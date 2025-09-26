import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../viewmodels/splash_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late SplashViewModel _splashController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _lottieController = AnimationController(vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Initialize splash controller
    _splashController = Get.put(SplashViewModel());

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    // Start fade-in animation
    _fadeController.forward();

    // Listen for Lottie animation completion
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Delay briefly then navigate
        Future.delayed(const Duration(milliseconds: 800), () {
          _splashController.navigateToNextScreen();
        });
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
              Theme.of(context).primaryColor.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spacer to push content up slightly
                const Spacer(flex: 2),

                // Lottie Animation
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    'assets/Mental Wellbeing - Seek Help.json',
                    controller: _lottieController,
                    onLoaded: (composition) {
                      _lottieController
                        ..duration = composition.duration
                        ..forward();
                    },
                    fit: BoxFit.contain,
                    repeat: false,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback UI if animation fails to load
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.psychology,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // App Name with enhanced styling
                Text(
                  'MindMate',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline with better styling
                Text(
                  'Your Mental Wellness Companion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Seek Help • Find Support • Grow Together',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // Loading indicator with enhanced styling
                GetBuilder<SplashViewModel>(
                  builder: (controller) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.9),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              controller.statusMessage.value,
                              key: ValueKey(controller.statusMessage.value),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
