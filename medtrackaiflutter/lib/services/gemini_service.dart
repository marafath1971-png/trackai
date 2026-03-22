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

  /// Standardized models and their versions for all AI tasks.
  /// Using verified identifiers from 2026 API diagnostics.
  static const List<Map<String, String>> _standardModels = [
    {'model': 'gemini-1.5-flash', 'version': 'v1beta'},
    {'model': 'gemini-1.5-pro', 'version': 'v1beta'},
    {'model': 'gemini-2.0-flash-exp', 'version': 'v1beta'},
    {'model': 'gemini-1.5-flash-8b', 'version': 'v1beta'},
    {'model': 'gemini-1.5-flash', 'version': 'v1'}, // Fallback to v1 stable
    {'model': 'gemini-1.0-pro', 'version': 'v1'},
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

    for (final config in _standardModels) {
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
        lastError = _humanizeError(e);
        appLogger.e('[GeminiService] Failed with $modelName ($apiVersion): $e');
        
        // Check if this error specifically represents a system/quota issue
        final s = e.toString().toLowerCase();
        if (s.contains('quota') || s.contains('limit') || s.contains('429')) {
             // We continue to next model, only if ALL fail will we return busy status
             continue;
        }
      }
    }

    // If we've exhausted all models and they all failed with quota/busy, or other errors
    final isBusy = lastError.contains('Limit Reached') || lastError.contains('taking a short breather');
    if (isBusy) {
      return Success(ScanResult(identified: false, systemBusy: true));
    }

    return Error(ScanFailure(lastError.isNotEmpty 
        ? lastError 
        : "The AI couldn't identify this medicine. Please try again with a clearer photo of the label."));
  }

  /// Uses Gemini to generate a short, friendly, personalized health tip.
  /// Includes fallback to multiple models and a static tip if all fail (e.g., quota).
  static Future<Result<List<HealthInsight>>> getHealthInsight({
    required List<Medicine> meds,
    required int streak,
    required double adherence,
    required List<Map<String, dynamic>> latencyData,
    required List<Symptom> symptoms,
  }) async {
    String lastError = '';

    for (final config in _standardModels) {
      final modelName = config['model']!;
      final apiVersion = config['version']!;

      try {
        final model = _getModel(modelName, apiVersion: apiVersion);
        final prompt =
            _buildInsightPrompt(meds, streak, adherence, latencyData, symptoms);
        final response = await _withRetry(
            () => model.generateContent([Content.text(prompt)]));
        if (response.text != null && response.text!.isNotEmpty) {
          final responseText = response.text!.trim();
          try {
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
            if (jsonMatch != null) {
              final data = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;
              final insightsList = data['insights'] as List;
              if (insightsList.isNotEmpty) {
                final result = insightsList
                    .map((item) => HealthInsight.fromJson(item as Map<String, dynamic>))
                    .toList();
                return Success(result);
              }
            }
          } catch (e) {
            appLogger.w('[GeminiService] Insight JSON parse error: $e');
          }
          // Fallback if not JSON or empty
          return Success([HealthInsight(category: 'Coach', title: 'Daily Tip', body: responseText)]);
        }
      } catch (e) {
        lastError = _humanizeError(e);
        appLogger.w('[GeminiService] Insight failed with $modelName ($apiVersion): $e');
      }
    }

    // Static Fallback Tips if AI is unavailable
    final fallbackTips = [
      HealthInsight(category: 'Personal', title: 'Consistency', body: 'Consistency is key! Taking your meds at the same time every day helps maintain effectiveness.'),
      HealthInsight(category: 'Safety', title: 'Hydration', body: 'Stay hydrated and track your symptoms regularily to help your doctor monitor your progress.'),
      HealthInsight(category: 'Adherence', title: 'Keep it up!', body: 'Keep your current streak going! Every day adds up to a healthier routine.')
    ];
    
    appLogger.e(
        '[GeminiService] All insight models failed. Returning static tip.',
        error: lastError);
    return Success([fallbackTips[meds.length % 3]]);
  }

  // ── Helper Prompt Generators ───────────────────────────────────────────────

  static String _buildScanPrompt(String? hint) {
    return '''
You are an expert pharmacist and clinical image analyst.
Examine the provided ${hint ?? ''} medicine packaging image carefully and extract all key medical details.
Auto-detect the medicine FORM (pill, spray, liquid, tablet, capsule etc.) and STOCK details.
Return ONLY valid JSON with NO markdown formatting, NO code fences, NO explanations:
{
  "identified": true,
  "name": "Generic medicine name",
  "brand": "Brand/trade name",
  "form": "tablet|capsule|pill|liquid|syrup|spray|inhaler|drops|cream|patch|injection|other",
  "dose": "Strength e.g. 500mg, 250mg/5ml",
  "dosePerTake": "Quantity per dose e.g. 1 tablet, 5ml",
  "frequency": "e.g. twice daily, every 8 hours, once at bedtime",
  "howToTake": "Detailed instructions e.g. Swallow whole with a full glass of water. If regional names exist (e.g., Paracetamol vs Acetaminophen), note them if appropriate.",
  "whenToTake": "Specific timing guidance e.g. Take in the morning before breakfast.",
  "withFood": true,
  "sideEffects": "Common side effects: nausea, headache. Use regional spelling if applicable (e.g., 'drowsiness' vs 'doziness' is less relevant than drug synonyms).",
  "interactions": "Avoid with: alcohol, blood thinners.",
  "warnings": "Do not use if pregnant. Avoid driving if drowsy. Handle regional drug name synonyms (e.g. Salbutamol for Albuterol, Paracetamol for Acetaminophen).",
  "storage": "Store below 25°C away from light.",
  "category": "Prescription|OTC|Supplement",
  "isAntibiotic": false,
  "isOngoing": false,
  "courseType": "fixed|ongoing|as-needed",
  "courseDurationDays": 7,
  "pillCount": 30,
  "packSize": 30,
  "isLiquid": false,
  "isSpray": false,
  "volumeAmount": 0,
  "volumeUnit": "ml",
  "unit": "tablets|ml|puffs|drops|creams|units",
  "scheduleSlots": [
    {"label": "Morning", "h": 8, "m": 0, "days": [0,1,2,3,4,5,6]},
    {"label": "Evening", "h": 20, "m": 0, "days": [0,1,2,3,4,5,6]}
  ],
  "confidence": "high|medium|low"
}
Note: scheduleSlots days use JavaScript day index (0=Sun, 1=Mon...6=Sat). 
Generate realistic scheduleSlots based on the frequency field.
If identification is not possible, set identified to false and best guess.
''';
  }

  static String _buildInsightPrompt(List<Medicine> meds, int streak,
      double adherence, List<Map<String, dynamic>> latencyData, List<Symptom> symptoms) {
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

    // Summarize symptoms for the AI
    final recentSymptoms = symptoms.take(10).map((s) => '${s.name} (Severity: ${s.severity}) at ${s.timestamp}').join(', ');

    return '''
Analyze medication data for a patient.
Meds: $medList
Streak: $streak days
Adherence: $adherence%
Last 14 days timing data: ${latencyData.length} records, Average Latency: ${avgLatency.toStringAsFixed(1)} mins.
Morning (>30m) delays: $morningDelays.
Recent Symptoms/Self-Reports: $recentSymptoms.

Provide 3 short, friendly, categorized health coaching tips.
Return ONLY a JSON object:
{
  "insights": [
    {
      "category": "Safety|Adherence|Optimization", 
      "title": "Short Title", 
      "body": "Actionable tip (max 30 words)",
      "steps": ["Step 1", "Step 2"]
    }
  ]
}
''';
  }

  /// Handles interactive follow-up questions for health coaching.
  static Future<Result<String>> askFollowUp(String question, List<HealthInsight> currentInsights) async {
    final context = currentInsights.map((i) => '${i.title}: ${i.body}').join('\n');
    final prompt = '''
You are MedAI Pro, a premium, high-performance AI Health Coach. 🚀
Recent insights provided:
$context

The user is asking: "$question"

Provide a response that is helpful, professional, yet exceptionally engaging and "hooked". 🤖
- Use emojis strategically (e.g., ✨, 💊, 📈, 🚨).
- Keep it concise (max 100 words).
- Focus on being encouraging and medically sound.
- If the question is unrelated to health, politely redirect.
''';

    for (final config in _standardModels) {
      final modelName = config['model']!;
      final apiVersion = config['version']!;
      try {
        final model = _getModel(modelName, apiVersion: apiVersion);
        final response = await _withRetry(() => model.generateContent([Content.text(prompt)]));
        if (response.text != null && response.text!.isNotEmpty) {
          return Success(response.text!.trim());
        }
      } catch (e) {
        appLogger.w('[GeminiService] Follow-up failed with $modelName: $e');
      }
    }
    return const Error(ScanFailure('Sorry, I couldn\'t process that question right now. Our AI might be busy. Please try again later.'));
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
    // Defensive check for UTF-16 compatibility
    final errStr = _safeString(e).toLowerCase();

    // FAIL FAST if quota is strictly zero (account limitation)
    if (errStr.contains('limit: 0')) {
      return false;
    }

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

  /// Sanitizes strings to ensure they are well-formed UTF-16 for Flutter/Dart logging.
  static String _safeString(dynamic e) {
    try {
      final s = e.toString();
      // Only keep characters that are part of well-formed UTF-16
      return s.runes.map((r) => r <= 0x10FFFF ? String.fromCharCode(r) : '').join();
    } catch (_) {
      return "Unknown Gemini Error";
    }
  }

  /// Translates ugly technical AI errors into friendly, branded messages.
  static String _humanizeError(dynamic e) {
    final s = _safeString(e).toLowerCase();

    if (s.contains('quota') || s.contains('limit') || s.contains('429')) {
      return "Our AI is currently taking a short breather (Limit Reached). Please try again in a few minutes, or upgrade to Pro for unlimited scanning! ✨";
    }
    if (s.contains('socket') || s.contains('timeout') || s.contains('network')) {
      return "Connection issues? Check your internet and let's try identifying that medicine again. 🌐";
    }
    if (s.contains('safety') || s.contains('finish_reason_safety')) {
      return "Our AI couldn't process this for safety reasons. Please ensure the label is clearly visible and medical in nature. ⚖️";
    }
    if (s.contains('401') || s.contains('key') || s.contains('auth')) {
      return "AI authentication failed. Please check your API key in settings. 🔑";
    }

    return "The AI couldn't identify this medicine. Please try again with a clearer photo of the label. 💊";
  }
}
