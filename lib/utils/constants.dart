class AppConstants {
  static const String appName = 'MindMate';
}

class StringUtils {
  /// Safely formats a userId for display by truncating to 8 characters if longer
  static String formatUserId(String userId) {
    if (userId.isEmpty) return 'Unknown User';
    return userId.length >= 8 ? userId.substring(0, 8) : userId;
  }

  /// Formats userId with "User " prefix for display
  static String formatUserDisplayName(String userId) {
    return 'User ${formatUserId(userId)}';
  }
}
