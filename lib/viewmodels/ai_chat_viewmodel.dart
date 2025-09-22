import 'package:get/get.dart';
import '../services/ai_service.dart';

class AIChatViewModel extends GetxController {
  final AIService _aiService = AIService();

  // Observable variables
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    messages.add(
      ChatMessage(
        text:
            "Hello! I'm your AI therapist companion, focused specifically on mental health and emotional wellness. I'm here to listen, provide support, and guide you through your mental wellness journey.\n\nI only discuss topics related to mental health, emotions, stress, anxiety, and wellness. How are you feeling today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  // Send message to AI and get response
  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;

    // Clear any previous errors
    errorMessage.value = '';

    // Add user message
    final userMessage = ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMessage);

    // Show typing indicator
    isTyping.value = true;

    try {
      // Prepare chat history for context
      final chatHistory = _aiService.formatChatHistory(messages);

      // Get AI response
      final aiResponse = await _aiService.sendMessage(messageText, chatHistory);

      // Add AI response
      final aiMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(aiMessage);
    } catch (e) {
      print('Error in sendMessage: $e');
      errorMessage.value = 'Failed to send message. Please try again.';

      // Add fallback message
      final fallbackMessage = ChatMessage(
        text:
            "I apologize, but I'm having technical difficulties right now. Please know that I'm still here for you. How are you feeling, and is there anything specific you'd like to discuss about your mental wellness?",
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(fallbackMessage);
    } finally {
      isTyping.value = false;
    }
  }

  // Clear chat history
  void clearChat() {
    messages.clear();
    _addWelcomeMessage();
    errorMessage.value = '';
  }

  // Get chat history for persistence (if needed later)
  List<Map<String, dynamic>> getChatHistory() {
    return messages.map((message) => message.toMap()).toList();
  }

  // Load chat history from persistence (if needed later)
  void loadChatHistory(List<Map<String, dynamic>> history) {
    messages.clear();
    for (final messageMap in history) {
      messages.add(ChatMessage.fromMap(messageMap));
    }
  }
}
