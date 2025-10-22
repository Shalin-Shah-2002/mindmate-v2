import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../widgets/loading_animation.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;
  late SplashViewModel _splashController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _lottieController = AnimationController(vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Initialize splash controller
    _splashController = Get.put(SplashViewModel());

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    // Start all animations
    _fadeController.forward();
    _scaleController.forward();

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
    _scaleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6D83F2), // Primary indigo
                Color(0xFF5B72E8), // Mid-tone
                Color(0xFF4961DE), // Deeper blue
                Color(0xFF00B4D8), // Cyan transition
                Color(0xFF00C6FF), // Bright cyan
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated floating circles background
              _buildFloatingCircles(),

              // Main content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo + Lottie combo - Enhanced Design
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatAnimation.value),
                                      child: child,
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer glow ring
                                      Container(
                                        width: 320,
                                        height: 320,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.15),
                                              Colors.white.withOpacity(0.05),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                      ),

                                      // Middle glow effect
                                      Container(
                                        width: 300,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF00C6FF,
                                              ).withOpacity(0.3),
                                              blurRadius: 60,
                                              spreadRadius: 10,
                                            ),
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6D83F2,
                                              ).withOpacity(0.2),
                                              blurRadius: 40,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Glass morphism container
                                      Container(
                                        width: 260,
                                        height: 260,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.1),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                      ),

                                      // Virtual Assistant Lottie Animation
                                      SizedBox(
                                        width: 240,
                                        height: 240,
                                        child: Lottie.asset(
                                          'assets/Virtual assistant.json',
                                          controller: _lottieController,
                                          onLoaded: (composition) {
                                            _lottieController
                                              ..duration = composition.duration
                                              ..forward();
                                          },
                                          fit: BoxFit.contain,
                                          repeat: false,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 240,
                                                  height: 240,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.chat_bubble_outline,
                                                    size: 100,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 48),

                              // App Name with animated text
                              SizedBox(
                                height: 60,
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      TypewriterAnimatedText(
                                        'MindMate',
                                        speed: const Duration(
                                          milliseconds: 150,
                                        ),
                                        cursor: '',
                                      ),
                                    ],
                                    totalRepeatCount: 1,
                                    pause: const Duration(milliseconds: 100),
                                    displayFullTextOnTap: true,
                                    stopPauseOnTap: false,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Tagline with gradient background
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Your Mental Wellness Companion',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle with fade animation
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      FadeAnimatedText(
                                        '✨ Seek Help • Find Support • Grow Together ✨',
                                        duration: const Duration(
                                          milliseconds: 2000,
                                        ),
                                      ),
                                    ],
                                    totalRepeatCount: 1,
                                    pause: const Duration(milliseconds: 100),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Loading indicator
                              GetBuilder<SplashViewModel>(
                                builder: (controller) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      // Custom Lottie loading animation
                                      const LoadingAnimation(
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 16),
                                      Obx(
                                        () => AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          child: Container(
                                            key: ValueKey(
                                              controller.statusMessage.value,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              controller.statusMessage.value,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCircles() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Stack(
          children: [
            // Circle 1 - Top left with gradient
            Positioned(
              top: -50 + (_floatAnimation.value * 2),
              left: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Circle 2 - Top right with gradient
            Positioned(
              top: 100 - (_floatAnimation.value * 1.5),
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C6FF).withOpacity(0.15),
                      const Color(0xFF00C6FF).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Circle 3 - Middle left with gradient
            Positioned(
              top: 300 + (_floatAnimation.value * 1.8),
              left: -80,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Circle 4 - Bottom right with gradient
            Positioned(
              bottom: -40 - (_floatAnimation.value * 2),
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6D83F2).withOpacity(0.15),
                      const Color(0xFF6D83F2).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Circle 5 - Bottom left with gradient
            Positioned(
              bottom: 150 + (_floatAnimation.value * 1.3),
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Sparkle effects - Small circles
            Positioned(
              top: 120 + (_floatAnimation.value * 0.5),
              left: 50,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 200 - (_floatAnimation.value * 0.8),
              right: 80,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 180 + (_floatAnimation.value * 0.6),
              left: 100,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C6FF).withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C6FF).withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 250 - (_floatAnimation.value * 0.4),
              right: 60,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6D83F2).withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D83F2).withOpacity(0.5),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
