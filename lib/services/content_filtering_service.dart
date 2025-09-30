class ContentFilteringService {
  // Crisis keywords that require immediate intervention
  static const List<String> _crisisKeywords = [
    'suicide',
    'kill myself',
    'end my life',
    'want to die',
    'not worth living',
    'end it all',
    'better off dead',
    'harm myself',
    'hurt myself',
    'cut myself',
    'overdose',
    'jump off',
    'hanging',
    'pills',
    'razor',
  ];

  // Predatory/exploitation patterns
  static const List<String> _predatoryPatterns = [
    'give me your number',
    'meet in person',
    'send photos',
    'what are you wearing',
    'are you alone',
    'keep this secret',
    'don\'t tell anyone',
    'special relationship',
    'mature for your age',
    'trust me',
    'I understand you',
    'nobody else gets you',
  ];

  // Personal information requests
  static const List<String> _personalInfoPatterns = [
    'phone number',
    'address',
    'where do you live',
    'full name',
    'what school',
    'where do you work',
    'social security',
    'credit card',
    'bank account',
    'password',
  ];

  // Triggering content for mental health
  static const List<String> _triggerWords = [
    'worthless',
    'pathetic',
    'failure',
    'loser',
    'ugly',
    'stupid',
    'useless',
    'nobody likes you',
    'kill yourself',
    'just die',
    'waste of space',
    'burden',
  ];

  // Profanity/harassment terms (normalized to lowercase)
  static const List<String> _profanityTerms = [
    'fuck',
    'fucker',
    'motherfucker',
    'mf',
    'bitch',
    'asshole',
    'bastard',
    'dick',
    'pussy',
    'cunt',
    'slut',
    'whore',
    'loser',
    'looser',
    'retard',
    'stfu',
  ];

  // Hindi transliterations and variations (lowercase, no diacritics)
  static const List<String> _hindiProfanityTranslit = [
    'madarchod',
    'maderchod',
    'madrchod',
    'madarchot',
    'bhenchod',
    'bhencod',
    'bhenchot',
    'chutiya',
    'chutia',
    'chutiye',
    'chutya',
    'gandu',
    'gaand',
    'harami',
    'randi',
  ];

  // Common Devanagari forms (Unicode)
  static const List<String> _hindiProfanityDevanagari = [
    'मादरचोद',
    'मादरचोट',
    'भेंचोद',
    'भेंचोट',
    'चूतिया',
    'चुतिया',
    'गांडू',
    'गांड',
    'हरामी',
    'रंडी',
  ];

  // Regex patterns to detect spaced/obfuscated Hindi abuse phrases
  static final List<RegExp> _abusiveHindiPatterns = [
    // e.g., "teri ma chod dunga", "maa ki ch**d", variations with k/ki/ke and spaces
    RegExp(
      r"\b(teri|tumhari|uski|apni)?\s*(maa|ma|madar\w*)\s*(?:ki|ke|ka|k)?\s*cho?d\w*",
      caseSensitive: false,
      unicode: true,
    ),
    // e.g., "bhen ki ch*od", "behen ko chod", "bhen ka lund"
    RegExp(
      r"\b(bhen|behen)\s*(?:ki|ke|ka|k)?\s*(cho?d\w*|lund\w*)",
      caseSensitive: false,
      unicode: true,
    ),
    // direct mentions of lund/gaand with relational pronouns
    RegExp(
      r"\b(teri|tumhari|uski)?\s*(bhen|behen|maa|ma)\s*(?:ki|ke|ka|k)?\s*lund\w*",
      caseSensitive: false,
      unicode: true,
    ),
  ];

  // Substance abuse indicators
  static const List<String> _substanceAbuseKeywords = [
    'getting high',
    'need drugs',
    'want to drink',
    'getting wasted',
    'party hard',
    'blackout drunk',
    'cocaine',
    'heroin',
    'methamphetamine',
    'prescription abuse',
  ];

  // Threat/violence indicators (English + Hinglish transliterations)
  static const List<String> _threatKeywords = [
    // English
    'kill you', 'beat you', 'rape you', 'stab you', 'acid attack', 'kidnap',
    'murder you', 'i will kill', 'i will rape', 'i will beat you',
    // Hinglish
    'maar dunga', 'mar dunga', 'kaat dunga', 'chod dunga', 'utha lunga',
    'jeb me daal dunga', 'kidnap kar lunga', 'tezab dal dunga', 'jala dunga',
  ];

  // Threat regex patterns to catch spacing/obfuscation and inflections
  static final List<RegExp> _threatPatterns = [
    RegExp(r"\bmaar\s*dung[aieou]\b", caseSensitive: false, unicode: true),
    RegExp(r"\bmar\s*dung[aieou]\b", caseSensitive: false, unicode: true),
    RegExp(r"\bka?t\s*dung[aieou]\b", caseSensitive: false, unicode: true),
    RegExp(r"\bcho?d\s*dung[aieou]\b", caseSensitive: false, unicode: true),
    RegExp(r"\b(rape|kill|murder)\s+(you|u)\b", caseSensitive: false),
    RegExp(r"\bacid\s+attack\b", caseSensitive: false),
    RegExp(
      r"\btezab\s+dal\s*dung[aieou]\b",
      caseSensitive: false,
      unicode: true,
    ),
  ];

  /// Main content filtering function
  static ContentFilterResult filterMessage(String content) {
    final lowerContent = content.toLowerCase();
    final result = ContentFilterResult();

    // Check for crisis indicators
    for (final keyword in _crisisKeywords) {
      if (lowerContent.contains(keyword)) {
        result.crisisFlags.add('suicide_ideation');
        result.safetyScore = 0.0;
        result.requiresImmediateIntervention = true;
        break;
      }
    }

    // Check for predatory behavior
    for (final pattern in _predatoryPatterns) {
      if (lowerContent.contains(pattern)) {
        result.crisisFlags.add('predatory_behavior');
        result.safetyScore = (result.safetyScore * 0.1).clamp(0.0, 1.0);
        result.shouldBlock = true;
        break;
      }
    }

    // Check for personal info requests
    for (final pattern in _personalInfoPatterns) {
      if (lowerContent.contains(pattern)) {
        result.crisisFlags.add('personal_info_request');
        result.safetyScore = (result.safetyScore * 0.3).clamp(0.0, 1.0);
        result.requiresModeration = true;
        break;
      }
    }

    // Check for triggering content (abusive/harsh words)
    for (final trigger in _triggerWords) {
      if (lowerContent.contains(trigger)) {
        result.crisisFlags.add('triggering_content');
        // Reduce safety score but don't always require moderation on single occurrence
        // Let AI analysis and trust level policy combine to decide
        result.safetyScore = (result.safetyScore * 0.7).clamp(0.0, 1.0);
        break;
      }
    }

    // Check for profanity/harassment (requires moderation)
    bool profanityHit = false;
    for (final term in _profanityTerms) {
      if (lowerContent.contains(term)) {
        profanityHit = true;
        break;
      }
    }

    // Check Hindi transliterations directly
    if (!profanityHit) {
      for (final term in _hindiProfanityTranslit) {
        if (lowerContent.contains(term)) {
          profanityHit = true;
          break;
        }
      }
    }

    // Check Devanagari directly
    if (!profanityHit) {
      for (final term in _hindiProfanityDevanagari) {
        if (content.contains(term)) {
          // keep original for Unicode
          profanityHit = true;
          break;
        }
      }
    }

    // Normalized collapse: remove non-letters/digits to catch obfuscations
    if (!profanityHit) {
      final collapsed = lowerContent.replaceAll(
        RegExp(r'[^a-z0-9\u0900-\u097F]'),
        '',
      );
      for (final term in [..._hindiProfanityTranslit]) {
        if (collapsed.contains(term)) {
          profanityHit = true;
          break;
        }
      }
    }

    // Check regex-based abusive phrase patterns
    if (!profanityHit) {
      for (final re in _abusiveHindiPatterns) {
        if (re.hasMatch(content)) {
          profanityHit = true;
          break;
        }
      }
    }

    if (profanityHit) {
      result.crisisFlags.add('harassment_profanity');
      result.safetyScore = (result.safetyScore * 0.4).clamp(0.0, 1.0);
      result.requiresModeration = true;
    }

    // Check for substance abuse mentions
    for (final keyword in _substanceAbuseKeywords) {
      if (lowerContent.contains(keyword)) {
        result.crisisFlags.add('substance_abuse');
        // Reduce score; moderation will be decided in combined analysis
        result.safetyScore = (result.safetyScore * 0.75).clamp(0.0, 1.0);
        break;
      }
    }

    // Additional safety checks
    _checkForSpam(content, result);
    _checkForExcessiveCaps(content, result);
    _checkForRepetitiveContent(content, result);

    // Threat detection (apply after general checks to ensure block)
    bool threatDetected = false;
    for (final k in _threatKeywords) {
      if (lowerContent.contains(k)) {
        threatDetected = true;
        break;
      }
    }
    if (!threatDetected) {
      for (final re in _threatPatterns) {
        if (re.hasMatch(content)) {
          threatDetected = true;
          break;
        }
      }
    }
    if (threatDetected) {
      result.crisisFlags.add('threat');
      result.safetyScore = 0.0;
      result.shouldBlock = true;
      result.requiresModeration = true;
    }

    return result;
  }

  /// Check for spam patterns
  static void _checkForSpam(String content, ContentFilterResult result) {
    final repeatedChars = RegExp(r'(.)\1{4,}'); // 5+ repeated characters
    // Fixed emoji regex: matches any emoji character repeated 5+ times
    final excessiveEmojis = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}]{5,}',
      unicode: true,
    );

    if (repeatedChars.hasMatch(content) || excessiveEmojis.hasMatch(content)) {
      result.crisisFlags.add('spam');
      result.safetyScore = (result.safetyScore * 0.8).clamp(0.0, 1.0);
    }
  }

  /// Check for excessive caps (shouting)
  static void _checkForExcessiveCaps(
    String content,
    ContentFilterResult result,
  ) {
    if (content.length > 10) {
      final capsCount = content
          .split('')
          .where(
            (char) => char == char.toUpperCase() && char != char.toLowerCase(),
          )
          .length;
      final capsPercentage = capsCount / content.length;

      if (capsPercentage > 0.7) {
        result.crisisFlags.add('excessive_caps');
        result.safetyScore = (result.safetyScore * 0.9).clamp(0.0, 1.0);
      }
    }
  }

  /// Check for repetitive content
  static void _checkForRepetitiveContent(
    String content,
    ContentFilterResult result,
  ) {
    final words = content.toLowerCase().split(' ');
    final wordSet = words.toSet();

    if (words.length > 10 && wordSet.length < words.length * 0.5) {
      result.crisisFlags.add('repetitive');
      result.safetyScore = (result.safetyScore * 0.85).clamp(0.0, 1.0);
    }
  }

  /// Enhanced crisis detection using multiple indicators
  static bool isCrisisMessage(
    String content, {
    int? userMoodLevel,
    List<String>? recentMessages,
  }) {
    final filterResult = filterMessage(content);

    // Immediate crisis indicators
    if (filterResult.crisisFlags.contains('suicide_ideation')) {
      return true;
    }

    // Contextual crisis detection
    if (userMoodLevel != null && userMoodLevel <= 2) {
      final concerningPhrases = [
        'can\'t take it anymore',
        'giving up',
        'no hope',
        'too much pain',
        'end the suffering',
        'nobody cares',
        'disappear forever',
        'make it stop',
      ];

      final lowerContent = content.toLowerCase();
      for (final phrase in concerningPhrases) {
        if (lowerContent.contains(phrase)) {
          return true;
        }
      }
    }

    // Pattern analysis with recent messages
    if (recentMessages != null && recentMessages.length >= 3) {
      final allContent = recentMessages.join(' ').toLowerCase();
      final negativeWords = [
        'hopeless',
        'pointless',
        'alone',
        'empty',
        'numb',
        'broken',
        'worthless',
        'tired',
        'exhausted',
        'done',
      ];

      int negativeCount = 0;
      for (final word in negativeWords) {
        if (allContent.contains(word)) negativeCount++;
      }

      if (negativeCount >= 5) return true;
    }

    return false;
  }

  /// Generate appropriate response for crisis situations
  static String generateCrisisResponse(List<String> crisisFlags) {
    if (crisisFlags.contains('suicide_ideation')) {
      return '''
🆘 **Crisis Support Available**

I'm concerned about what you're sharing. You're not alone, and help is available right now:

• **Tele-MANAS (India)**: Call 14416 or 1-800-891-4416
• **Emergency Services (India)**: 112

Would you like me to connect you with a crisis counselor immediately?

Remember: You matter, your life has value, and there are people who want to help. 💙
''';
    }

    if (crisisFlags.contains('predatory_behavior')) {
      return '''
🛡️ **Safety Notice**

This message has been flagged for potentially inappropriate content. 

If someone is making you uncomfortable or asking for personal information:
• Don't share personal details (phone, address, etc.)
• Report the behavior immediately
• Talk to a trusted adult or counselor

Your safety is our priority.
''';
    }

    return '''
💙 **Support Available**

It seems like you might be going through a difficult time. 

Our support resources are here for you:
• Join a support group chat
• Connect with peer mentors
• Access professional help resources

You don't have to face this alone.
''';
  }

  /// Filter content for specific user based on their vulnerability level
  static ContentFilterResult filterForUser(
    String content,
    int userMoodLevel,
    List<String> personalTriggers,
  ) {
    final baseResult = filterMessage(content);

    // Additional filtering for vulnerable users
    if (userMoodLevel <= 3) {
      // More strict filtering for users in crisis
      baseResult.safetyScore = (baseResult.safetyScore * 0.8).clamp(0.0, 1.0);

      // Check personal triggers
      final lowerContent = content.toLowerCase();
      for (final trigger in personalTriggers) {
        if (lowerContent.contains(trigger.toLowerCase())) {
          baseResult.crisisFlags.add('personal_trigger');
          baseResult.safetyScore = (baseResult.safetyScore * 0.5).clamp(
            0.0,
            1.0,
          );
          baseResult.shouldHideFromUser = true;
          break;
        }
      }
    }

    return baseResult;
  }

  /// Generate safe alternative content suggestions
  static String generateSafeAlternative(
    String originalContent,
    List<String> crisisFlags,
  ) {
    if (crisisFlags.contains('triggering_content')) {
      return 'I\'m sharing some difficult feelings right now and could use support.';
    }

    if (crisisFlags.contains('excessive_caps')) {
      return originalContent.toLowerCase();
    }

    if (crisisFlags.contains('personal_info_request')) {
      return 'I\'d like to connect more, but let\'s keep our conversation here in the safe chat space.';
    }

    return originalContent;
  }
}

/// Result class for content filtering
class ContentFilterResult {
  double safetyScore;
  List<String> crisisFlags;
  bool shouldBlock;
  bool requiresModeration;
  bool requiresImmediateIntervention;
  bool shouldHideFromUser;
  String? suggestedAlternative;
  String? moderatorNote;

  ContentFilterResult({
    this.safetyScore = 1.0,
    List<String>? crisisFlags,
    this.shouldBlock = false,
    this.requiresModeration = false,
    this.requiresImmediateIntervention = false,
    this.shouldHideFromUser = false,
    this.suggestedAlternative,
    this.moderatorNote,
  }) : crisisFlags = crisisFlags ?? [];

  bool get isClean => safetyScore > 0.8 && crisisFlags.isEmpty;
  bool get needsAttention => safetyScore < 0.5 || crisisFlags.isNotEmpty;
}

/// Specialized content filters for different scenarios
class SpecializedFilters {
  /// Filter for new users (more restrictive)
  static ContentFilterResult filterForNewUser(String content) {
    final result = ContentFilteringService.filterMessage(content);

    // New users get stricter filtering
    result.safetyScore = (result.safetyScore * 0.9).clamp(0.0, 1.0);

    // Block anything below 0.7 safety score for new users
    if (result.safetyScore < 0.7) {
      result.requiresModeration = true;
    }

    return result;
  }

  /// Filter for crisis support rooms (most restrictive)
  static ContentFilterResult filterForCrisisRoom(String content) {
    final result = ContentFilteringService.filterMessage(content);

    // Crisis rooms require professional moderation for anything concerning
    if (result.safetyScore < 0.9 || result.crisisFlags.isNotEmpty) {
      result.requiresModeration = true;
    }

    return result;
  }

  /// Filter for general chat (least restrictive)
  static ContentFilterResult filterForGeneralChat(String content) {
    final result = ContentFilteringService.filterMessage(content);

    // Only block clearly harmful content in general chat
    if (result.safetyScore < 0.3) {
      result.shouldBlock = true;
    }

    return result;
  }
}
