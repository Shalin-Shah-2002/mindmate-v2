import 'package:flutter/material.dart';

class MindMateLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final Color? textColor;

  const MindMateLogo({
    super.key,
    this.width,
    this.height,
    this.showText = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Image
        Image.asset(
          'assets/images/logos/mindmate_logo.png',
          width: width ?? 120,
          height: height ?? 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if logo doesn't load
            return Container(
              width: width ?? 120,
              height: height ?? 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.psychology,
                size: (width ?? 120) * 0.6,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),

        // Optional text
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'MindMate',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

// Different logo variants for different use cases
class MindMateLogoSmall extends StatelessWidget {
  const MindMateLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const MindMateLogo(width: 32, height: 32);
  }
}

class MindMateLogoMedium extends StatelessWidget {
  const MindMateLogoMedium({super.key});

  @override
  Widget build(BuildContext context) {
    return const MindMateLogo(width: 80, height: 80);
  }
}

class MindMateLogoLarge extends StatelessWidget {
  final bool showText;

  const MindMateLogoLarge({super.key, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return MindMateLogo(width: 120, height: 120, showText: showText);
  }
}
