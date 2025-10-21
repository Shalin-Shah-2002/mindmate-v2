import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../search/search_results_view.dart';
import '../mood/mood_tracker_view.dart';
import '../meditation/meditation_view.dart';
import '../resources/resources_view.dart';
import '../../services/sos_service.dart';

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
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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

              // Search Bar - Modern Design
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => const SearchResultsView(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6D83F2).withValues(alpha: 0.08),
                        const Color(0xFF00C6FF).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6D83F2).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search users, connect...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '⌘K',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                          onTap: () async {
                            final auth = Get.find<AuthViewModel>();
                            final user = auth.userModel;
                            if (user == null || user.sosContacts.isEmpty) {
                              Get.snackbar(
                                'No SOS Contacts',
                                'Add SOS contacts in profile/settings first.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            final phones = user.sosContacts
                                .map((c) => c.phone)
                                .toList();
                            final sent = await SosService.sendGroupSms(
                              phoneNumbers: phones,
                              userName: user.name,
                            );
                            if (!sent) {
                              Get.snackbar(
                                'Unable to open SMS',
                                'Please check your messaging app permissions.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
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

  // Modern animated action card with glassmorphism and floating effects
  Widget _buildIllustrationActionCard({
    required String assetPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final gradient = _cardGradientFromColor(color);
    return _AnimatedActionCard(
      gradient: gradient,
      label: label,
      assetPath: assetPath,
      onTap: onTap,
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

// Clean, Sharp Animated Action Card with vibrant colors
class _AnimatedActionCard extends StatefulWidget {
  final List<Color> gradient;
  final String label;
  final String assetPath;
  final VoidCallback onTap;

  const _AnimatedActionCard({
    required this.gradient,
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? 0.95 : _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.gradient.first, widget.gradient.last],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.last.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    children: [
                      // Gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.gradient,
                          ),
                        ),
                      ),
                      // Decorative circles in background
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -10,
                        bottom: -10,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // Main content
                      Stack(
                        children: [
                          // Illustration - HUGE and centered
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Image.asset(
                                widget.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 60,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Label with icon - overlay on top
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black38,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Press effect
                      if (_isPressed)
                        Container(color: Colors.black.withValues(alpha: 0.15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
