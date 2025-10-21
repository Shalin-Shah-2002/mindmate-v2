import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/splash_view.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'config/app_theme.dart';
import 'utils/overflow_handler.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style globally - white status bar with dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize overflow protection system
  OverflowHandler.initialize(debugOverflowEnabled: true);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize default chat rooms
    await ChatService.initializeDefaultChatRooms();
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('Running app without Firebase for now...');
  }

  // Initialize global controllers before runApp to avoid creating them during build
  Get.put(ThemeViewModel(), permanent: true);
  Get.put(AuthViewModel(), permanent: true);

  runApp(const MindMateApp());
}

class MindMateApp extends StatelessWidget {
  const MindMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeViewModel>();

    return GetBuilder<ThemeViewModel>(
      builder: (_) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: GetMaterialApp(
            title: 'MindMate',
            themeMode: themeController.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const SplashView(),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
