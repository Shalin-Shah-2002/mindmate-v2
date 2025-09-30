import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Accessibility configuration for mental health app
/// Provides enhanced accessibility features for users with various needs
class AccessibilityConfig {
  // Semantic labels for mental health contexts
  static const Map<String, String> semanticLabels = {
    'panic_button': 'Emergency panic button - tap for immediate crisis support',
    'mood_log': 'Record your current mood and feelings',
    'chat_room': 'Support group chat room',
    'crisis_help': 'Crisis intervention and professional help resources',
    'safe_space': 'This is a moderated safe space for mental health support',
    'trust_indicator': 'User trust level indicator for safety',
    'content_warning': 'This message contains sensitive content',
    'coping_suggestion': 'AI-generated coping strategy recommendation',
  };

  // High contrast colors for accessibility
  static const Map<String, Color> highContrastColors = {
    'primary': Color(0xFF000080), // Dark blue
    'secondary': Color(0xFF800000), // Dark red
    'background': Color(0xFFFFFFFF), // White
    'surface': Color(0xFFF5F5F5), // Light gray
    'error': Color(0xFF8B0000), // Dark red
    'success': Color(0xFF006400), // Dark green
    'warning': Color(0xFFFF8C00), // Dark orange
    'text': Color(0xFF000000), // Black
    'textSecondary': Color(0xFF333333), // Dark gray
  };

  // Text scaling configurations
  static const Map<String, double> textScales = {
    'small': 0.85,
    'normal': 1.0,
    'large': 1.15,
    'extra_large': 1.3,
    'accessibility': 1.5,
  };

  // Mental health specific accessibility features
  static Widget buildAccessibleChatMessage({
    required String message,
    required bool isOwnMessage,
    required DateTime timestamp,
    double? safetyScore,
    bool isCrisisMessage = false,
  }) {
    String semanticLabel = 'Message: $message';

    if (isCrisisMessage) {
      semanticLabel =
          'Crisis message detected: $message. This message has been flagged for safety review.';
    } else if (safetyScore != null && safetyScore < 0.8) {
      semanticLabel =
          'Reviewed message: $message. This message has been checked for safety.';
    }

    if (isOwnMessage) {
      semanticLabel = 'Your message: $message';
    }

    return Semantics(
      label: semanticLabel,
      hint: isOwnMessage
          ? 'Double tap to edit or delete'
          : 'Double tap to report if inappropriate',
      child: _buildMessageContent(
        message,
        isOwnMessage,
        timestamp,
        safetyScore,
        isCrisisMessage,
      ),
    );
  }

  static Widget _buildMessageContent(
    String message,
    bool isOwnMessage,
    DateTime timestamp,
    double? safetyScore,
    bool isCrisisMessage,
  ) {
    // This would be the actual message widget implementation
    return Container(padding: const EdgeInsets.all(8), child: Text(message));
  }

  static Widget buildAccessiblePanicButton({required VoidCallback onPressed}) {
    return Semantics(
      label: semanticLabels['panic_button'],
      hint:
          'Double tap to activate crisis support. This will connect you with professional help immediately.',
      button: true,
      child: FloatingActionButton(
        onPressed: () {
          // Haptic feedback for accessibility
          HapticFeedback.heavyImpact();
          onPressed();
        },
        backgroundColor: Colors.red[600],
        child: const Icon(Icons.sos, size: 28),
      ),
    );
  }

  static Widget buildAccessibleChatRoom({
    required String roomName,
    required String description,
    required int memberCount,
    required bool isModerated,
    required VoidCallback onTap,
  }) {
    String semanticLabel =
        '$roomName support group. $description. $memberCount members.';
    if (isModerated) {
      semanticLabel += ' This room is moderated for safety.';
    }

    return Semantics(
      label: semanticLabel,
      hint: 'Double tap to join this support group',
      button: true,
      child: ListTile(
        title: Text(roomName),
        subtitle: Text(description),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }

  // Screen reader optimized crisis intervention
  static Widget buildAccessibleCrisisIntervention({
    required List<String> emergencyContacts,
    required VoidCallback onCallCrisisLine,
    required VoidCallback onTextSupport,
    required VoidCallback onCall911,
  }) {
    return Semantics(
      label:
          'Crisis intervention options. Multiple ways to get immediate help.',
      child: Column(
        children: [
          Semantics(
            label:
                'Call National Crisis Lifeline at 988. Available 24/7 for immediate support.',
            hint: 'Double tap to call crisis lifeline',
            button: true,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                onCallCrisisLine();
              },
              child: const Text('Call 988 Crisis Line'),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Text HOME to 741741 for text-based crisis support.',
            hint: 'Double tap to start text conversation',
            button: true,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onTextSupport();
              },
              child: const Text('Text Crisis Support'),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label:
                'Call 911 for emergency services if you are in immediate danger.',
            hint: 'Double tap to call emergency services',
            button: true,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                onCall911();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Call 911 Emergency'),
            ),
          ),
        ],
      ),
    );
  }

  // Mood tracking accessibility
  static Widget buildAccessibleMoodButton({
    required String mood,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    String semanticLabel = '$mood mood, represented by $emoji emoji';
    if (isSelected) {
      semanticLabel += '. Currently selected.';
    }

    return Semantics(
      label: semanticLabel,
      hint: 'Double tap to select this mood',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(mood),
            ],
          ),
        ),
      ),
    );
  }

  // Focus management for keyboard navigation
  static void announceFocus(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Custom semantic announcements for mental health contexts
  static void announceToUser(String message, {bool isImportant = false}) {
    if (isImportant) {
      HapticFeedback.heavyImpact();
    }
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Accessibility theme extensions
  static ThemeData buildAccessibleTheme({
    required BuildContext context,
    bool highContrast = false,
    double textScale = 1.0,
  }) {
    final baseTheme = Theme.of(context);

    if (highContrast) {
      return baseTheme.copyWith(
        colorScheme: ColorScheme.light(
          primary: highContrastColors['primary']!,
          secondary: highContrastColors['secondary']!,
          surface: highContrastColors['surface']!,
          error: highContrastColors['error']!,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: highContrastColors['text']!,
          onError: Colors.white,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: highContrastColors['text'],
          displayColor: highContrastColors['text'],
          fontSizeFactor: textScale,
        ),
      );
    }

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontSizeFactor: textScale),
    );
  }

  // Keyboard shortcuts for power users
  static Map<LogicalKeySet, Intent> get keyboardShortcuts => {
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyC):
        const ActivateIntent(), // Open chat
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyP):
        const ActivateIntent(), // Panic button
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyM):
        const ActivateIntent(), // Mood log
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyH):
        const ActivateIntent(), // Help/Crisis support
  };

  // Screen reader friendly time formatting
  static String formatTimeForScreenReader(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
  }

  // Mental health content warnings
  static Widget buildContentWarning({
    required String warningType,
    required Widget child,
    required VoidCallback onProceed,
  }) {
    return Semantics(
      label:
          'Content warning: This content contains $warningType topics that may be sensitive.',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              border: Border.all(color: Colors.amber[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.warning, color: Colors.amber[700]),
                const SizedBox(height: 8),
                Text(
                  'Sensitive Content Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This content may contain $warningType topics.',
                  style: TextStyle(color: Colors.amber[700]),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Proceed to view sensitive content',
                  hint: 'Double tap to continue viewing this content',
                  button: true,
                  child: ElevatedButton(
                    onPressed: onProceed,
                    child: const Text('I understand, continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom intents for keyboard shortcuts
class ActivateIntent extends Intent {
  const ActivateIntent();
}
