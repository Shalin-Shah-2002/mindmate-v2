import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:shimmer/shimmer.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../search/search_results_view.dart';
import '../mood/mood_tracker_view.dart';
import '../meditation/meditation_view.dart';
import '../resources/resources_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get or create the AuthViewModel safely
    late AuthViewModel authController;
    try {
      authController = Get.find<AuthViewModel>();
    } catch (e) {
      authController = Get.put(AuthViewModel());
    }

    return Container(
      // Softer, lighter background to reduce visual load
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9FBFF), // very light indigo tint
            Color(0xFFF7FFFB), // very light mint tint
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gradient brand text
                  _gradientText(
                    'MindMate',
                    const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                    ),
                    const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Obx(
                    () => authController.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _gradientIconButton(
                            icon: Icons.logout,
                            onTap: () => authController.signOut(),
                            colors: const [
                              Color(0xFF8E97FD),
                              Color(0xFF6D83F2),
                            ],
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => const SearchResultsView(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: _gradientBorderContainer(
                  borderRadius: 14,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF6D83F2)),
                      const SizedBox(width: 12),
                      Text(
                        'Search for users...',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User profile section - vibrant gradient banner
              Obx(() {
                if (authController.userModel != null) {
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6D83F2,
                              ).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  authController.userModel!.photoUrl.isNotEmpty
                                  ? NetworkImage(
                                      authController.userModel!.photoUrl,
                                    )
                                  : null,
                              backgroundColor: Colors.white,
                              child: authController.userModel!.photoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome, ${authController.userModel!.name}!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              authController.userModel!.bio.isNotEmpty
                                  ? authController.userModel!.bio
                                  : 'Your mental wellness journey starts here',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      _welcomeCardShimmerOverlay(),
                    ],
                  );
                } else {
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Welcome to MindMate!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Your mental wellness companion',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      _welcomeCardShimmerOverlay(),
                    ],
                  );
                }
              }),
              const SizedBox(height: 32),

              // Quick Actions
              _gradientText(
                'Quick Actions',
                const LinearGradient(
                  colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                ),
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIllustrationActionCard(
                          assetPath:
                              'assets/illustrations/Young Woman Chatting on Smartphone.png',
                          label: 'Mood Tracking',
                          color: Colors.blue,
                          onTap: () {
                            Get.to(
                              () => const MoodTrackerView(),
                              transition: Transition.rightToLeft,
                              duration: const Duration(milliseconds: 300),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIllustrationActionCard(
                          assetPath: 'assets/illustrations/meditating.png',
                          label: 'Meditate',
                          color: Colors.green,
                          onTap: () {
                            Get.to(
                              () => const MeditationView(),
                              transition: Transition.rightToLeft,
                              duration: const Duration(milliseconds: 300),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIllustrationActionCard(
                          assetPath: 'assets/illustrations/Resourses.png',
                          label: 'Resources',
                          color: Colors.orange,
                          onTap: () {
                            Get.to(
                              () => const ResourcesView(),
                              transition: Transition.rightToLeft,
                              duration: const Duration(milliseconds: 300),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIllustrationActionCard(
                          assetPath:
                              'assets/illustrations/SOS illustrations.png',
                          label: 'SOS Help',
                          color: Colors.red,
                          onTap: () {
                            // TODO: Wire to SOS view when available.
                            Get.snackbar(
                              'Coming Soon',
                              'SOS feature will be available soon!',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Focus Areas (if available)
              Obx(() {
                if (authController.userModel != null &&
                    authController.userModel!.moodPreferences.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gradientText(
                        'Your Focus Areas',
                        const LinearGradient(
                          colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                        ),
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: authController.userModel!.moodPreferences
                            .map((pref) => _gradientChip(pref))
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),

              // Daily Tip
              _dailyTipCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Illustration action card with in-card label overlay
  Widget _buildIllustrationActionCard({
    required String assetPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final gradient = _cardGradientFromColor(color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlowContainer(
          glowColor: gradient.last.withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 0.5,
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: _gradientBorderContainer(
            borderRadius: 14,
            gradient: LinearGradient(colors: gradient),
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Soft background in case the image has transparent areas
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            gradient.first.withValues(alpha: 0.15),
                            gradient.last.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Image.asset(
                          assetPath,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),
                    // Bottom gradient scrim for text readability
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Label inside the card
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Shimmer overlay for welcome card: diagonal moving band every 4 seconds
  Widget _welcomeCardShimmerOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Shimmer(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.00),
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.00),
              ],
              stops: const [0.35, 0.50, 0.65],
            ),
            period: const Duration(seconds: 4),
            direction: ShimmerDirection.ltr,
            child: Container(
              // The band is created by the gradient above; base color transparent
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  // ————— Helpers: gradient UI widgets —————
  Widget _gradientText(String text, Gradient gradient, TextStyle style) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }

  Widget _gradientIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: Colors.white, size: 18)),
        ),
      ),
    );
  }

  Widget _gradientBorderContainer({
    required Widget child,
    required LinearGradient gradient,
    double borderRadius = 12,
    EdgeInsetsGeometry? padding,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius - 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  List<Color> _cardGradientFromColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0))
        .toColor();
    final darker = hsl
        .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
        .toColor();
    return [lighter, darker];
  }

  Widget _gradientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E97FD), Color(0xFF00C6FF)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dailyTipCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4D6), Color(0xFFFFF9E7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFFFFB300)),
                SizedBox(width: 8),
                Text(
                  'Daily Tip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5E00),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Take a few minutes today to practice deep breathing. It can help reduce stress and improve focus.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
            ),
          ],
        ),
      ),
    );
  }
}
