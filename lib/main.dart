import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/splash_view.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'config/app_theme.dart';
import 'utils/overflow_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize overflow protection system
  OverflowHandler.initialize(debugOverflowEnabled: true);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('Running app without Firebase for now...');
  }

  runApp(const MindMateApp());
}

class MindMateApp extends StatelessWidget {
  const MindMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeViewModel(), permanent: true);
    return GetBuilder<ThemeViewModel>(
      builder: (_) {
        return GetMaterialApp(
          title: 'MindMate',
          themeMode: themeController.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SplashView(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
