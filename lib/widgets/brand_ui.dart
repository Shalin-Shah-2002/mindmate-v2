import 'package:flutter/material.dart';

/// Shared brand UI widgets to align pages with the Home view style
class BrandUI {
  /// Soft background gradient used on Home
  static const LinearGradient softBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF9FBFF), // very light indigo tint
      Color(0xFFF7FFFB), // very light mint tint
    ],
  );

  /// Brand accent gradient (indigo -> cyan) used for text and borders
  static const LinearGradient brandAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
  );
}

/// Full-size background gradient wrapper
class BrandBackground extends StatelessWidget {
  final Widget child;
  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: BrandUI.softBackground),
      child: child,
    );
  }
}

/// Gradient text widget matching Home's brand text style
class BrandGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient? gradient;
  const BrandGradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? BrandUI.brandAccent;
    return ShaderMask(
      shaderCallback: (bounds) =>
          g.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// Border gradient container used for accent outlines
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GradientBorderContainer({
    super.key,
    required this.child,
    required this.gradient,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
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
}
