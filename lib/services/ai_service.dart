import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AIService {
  static const String _baseUrl = ApiConfig.geminiBaseUrl;
  static const String _apiKey = ApiConfig.geminiApiKey;

  // List of non-therapeutic topics to filter out
  static const List<String> _nonTherapeuticKeywords = [
    'recipe',
    'cooking',
    'food',
    'weather',
    'sports',
    'game',
    'movie',
    'music',
    'politics',
    'news',
    'celebrity',
    'technology',
    'programming',
    'code',
    'math',
    'science',
    'history',
    'geography',
    'travel',
    'shopping',
    'business',
    'money',
    'investment',
    'entertainment',
    'joke',
    'riddle',
  ];

  // Pre-filter user input to check if it's therapy-related
  bool _isTherapyRelated(String message) {
    final lowerMessage = message.toLowerCase();

    // Check if message contains obvious non-therapeutic keywords
    for (String keyword in _nonTherapeuticKeywords) {
      if (lowerMessage.contains(keyword)) {
        return false;
      }
    }

    // Allow mental health related keywords
    final therapeuticKeywords = [
      'feel',
      'emotion',
      'sad',
      'happy',
      'angry',
      'anxious',
      'stress',
      'worry',
      'depression',
      'anxiety',
      'mood',
      'mental',
      'health',
      'wellness',
      'cope',
      'help',
      'support',
      'therapy',
      'counseling',
      'thoughts',
      'mind',
      'heart',
      'relationship',
      'family',
      'friend',
      'work',
      'school',
      'life',
      'problem',
      'issue',
      'difficult',
      'hard',
      'tough',
      'struggle',
      'pain',
      'hurt',
      'lonely',
      'isolated',
      'overwhelmed',
      'frustrated',
      'upset',
      'confused',
    ];

    // If message contains therapeutic keywords, likely therapy-related
    for (String keyword in therapeuticKeywords) {
      if (lowerMessage.contains(keyword)) {
        return true;
      }
    }

    // Default to allowing shorter messages that might be greeting or general
    return message.trim().length < 50;
  }

  // Send message to Gemini API and get response
  Future<String> sendMessage(
    String userMessage,
    List<Map<String, dynamic>> chatHistory,
  ) async {
    // Pre-filter non-therapeutic topics
    if (!_isTherapyRelated(userMessage) && chatHistory.isNotEmpty) {
      return "I'm here specifically to support your mental health and wellness. Let's talk about how you're feeling today instead. What's on your mind emotionally?";
    }

    try {
      List<Map<String, dynamic>> contents = [];

      // If this is the first message, include system prompt
      if (chatHistory.isEmpty) {
        // Add system context as first user message
        contents.add({
          "parts": [
            {
              "text":
                  "${ApiConfig.therapistSystemPrompt}\n\nUser: $userMessage",
            },
          ],
          "role": "user",
        });
      } else {
        // Add chat history
        contents.addAll(chatHistory);

        // Add current user message
        contents.add({
          "parts": [
            {"text": userMessage},
          ],
          "role": "user",
        });
      }

      // Prepare the request body
      final requestBody = {
        "contents": contents,
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 1024,
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
        ],
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract the generated text from the response
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          String aiResponse =
              responseData['candidates'][0]['content']['parts'][0]['text'] ??
              '';

          // Post-process the response to ensure it stays therapeutic
          aiResponse = _ensureTherapeuticResponse(aiResponse);

          return aiResponse.isNotEmpty
              ? aiResponse
              : 'I\'m here to help, but I couldn\'t generate a proper response. Could you please try rephrasing your message?';
        } else {
          print('Unexpected response structure: $responseData');
          return 'I\'m here to support you, but I\'m having trouble processing your message right now. Can you tell me more about how you\'re feeling?';
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getErrorResponse(response.statusCode);
      }
    } catch (e) {
      print('Error calling AI service: $e');
      return 'I\'m experiencing some technical difficulties right now, but I\'m still here for you. How are you feeling today, and is there anything specific you\'d like to talk about?';
    }
  }

  // Get appropriate error response based on status code
  String _getErrorResponse(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'I\'m having authentication issues right now. Please try again in a moment.';
      case 429:
        return 'I\'m getting a lot of requests right now. Please wait a moment and try again.';
      case 500:
        return 'I\'m experiencing some technical issues. How are you feeling right now? I\'d still like to help in any way I can.';
      default:
        return 'I\'m having trouble connecting right now, but I want you to know that your feelings are valid and I\'m here to support you. Can you tell me what\'s on your mind?';
    }
  }

  // Ensure AI response stays therapeutic and appropriate
  String _ensureTherapeuticResponse(String response) {
    final lowerResponse = response.toLowerCase();

    // Check if response contains non-therapeutic content
    final nonTherapeuticPatterns = [
      'recipe',
      'cooking',
      'weather',
      'sports',
      'game',
      'movie',
      'programming',
      'mathematics',
      'science',
      'history',
      'geography',
      'politics',
      'news',
    ];

    for (String pattern in nonTherapeuticPatterns) {
      if (lowerResponse.contains(pattern)) {
        return "I'm here specifically to support your mental health and wellness. Let's focus on how you're feeling and what you might need emotionally right now. What's been on your mind lately?";
      }
    }

    // Ensure response is supportive and not too long
    if (response.length > 500) {
      return "${response.substring(0, 400)}... How does that resonate with you?";
    }

    return response;
  }

  // Convert chat messages to API format for context
  List<Map<String, dynamic>> formatChatHistory(List<ChatMessage> messages) {
    // Only include recent messages and skip the welcome message for context
    // Take last 6-8 messages to avoid token limits but maintain context
    final recentMessages = messages
        .where((msg) => !_isWelcomeMessage(msg))
        .toList();
    final contextMessages = recentMessages.length > 6
        ? recentMessages.sublist(recentMessages.length - 6)
        : recentMessages;

    List<Map<String, dynamic>> formattedHistory = [];

    for (int i = 0; i < contextMessages.length; i++) {
      final message = contextMessages[i];

      // For Gemini, we need to format as alternating user/model conversation
      formattedHistory.add({
        "parts": [
          {"text": message.isUser ? message.text : message.text},
        ],
        // Add role for proper conversation flow
        "role": message.isUser ? "user" : "model",
      });
    }

    return formattedHistory;
  }

  // Check if message is the welcome message
  bool _isWelcomeMessage(ChatMessage message) {
    return !message.isUser &&
        message.text.contains("Hello! I'm your AI therapist companion");
  }
}

// Chat message model for the AI service
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
