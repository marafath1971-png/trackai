import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../domain/entities/entities.dart';
import '../core/utils/result.dart';
import '../core/error/failures.dart';
import '../core/utils/logger.dart';

// ══════════════════════════════════════════════
// GEMINI SERVICE — FREE AI ENGINE
// ══════════════════════════════════════════════
// Provides robust AI analysis for medicine scanning
// and generic health insights using Gemini models.

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Tried models and their preferred API versions in order of reliability.
  static const List<Map<String, String>> _scanModels = [
    {'model': 'gemini-2.5-flash', 'version': 'v1beta'},
    {'model': 'gemini-flash-latest', 'version': 'v1beta'},
    {'model': 'gemini-2.0-flash-lite', 'version': 'v1beta'},
    {'model': 'gemini-2.0-flash', 'version': 'v1beta'},
  ];

  static GenerativeModel _getModel(String modelName, {String apiVersion = 'v1'}) {
    if (_apiKey.isEmpty) {
      appLogger.w(
          '[GeminiService] Warning: GEMINI_API_KEY is empty. API calls will fail.');
    }
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      requestOptions: RequestOptions(apiVersion: apiVersion),
    );
  }

  /// Scans a medicine image label using Gemini Flash to extract structural medication data.
  /// Falls back through multiple Gemini model versions and API versions if one fails.
  static Future<Result<ScanResult>> scanMedicine(File imageFile,
      {String? hint}) async {
    appLogger.d('[GeminiService] Starting scan with hint: $hint');
    String lastError = '';

    for (final config in _scanModels) {
      final modelName = config['model']!;
      final apiVersion = config['version']!;
      
      try {
        appLogger.d('[GeminiService] Trying $modelName on $apiVersion...');
        final model = _getModel(modelName, apiVersion: apiVersion);
        final bytes = await imageFile.readAsBytes();

        final content = [
          Content.multi([
            TextPart(_buildScanPrompt(hint)),
            DataPart('image/jpeg', bytes),
          ])
        ];

        final response = await _withRetry(() => model.generateContent(content));
        final responseText = response.text ?? '';
        appLogger.d('[GeminiService] Raw Response: $responseText');
        
        if (responseText.isEmpty) {
          throw const FormatException('Empty response from AI');
        }

        return Success(_parseScanResponse(responseText));
      } catch (e) {
        lastError = e.toString();
        appLogger.e('[GeminiService] Failed with $modelName ($apiVersion): $e');
        
        // If it's a quota error on one model, we continue to the next
      }
    }

    return Error(ScanFailure("The AI couldn't identify this medicine. Please try again with a clearer photo of the label. ($lastError)"));
  }

  /// Uses Gemini to generate a short, friendly, personalized health tip.
  /// Includes fallback to multiple models and a static tip if all fail (e.g., quota).
  static Future<Result<String>> getHealthInsight({
    required List<Medicine> meds,
    required int streak,
    required double adherence,
    required List<Map<String, dynamic>> latencyData,
  }) async {
    final configs = [
      {'model': 'gemini-2.5-flash', 'version': 'v1beta'},
      {'model': 'gemini-flash-latest', 'version': 'v1beta'},
      {'model': 'gemini-2.0-flash-lite', 'version': 'v1beta'},
      {'model': 'gemini-2.0-flash', 'version': 'v1beta'},
    ];
    String lastError = '';

    for (final config in configs) {
      final modelName = config['model']!;
      final apiVersion = config['version']!;

      try {
        final model = _getModel(modelName, apiVersion: apiVersion);
        final prompt =
            _buildInsightPrompt(meds, streak, adherence, latencyData);
        final response = await _withRetry(
            () => model.generateContent([Content.text(prompt)]));
        if (response.text != null && response.text!.isNotEmpty) {
          return Success(response.text!.trim());
        }
      } catch (e) {
        lastError = e.toString();
        appLogger.w('[GeminiService] Insight failed with $modelName ($apiVersion): $e');
      }
    }

    // Static Fallback Tips if AI is unavailable
    final fallbackTips = [
      'Consistency is key! Taking your meds at the same time every day helps maintain effectiveness.',
      'Stay hydrated and track your symptoms regularily to help your doctor monitor your progress.',
      'Keep your current streak going! Every day adds up to a healthier, more predictable routine.'
    ];
    final staticTip = (meds.length % 3 == 0)
        ? fallbackTips[0]
        : (meds.length % 3 == 1 ? fallbackTips[1] : fallbackTips[2]);

    appLogger.e(
        '[GeminiService] All insight models failed. Returning static tip.',
        error: lastError);
    return Success(staticTip);
  }

  // ── Helper Prompt Generators ───────────────────────────────────────────────

  static String _buildScanPrompt(String? hint) {
    return '''
You are an expert pharmacist and clinical image analyst.
Examine the provided ${hint ?? ''} medicine packaging image carefully and extract all key medical details.
Return ONLY valid JSON with NO markdown formatting, NO code fences, NO explanations:
{
  "identified": true,
  "name": "Generic medicine name",
  "brand": "Brand/trade name",
  "form": "tablet|syrup|capsule|liquid|inhaler|drops|cream|patch|injection|other",
  "dose": "Strength e.g. 500mg, 250mg/5ml",
  "dosePerTake": "Quantity per dose e.g. 1 tablet, 5ml",
  "frequency": "e.g. twice daily, every 8 hours, once at bedtime",
  "howToTake": "Detailed instructions e.g. Swallow whole with a full glass of water. Do not crush.",
  "whenToTake": "Specific timing guidance e.g. Take in the morning before breakfast. Avoid taking at night.",
  "withFood": true,
  "sideEffects": "Common side effects: nausea, headache, dizziness. Rare: allergic reaction.",
  "interactions": "Avoid with: alcohol, blood thinners, antacids. Consult doctor if taking NSAIDs.",
  "warnings": "Do not use if pregnant or breastfeeding. Avoid driving if drowsy. Keep out of reach of children.",
  "storage": "Store below 25°C away from light and moisture. Keep refrigerated after opening.",
  "category": "Prescription|OTC|Supplement",
  "isAntibiotic": false,
  "isOngoing": false,
  "courseType": "fixed|ongoing|as-needed",
  "courseDurationDays": 7,
  "pillCount": 30,
  "packSize": 30,
  "isLiquid": false,
  "volumeAmount": 0,
  "volumeUnit": "ml",
  "scheduleSlots": [
    {"label": "Morning", "h": 8, "m": 0, "days": [0,1,2,3,4,5,6]},
    {"label": "Evening", "h": 20, "m": 0, "days": [0,1,2,3,4,5,6]}
  ],
  "confidence": "high|medium|low"
}
Note: scheduleSlots days use JavaScript day index (0=Sun, 1=Mon...6=Sat). 
Generate realistic scheduleSlots based on the frequency field (once daily = morning only, twice = morning+evening, three times = morning+noon+night etc.)
If identification is not possible, set identified to false and return best guesses.
''';
  }

  static String _buildInsightPrompt(List<Medicine> meds, int streak,
      double adherence, List<Map<String, dynamic>> latencyData) {
    final medList = meds.map((m) => '${m.name} ${m.dose}').join(', ');

    // Summarize latency for the AI
    final avgLatency = latencyData.isEmpty
        ? 0
        : latencyData.map((e) => e['latency'] as int).reduce((a, b) => a + b) /
            latencyData.length;
    final morningDelays = latencyData
        .where((e) =>
            (e['latency'] as int) > 30 && (e['time'] as String).startsWith('0'))
        .length;

    return '''
Analyze medication data for a patient.
Meds: $medList
Streak: $streak days
Adherence: $adherence%
Last 14 days timing data: ${latencyData.length} records, Average Latency: ${avgLatency.toStringAsFixed(1)} mins.
Morning (>30m) delays: $morningDelays.

Provide 3 short, friendly, categorized health coaching tips.
Return ONLY a JSON object:
{
  "insights": [
    {"category": "Safety|Adherence|Optimization", "title": "Short Title", "body": "Actionable tip (max 30 words)"}
  ]
}
''';
  }

  // ── Helper Data Parsers ──────────────────────────────────────────────────

  static ScanResult _parseScanResponse(String responseText) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        throw const FormatException('No JSON found in response');
      }

      String jsonStr = jsonMatch.group(0)!;
      // Aggressive cleaning of markdown and potential junk
      jsonStr = jsonStr
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('//', '') // Remove comments if any
          .trim();
      
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      return ScanResult.fromJson(data);
    } catch (e) {
      appLogger.e('[GeminiService] JSON parse error', error: e);
      throw FormatException('JSON parse error: $e');
    }
  }

  static Future<T> _withRetry<T>(Future<T> Function() action,
      {int maxRetries = 3}) async {
    int attempts = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempts++;
        if (attempts > maxRetries || !_isRetryableError(e)) {
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s
        final delayMs = 1000 * (1 << (attempts - 1));
        appLogger.w(
            '[GeminiService] Rate Limit/Network Error: $e. Retrying in ${delayMs}ms (attempt $attempts/$maxRetries)...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  static bool _isRetryableError(dynamic e) {
    final errStr = e.toString().toLowerCase();

    // Do not retry fatal auth or invalid request errors
    if (errStr.contains('403') ||
        errStr.contains('401') ||
        errStr.contains('unauthenticated') ||
        errStr.contains('key') ||
        errStr.contains('not found')) {
      return false;
    }

    // Always retry 429 quota/rate limit, 503 service issues, and network timeouts
    if (errStr.contains('429') ||
        errStr.contains('quota') ||
        errStr.contains('503') ||
        errStr.contains('socket') ||
        errStr.contains('timeout')) {
      return true;
    }

    return true; // Default to retry for transient exceptions
  }
}
