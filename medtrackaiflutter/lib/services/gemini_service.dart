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

  static const List<String> _modelNames = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
  ];

  static GenerativeModel _getModel(String modelName) {
    if (_apiKey.isEmpty) {
      appLogger.w(
          '[GeminiService] Warning: GEMINI_API_KEY is empty. API calls will fail.');
    }
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );
  }

  /// Scans a medicine image label using Gemini Flash to extract structural medication data.
  /// Falls back through multiple Gemini model versions if one fails.
  static Future<Result<ScanResult>> scanMedicine(File imageFile,
      {String? hint}) async {
    appLogger.d('[GeminiService] Starting scan with hint: $hint');
    String lastError = '';

    for (final modelName in _modelNames) {
      try {
        appLogger.d('[GeminiService] Trying $modelName (v1 API)...');
        final model = _getModel(modelName);
        final bytes = await imageFile.readAsBytes();

        final content = [
          Content.multi([
            TextPart(_buildScanPrompt(hint)),
            DataPart('image/jpeg', bytes),
          ])
        ];

        final response = await _withRetry(() => model.generateContent(content));
        return Success(_parseScanResponse(response.text ?? ''));
      } catch (e) {
        lastError = e.toString();
        appLogger.e('[GeminiService] Failed with $modelName', error: e);
      }
    }

    return Error(ScanFailure(lastError));
  }

  /// Uses Gemini to generate a short, friendly, personalized health tip.
  /// Includes fallback to multiple models and a static tip if all fail (e.g., quota).
  static Future<Result<String>> getHealthInsight({
    required List<Medicine> meds,
    required int streak,
    required double adherence,
    required List<Map<String, dynamic>> latencyData,
  }) async {
    final models = [
      'gemini-2.0-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash'
    ];
    String lastError = '';

    for (final modelName in models) {
      try {
        final model = _getModel(modelName);
        final prompt =
            _buildInsightPrompt(meds, streak, adherence, latencyData);
        final response = await _withRetry(
            () => model.generateContent([Content.text(prompt)]));
        if (response.text != null && response.text!.isNotEmpty) {
          return Success(response.text!.trim());
        }
      } catch (e) {
        lastError = e.toString();
        appLogger.w('[GeminiService] Insight failed with $modelName: $e');
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
    String type =
        (hint == 'Beauty') ? 'beauty product (skincare/cosmetic)' : 'medicine';
    return '''
You are an expert clinical pharmacist with 20 years of experience reading medicine labels. 
Carefully examine EVERY part of this $type packaging image — front, back, sides, any visible text.
User hint: "$hint".

Extract ALL information and return ONLY a valid JSON object (no markdown, no explanation):
{
  "identified": true,
  "name": "INN/generic name of active ingredient (e.g. Amoxicillin, Metformin, Paracetamol)",
  "brand": "brand/trade name on box (e.g. Augmentin, Glucophage, Tylenol)",
  "form": "exact form: tablet|capsule|syrup|liquid|inhaler|drops|cream|injection|powder|patch|other",
  "dose": "strength per unit WITH units (e.g. 500mg, 250mg/5ml, 10mg, 0.5%)",
  "dosePerTake": "quantity per dose (e.g. 1 tablet, 2 capsules, 5ml, 1 puff)",
  "frequency": "how often (e.g. twice daily, every 8 hours, once at bedtime)",
  "howToTake": "complete administration instructions visible on label",
  "withFood": true if label says take with food/meal, false otherwise,
  "mealTiming": "Before meal|After meal|With meal|With milk|Empty stomach|Anytime",
  "withWater": "With full glass of water|With small sip|Do not take with water|Any",
  "storage": "exact storage conditions from label (e.g. Store below 25°C, Refrigerate 2-8°C, Keep away from light)",
  "warnings": "ALL warnings, contraindications, side effects visible on packaging",
  "category": "Prescription|OTC|Supplement|Vitamin|Herbal",
  "indication": "what condition/disease this treats (use medical knowledge if not on label)",
  "activeIngredients": "all active ingredients listed",
  "pillCount": 30,
  "packSize": 30,
  "isLiquid": true if syrup/suspension/drops/liquid, false otherwise,
  "volumeAmount": 0,
  "volumeUnit": "ml" if liquid else "",
  "confidence": "high|medium",
  "isAntibiotic": true if antibiotic/antifungal/short-course treatment,
  "courseDurationDays": 7, 
  "courseType": "fixed|ongoing|as-needed",
  "scheduleSlots": [{"label": "Morning", "h": 8, "m": 0}],
  "refillAlert": 7
}

ACCURACY RULES:
1. Read text character by character, do not guess spellings.
2. If strength says "500mg" write exactly "500mg" not "500 mg".
3. For antibiotics: courseType="fixed", courseDurationDays=typical length.
4. For chronic meds: courseType="ongoing", courseDurationDays=0.
5. Identify medication even if packaging is partially obscured.
6. Return ONLY the JSON object. No other text.
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
      // Clean up common AI artifacts
      jsonStr = jsonStr.replaceAll(
          RegExp(r'//.*$', multiLine: true), ''); // remove comments

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
