import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'views/splash_view.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'utils/overflow_handler.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';

void main() async {
  // Preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

    // Initialize Supabase for notifications
    await SupabaseConfig.initialize();
    print('Supabase initialized successfully');

    // Initialize OneSignal for push notifications
    await NotificationService.initialize();
    print('OneSignal initialized successfully');

    // Initialize default chat rooms
    await ChatService.initializeDefaultChatRooms();
  } catch (e) {
    print('Initialization failed: $e');
    print('Running app with limited functionality...');
  }

  // Initialize global controllers before runApp to avoid creating them during build
  Get.put(ThemeViewModel(), permanent: true);
  Get.put(AuthViewModel(), permanent: true);

  runApp(const MindMateApp());

  // Remove native splash after a brief delay to show Flutter splash
  Future.delayed(const Duration(milliseconds: 500), () {
    FlutterNativeSplash.remove();
  });
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
