import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/content_filtering_service.dart';
import '../config/api_config.dart';

class GeminiAIService {
  static const String _apiKey = ApiConfig.geminiApiKey;
  static const String _primaryBaseUrl = ApiConfig.geminiBaseUrl;

  /// Enhanced content analysis using Gemini AI
  static Future<AIAnalysisResult> analyzeMessageContent(
    String content, {
    int? userMoodLevel,
    List<String>? recentMessages,
    String? userAge,
  }) async {
    try {
      // Debug: log endpoint being used for Gemini API
      // This helps ensure we are not accidentally calling deprecated models like gemini-pro
      // ignore: avoid_print
      print('DEBUG[GEMINI]: analyzeMessageContent()');
      final prompt = _buildAnalysisPrompt(
        content,
        userMoodLevel,
        recentMessages,
        userAge,
      );

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 1,
          'topP': 0.8,
          'maxOutputTokens': 1000,
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE',
          },
        ],
      };

      final response = await _postToGemini(payload);

      if (response != null) {
        final data = json.decode(response);
        String aiResponseText = '';
        try {
          final candidates = data['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final content = candidates.first['content'];
            if (content is Map &&
                content['parts'] is List &&
                content['parts'].isNotEmpty) {
              final firstPart = content['parts'][0];
              if (firstPart is Map && firstPart['text'] is String) {
                aiResponseText = firstPart['text'] as String;
              }
            }
          }
        } catch (_) {
          // Ignore parse errors and fall back
        }

        if (aiResponseText.isNotEmpty) {
          return _parseAIResponse(aiResponseText);
        }
      }
      return _fallbackToBasicFilter(content);
    } catch (e) {
      print('Gemini AI Service Error: $e');
      return _fallbackToBasicFilter(content);
    }
  }

  /// Generate supportive response for crisis situations using Gemini
  static Future<String> generateCrisisSupport(
    String userMessage, {
    int? moodLevel,
    List<String>? crisisFlags,
  }) async {
    try {
      print('DEBUG[GEMINI]: generateCrisisSupport()');
      final prompt =
          '''
As a mental health crisis support AI, generate a compassionate, immediate response to someone in distress.

User message: "$userMessage"
Current mood level: ${moodLevel ?? 'unknown'} (1-10 scale, 1 being lowest)
Crisis indicators: ${crisisFlags?.join(', ') ?? 'none detected'}

Generate a response that:
1. Acknowledges their pain without minimizing it
2. Provides immediate crisis resources (India: Tele-MANAS 14416 / 1-800-891-4416; Emergency 112)
3. Offers hope and connection
4. Is warm, non-judgmental, and professional
5. Encourages professional help
6. Is under 200 words

Format: Just return the supportive message, no explanations.
''';

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 300},
      };

      final response = await _postToGemini(payload);
      if (response != null) {
        final data = json.decode(response);
        // Safe parsing with null checks
        final candidates = data['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final firstCandidate = candidates[0];
          if (firstCandidate is Map) {
            final content = firstCandidate['content'];
            if (content is Map) {
              final parts = content['parts'];
              if (parts is List && parts.isNotEmpty) {
                final firstPart = parts[0];
                if (firstPart is Map && firstPart['text'] is String) {
                  return firstPart['text'];
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error generating crisis support: $e');
    }

    return _getDefaultCrisisResponse();
  }

  /// Analyze conversation patterns for early intervention
  static Future<ConversationAnalysis> analyzeConversationPattern(
    List<String> messages,
    String userId,
  ) async {
    try {
      print('DEBUG[GEMINI]: analyzeConversationPattern()');
      final prompt =
          '''
Analyze this conversation pattern for mental health early intervention signals:

Recent messages from user:
${messages.take(10).map((msg) => '- $msg').join('\n')}

Analyze for:
1. Escalating distress patterns
2. Social isolation indicators  
3. Mood deterioration over time
4. Crisis warning signs
5. Need for professional intervention

Return JSON format:
{
  "riskLevel": "low|medium|high|crisis",
  "concernAreas": ["area1", "area2"],
  "recommendedActions": ["action1", "action2"],
  "urgency": "immediate|within_24h|routine|none",
  "supportSuggestions": ["suggestion1", "suggestion2"]
}
''';

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 500},
      };

      final response = await _postToGemini(payload);
      if (response != null) {
        final data = json.decode(response);
        // Safe parsing with null checks
        final candidates = data['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final firstCandidate = candidates[0];
          if (firstCandidate is Map) {
            final content = firstCandidate['content'];
            if (content is Map) {
              final parts = content['parts'];
              if (parts is List && parts.isNotEmpty) {
                final firstPart = parts[0];
                if (firstPart is Map && firstPart['text'] is String) {
                  return ConversationAnalysis.fromJson(firstPart['text']);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error analyzing conversation pattern: $e');
    }

    return ConversationAnalysis.defaultAnalysis();
  }

  /// Generate personalized coping suggestions
  static Future<List<String>> generateCopingSuggestions(
    String userMessage,
    int moodLevel,
    List<String> userInterests,
  ) async {
    try {
      print('DEBUG[GEMINI]: generateCopingSuggestions()');
      final prompt =
          '''
Generate 3-5 personalized, immediate coping strategies for someone experiencing mental health challenges.

Current situation: "$userMessage"
Mood level: $moodLevel/10
User interests: ${userInterests.join(', ')}

Provide practical, actionable coping strategies that:
1. Can be done immediately (within 5-15 minutes)
2. Are personalized to their interests
3. Are evidence-based for mental health
4. Are accessible from home
5. Don't require special equipment

Format as a simple list, one strategy per line, starting with "-"
''';

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 300},
      };

      final response = await _postToGemini(payload);
      if (response != null) {
        final data = json.decode(response);
        // Safe parsing with null checks
        final candidates = data['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final firstCandidate = candidates[0];
          if (firstCandidate is Map) {
            final content = firstCandidate['content'];
            if (content is Map) {
              final parts = content['parts'];
              if (parts is List && parts.isNotEmpty) {
                final firstPart = parts[0];
                if (firstPart is Map && firstPart['text'] is String) {
                  final aiResponse = firstPart['text'];
                  return aiResponse
                      .split('\n')
                      .where((line) => line.trim().startsWith('-'))
                      .map((line) => line.trim().substring(1).trim())
                      .toList();
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error generating coping suggestions: $e');
    }

    return [
      'Take 5 deep breaths, focusing on the exhale',
      'Step outside for fresh air if possible',
      'Listen to calming music or nature sounds',
      'Reach out to a trusted friend or family member',
      'Use a grounding technique: name 5 things you can see, 4 you can touch, 3 you can hear',
    ];
  }

  /// Helper: POST to Gemini with fallback endpoints on 404/unsupported errors
  static Future<String?> _postToGemini(Map<String, dynamic> payload) async {
    final endpoints = <String>[
      _primaryBaseUrl,
      ...ApiConfig.geminiFallbackBaseUrls,
    ];

    for (final baseUrl in endpoints) {
      final fullUrl = '$baseUrl?key=$_apiKey';
      try {
        // Don't log API key
        print('DEBUG[GEMINI]: POST $baseUrl');
        final response = await http.post(
          Uri.parse(fullUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );

        if (response.statusCode == 200) {
          return response.body;
        }

        // If model not found/unsupported for method, try next endpoint
        if (response.statusCode == 404 || response.statusCode == 400) {
          final body = response.body;
          if (body.contains('not found') ||
              body.contains('not supported') ||
              body.contains('models/')) {
            print(
              'DEBUG[GEMINI]: Endpoint not supported, trying next. Response: ${response.statusCode} - $body',
            );
            continue; // try next endpoint
          }
        }

        // Other errors - log and stop trying further to avoid masking real issues
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return null;
      } catch (e) {
        print('DEBUG[GEMINI]: Error calling $fullUrl -> $e');
        // Try next endpoint
        continue;
      }
    }

    print('DEBUG[GEMINI]: All endpoints failed');
    return null;
  }

  static String _buildAnalysisPrompt(
    String content,
    int? moodLevel,
    List<String>? recentMessages,
    String? userAge,
  ) {
    return '''
Analyze this message from a mental health app user for SAFETY and CRISIS indicators.

Important:
- Handle multilingual text including English and Indian languages (Hindi, Bengali, Marathi, Tamil, Telugu, Gujarati, Kannada, Malayalam, Punjabi, Urdu), both native scripts (e.g., Devanagari) and transliterations (Latin script like "madarchod").
- Detect nuanced harassment, bullying, hate/threats, sexual, personal info requests, self-harm/crisis, substance mentions.

Message: "$content"
User mood level: ${moodLevel ?? 'unknown'} (1-10 scale)
Recent context: ${recentMessages?.take(3).join(' | ') ?? 'none'}
User age group: ${userAge ?? 'unknown'}

Output numeric scores 0-10 (10 safest). Keep the EXACT keys below:
CRISIS_LEVEL: [0-10]
SELF_HARM: [0-10]
PREDATORY: [0-10]
PERSONAL_INFO: [0-10]
BULLYING: [0-10]
SUBSTANCE: [0-10]
SAFETY_SCORE: [0-10]
REQUIRES_INTERVENTION: [YES/NO]
CRISIS_TYPE: [NONE/MILD/MODERATE/SEVERE/IMMEDIATE]
RECOMMENDED_ACTION: [brief action recommendation]
''';
  }

  static AIAnalysisResult _parseAIResponse(String response) {
    try {
      final lines = response.split('\n');
      final result = AIAnalysisResult();

      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length != 2) continue;

        final key = parts[0].trim();
        final value = parts[1].trim();

        switch (key) {
          case 'CRISIS_LEVEL':
            result.crisisLevel = int.tryParse(value) ?? 0;
            break;
          case 'SELF_HARM':
            result.selfHarmLevel = int.tryParse(value) ?? 0;
            break;
          case 'PREDATORY':
            result.predatoryLevel = int.tryParse(value) ?? 0;
            break;
          case 'SAFETY_SCORE':
            result.safetyScore = (int.tryParse(value) ?? 10) / 10.0;
            break;
          case 'REQUIRES_INTERVENTION':
            result.requiresIntervention = value.toUpperCase() == 'YES';
            break;
          case 'CRISIS_TYPE':
            result.crisisType = value;
            break;
          case 'RECOMMENDED_ACTION':
            result.recommendedAction = value;
            break;
        }
      }

      return result;
    } catch (e) {
      print('Error parsing AI response: $e');
      return AIAnalysisResult();
    }
  }

  static AIAnalysisResult _fallbackToBasicFilter(String content) {
    final basicResult = ContentFilteringService.filterMessage(content);
    return AIAnalysisResult(
      safetyScore: basicResult.safetyScore,
      requiresIntervention: basicResult.requiresImmediateIntervention,
      crisisType: basicResult.requiresImmediateIntervention
          ? 'MODERATE'
          : 'NONE',
    );
  }

  static String _getDefaultCrisisResponse() {
    return '''
I hear that you're going through something really difficult right now, and I want you to know that you're not alone. Your feelings are valid, and there are people who care about you and want to help.

🆘 **Immediate Support:**
• **Tele-MANAS (India)**: Call 14416 or 1-800-891-4416 (24/7)
• **Emergency Services (India)**: Call 112

You matter, and there is hope. These trained counselors are ready to listen and support you right now. Would you like help connecting with additional resources?

💙 Remember: Reaching out for help is a sign of strength, not weakness.
''';
  }
}

class AIAnalysisResult {
  int crisisLevel;
  int selfHarmLevel;
  int predatoryLevel;
  double safetyScore;
  bool requiresIntervention;
  String crisisType;
  String recommendedAction;

  AIAnalysisResult({
    this.crisisLevel = 0,
    this.selfHarmLevel = 0,
    this.predatoryLevel = 0,
    this.safetyScore = 1.0,
    this.requiresIntervention = false,
    this.crisisType = 'NONE',
    this.recommendedAction = 'Monitor conversation',
  });
}

class ConversationAnalysis {
  final String riskLevel;
  final List<String> concernAreas;
  final List<String> recommendedActions;
  final String urgency;
  final List<String> supportSuggestions;

  ConversationAnalysis({
    required this.riskLevel,
    required this.concernAreas,
    required this.recommendedActions,
    required this.urgency,
    required this.supportSuggestions,
  });

  factory ConversationAnalysis.fromJson(String jsonString) {
    try {
      final data = json.decode(
        jsonString.replaceAll('```json', '').replaceAll('```', ''),
      );
      return ConversationAnalysis(
        riskLevel: data['riskLevel'] ?? 'low',
        concernAreas: List<String>.from(data['concernAreas'] ?? []),
        recommendedActions: List<String>.from(data['recommendedActions'] ?? []),
        urgency: data['urgency'] ?? 'routine',
        supportSuggestions: List<String>.from(data['supportSuggestions'] ?? []),
      );
    } catch (e) {
      return ConversationAnalysis.defaultAnalysis();
    }
  }

  static ConversationAnalysis defaultAnalysis() {
    return ConversationAnalysis(
      riskLevel: 'low',
      concernAreas: [],
      recommendedActions: ['Continue monitoring'],
      urgency: 'routine',
      supportSuggestions: ['Encourage positive engagement'],
    );
  }
}
