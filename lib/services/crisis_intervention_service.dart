import 'package:url_launcher/url_launcher.dart';
import '../services/gemini_ai_service.dart';
import '../models/user_chat_profile.dart';

class CrisisInterventionService {
  // Crisis assessment questionnaire
  static const List<CrisisQuestion> _crisisQuestions = [
    CrisisQuestion(
      id: 'suicidal_thoughts',
      text: 'Are you having thoughts of suicide or self-harm?',
      type: CrisisQuestionType.yesNo,
      severity: CrisisSeverity.critical,
    ),
    CrisisQuestion(
      id: 'immediate_danger',
      text: 'Are you in immediate physical danger?',
      type: CrisisQuestionType.yesNo,
      severity: CrisisSeverity.critical,
    ),
    CrisisQuestion(
      id: 'safety_plan',
      text: 'Do you have a plan to hurt yourself?',
      type: CrisisQuestionType.yesNo,
      severity: CrisisSeverity.critical,
    ),
    CrisisQuestion(
      id: 'support_system',
      text: 'Do you have someone you trust that you can talk to right now?',
      type: CrisisQuestionType.yesNo,
      severity: CrisisSeverity.moderate,
    ),
    CrisisQuestion(
      id: 'coping_ability',
      text:
          'On a scale of 1-10, how able do you feel to cope with your current situation?',
      type: CrisisQuestionType.scale,
      severity: CrisisSeverity.moderate,
    ),
  ];

  /// Immediate crisis response - triggered automatically
  static Future<CrisisInterventionResult> triggerCrisisIntervention({
    required String userId,
    required String triggerMessage,
    required int userMoodLevel,
    List<String>? crisisFlags,
  }) async {
    try {
      print(
        'CrisisInterventionService: Triggering intervention for user $userId',
      );

      // Generate AI-powered crisis response
      final aiResponse = await GeminiAIService.generateCrisisSupport(
        triggerMessage,
        moodLevel: userMoodLevel,
        crisisFlags: crisisFlags,
      );

      // Determine intervention level
      final interventionLevel = _assessInterventionLevel(
        triggerMessage,
        userMoodLevel,
        crisisFlags,
      );

      // Get appropriate resources
      final resources = _getResourcesForIntervention(interventionLevel);

      return CrisisInterventionResult(
        interventionLevel: interventionLevel,
        aiResponse: aiResponse,
        emergencyContacts: resources.emergencyContacts,
        immediateActions: resources.immediateActions,
        followUpActions: resources.followUpActions,
        requiresProfessionalContact:
            interventionLevel == CrisisLevel.severe ||
            interventionLevel == CrisisLevel.imminent,
      );
    } catch (e) {
      print('CrisisInterventionService: Error in crisis intervention: $e');
      return _getEmergencyFallbackResponse();
    }
  }

  /// Interactive crisis assessment
  static Future<CrisisAssessmentResult> conductCrisisAssessment(
    String userId,
  ) async {
    // This would typically be called from a UI component
    // For now, return a structured assessment framework
    return CrisisAssessmentResult(
      questions: _crisisQuestions,
      recommendedAction: 'Begin interactive assessment',
      estimatedTime: Duration(minutes: 5),
    );
  }

  /// Connect user to professional help
  static Future<bool> connectToProfessionalHelp({
    required String userId,
    required CrisisLevel crisisLevel,
    String? preferredContact,
  }) async {
    try {
      switch (crisisLevel) {
        case CrisisLevel.imminent:
          // Immediate emergency services
          return await _callEmergencyServices();

        case CrisisLevel.severe:
          // Crisis hotline
          return await _connectToCrisisHotline(preferredContact);

        case CrisisLevel.moderate:
          // Crisis text line or counseling services
          return await _connectToCrisisText();

        case CrisisLevel.mild:
          // Self-help resources and scheduled counseling
          return await _provideSelfHelpResources(userId);
      }
    } catch (e) {
      print(
        'CrisisInterventionService: Error connecting to professional help: $e',
      );
      return false;
    }
  }

  /// Generate personalized safety plan
  static Future<SafetyPlan> generatePersonalizedSafetyPlan({
    required String userId,
    required UserChatProfile userProfile,
    Map<String, dynamic>? assessmentAnswers,
  }) async {
    try {
      // Use AI to generate personalized safety plan
      // TODO: Call Gemini API to generate personalized plan
      // For now, return a template safety plan

      return SafetyPlan(
        userId: userId,
        warningSigns: [
          'Feeling overwhelmed or hopeless',
          'Isolating from friends and family',
          'Changes in sleep or appetite',
          'Increased substance use',
        ],
        copingStrategies: [
          'Practice deep breathing exercises',
          'Go for a walk or do light exercise',
          'Listen to calming music',
          'Call a trusted friend or family member',
          'Use grounding techniques (5-4-3-2-1 method)',
        ],
        supportContacts: [
          SafetyContact(
            name: 'Trusted Friend/Family',
            phone: '(Fill in)',
            relationship: 'personal',
          ),
          SafetyContact(
            name: 'Crisis Text Line',
            phone: '741741',
            relationship: 'professional',
          ),
          SafetyContact(
            name: 'National Suicide Prevention Lifeline',
            phone: '988',
            relationship: 'professional',
          ),
        ],
        professionalResources: [
          'Local mental health services',
          'Employee assistance program (if applicable)',
          'Student counseling services (if applicable)',
          'Online therapy platforms',
        ],
        environmentSafety: [
          'Remove or secure items that could be used for self-harm',
          'Ask someone to stay with you if feeling unsafe',
          'Have emergency numbers readily available',
          'Create a calm, safe space in your home',
        ],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('CrisisInterventionService: Error generating safety plan: $e');
      return _getDefaultSafetyPlan(userId);
    }
  }

  /// Track intervention effectiveness
  static Future<void> recordInterventionOutcome({
    required String userId,
    required String interventionId,
    required InterventionOutcome outcome,
    String? userFeedback,
  }) async {
    try {
      // TODO: Store in Firebase for tracking effectiveness
      print(
        'CrisisInterventionService: Recording intervention outcome: $outcome',
      );
    } catch (e) {
      print(
        'CrisisInterventionService: Error recording intervention outcome: $e',
      );
    }
  }

  // Private helper methods

  static CrisisLevel _assessInterventionLevel(
    String message,
    int moodLevel,
    List<String>? crisisFlags,
  ) {
    final lowerMessage = message.toLowerCase();

    // Imminent danger keywords
    if (lowerMessage.contains('kill myself') ||
        lowerMessage.contains('end my life') ||
        lowerMessage.contains('suicide') ||
        lowerMessage.contains('overdose') ||
        moodLevel <= 1) {
      return CrisisLevel.imminent;
    }

    // Severe crisis indicators
    if (lowerMessage.contains('want to die') ||
        lowerMessage.contains('can\'t take it anymore') ||
        lowerMessage.contains('no point in living') ||
        moodLevel <= 2) {
      return CrisisLevel.severe;
    }

    // Moderate crisis indicators
    if (lowerMessage.contains('hopeless') ||
        lowerMessage.contains('worthless') ||
        lowerMessage.contains('give up') ||
        moodLevel <= 3) {
      return CrisisLevel.moderate;
    }

    return CrisisLevel.mild;
  }

  static CrisisResources _getResourcesForIntervention(CrisisLevel level) {
    switch (level) {
      case CrisisLevel.imminent:
        return CrisisResources(
          emergencyContacts: [
            EmergencyContact('Emergency Services (India)', '112', true),
            EmergencyContact('Tele-MANAS', '14416', true),
            EmergencyContact('Tele-MANAS Alt', '18008914416', true),
          ],
          immediateActions: [
            'Call 112 immediately if you are in danger',
            'Go to your nearest hospital emergency department',
            'Call Tele-MANAS: 14416 or 1-800-891-4416',
            'Remove any means of self-harm from your environment',
          ],
          followUpActions: [
            'Schedule emergency psychiatric evaluation',
            'Contact family member or trusted friend',
            'Follow up with mental health professional within 24 hours',
          ],
        );

      case CrisisLevel.severe:
        return CrisisResources(
          emergencyContacts: [
            EmergencyContact('Tele-MANAS', '14416', false),
            EmergencyContact('Tele-MANAS Alt', '18008914416', false),
          ],
          immediateActions: [
            'Call or text a crisis hotline',
            'Reach out to a trusted friend or family member',
            'Remove items that could be used for self-harm',
            'Stay in a safe, supervised environment',
          ],
          followUpActions: [
            'Schedule appointment with mental health professional',
            'Create or review safety plan',
            'Consider intensive outpatient treatment',
          ],
        );

      case CrisisLevel.moderate:
        return CrisisResources(
          emergencyContacts: [
            EmergencyContact('Tele-MANAS', '14416', false),
            EmergencyContact('Tele-MANAS Alt', '18008914416', false),
          ],
          immediateActions: [
            'Use coping strategies from your safety plan',
            'Reach out to support system',
            'Consider crisis text line support',
            'Practice grounding techniques',
          ],
          followUpActions: [
            'Schedule therapy appointment',
            'Review and update safety plan',
            'Increase social support activities',
          ],
        );

      case CrisisLevel.mild:
        return CrisisResources(
          emergencyContacts: [],
          immediateActions: [
            'Practice self-care activities',
            'Use learned coping strategies',
            'Connect with support system',
            'Engage in pleasant activities',
          ],
          followUpActions: [
            'Continue regular therapy if applicable',
            'Monitor mood and symptoms',
            'Maintain healthy routines',
          ],
        );
    }
  }

  static Future<bool> _callEmergencyServices() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: '112');
      if (await canLaunchUrl(phoneUri)) {
        return await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error calling emergency services: $e');
    }
    return false;
  }

  static Future<bool> _connectToCrisisHotline(String? preferredContact) async {
    try {
      final phoneNumber = preferredContact ?? '14416';
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        return await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error connecting to crisis hotline: $e');
    }
    return false;
  }

  static Future<bool> _connectToCrisisText() async {
    try {
      final Uri smsUri = Uri(scheme: 'tel', path: '18008914416');
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      }
    } catch (e) {
      print('Error connecting to crisis text: $e');
    }
    return false;
  }

  static Future<bool> _provideSelfHelpResources(String userId) async {
    // TODO: Navigate to self-help resources in app
    return true;
  }

  static CrisisInterventionResult _getEmergencyFallbackResponse() {
    return CrisisInterventionResult(
      interventionLevel: CrisisLevel.severe,
      aiResponse: '''
I'm concerned about you and want to help. If you're having thoughts of suicide or self-harm, please reach out for immediate support:

🆘 **Tele-MANAS (India)**: Call 14416 or 1-800-891-4416 (24/7)
🆘 **Emergency**: Call 112 if you're in immediate danger

You are not alone. There are people who care about you and want to help.
''',
      emergencyContacts: [
        EmergencyContact('Tele-MANAS', '14416', false),
        EmergencyContact('Emergency Services (India)', '112', true),
      ],
      immediateActions: [
        'Call a crisis hotline immediately',
        'Reach out to a trusted person',
        'Go to a safe place',
      ],
      followUpActions: ['Seek professional help', 'Create a safety plan'],
      requiresProfessionalContact: true,
    );
  }

  static SafetyPlan _getDefaultSafetyPlan(String userId) {
    return SafetyPlan(
      userId: userId,
      warningSigns: [
        'Feeling hopeless or trapped',
        'Increased substance use',
        'Withdrawing from others',
        'Extreme mood changes',
      ],
      copingStrategies: [
        'Deep breathing exercises',
        'Call a friend or family member',
        'Listen to music',
        'Take a walk',
        'Practice mindfulness',
      ],
      supportContacts: [
        SafetyContact(
          name: 'Crisis Text Line',
          phone: '741741',
          relationship: 'professional',
        ),
        SafetyContact(
          name: 'Crisis Lifeline',
          phone: '988',
          relationship: 'professional',
        ),
      ],
      professionalResources: [
        'Tele-MANAS (India): 14416 / 1-800-891-4416',
        'Emergency services (India): 112',
      ],
      environmentSafety: [
        'Remove potentially harmful items',
        'Stay with trusted people when distressed',
        'Have emergency numbers easily accessible',
      ],
      createdAt: DateTime.now(),
    );
  }
}

// Data classes

enum CrisisLevel { mild, moderate, severe, imminent }

enum CrisisQuestionType { yesNo, scale, multiChoice, text }

enum CrisisSeverity { low, moderate, critical }

enum InterventionOutcome { helpful, somewhat_helpful, not_helpful, harmful }

class CrisisQuestion {
  final String id;
  final String text;
  final CrisisQuestionType type;
  final CrisisSeverity severity;
  final List<String>? options;

  const CrisisQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.severity,
    this.options,
  });
}

class CrisisInterventionResult {
  final CrisisLevel interventionLevel;
  final String aiResponse;
  final List<EmergencyContact> emergencyContacts;
  final List<String> immediateActions;
  final List<String> followUpActions;
  final bool requiresProfessionalContact;

  CrisisInterventionResult({
    required this.interventionLevel,
    required this.aiResponse,
    required this.emergencyContacts,
    required this.immediateActions,
    required this.followUpActions,
    required this.requiresProfessionalContact,
  });
}

class CrisisAssessmentResult {
  final List<CrisisQuestion> questions;
  final String recommendedAction;
  final Duration estimatedTime;

  CrisisAssessmentResult({
    required this.questions,
    required this.recommendedAction,
    required this.estimatedTime,
  });
}

class CrisisResources {
  final List<EmergencyContact> emergencyContacts;
  final List<String> immediateActions;
  final List<String> followUpActions;

  CrisisResources({
    required this.emergencyContacts,
    required this.immediateActions,
    required this.followUpActions,
  });
}

class EmergencyContact {
  final String name;
  final String number;
  final bool isEmergency;

  EmergencyContact(this.name, this.number, this.isEmergency);
}

class SafetyPlan {
  final String userId;
  final List<String> warningSigns;
  final List<String> copingStrategies;
  final List<SafetyContact> supportContacts;
  final List<String> professionalResources;
  final List<String> environmentSafety;
  final DateTime createdAt;

  SafetyPlan({
    required this.userId,
    required this.warningSigns,
    required this.copingStrategies,
    required this.supportContacts,
    required this.professionalResources,
    required this.environmentSafety,
    required this.createdAt,
  });
}

class SafetyContact {
  final String name;
  final String phone;
  final String relationship;

  SafetyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });
}
