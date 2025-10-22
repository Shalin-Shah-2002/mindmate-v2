import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable loading animation widget using custom Lottie animation
class LoadingAnimation extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingAnimation({
    super.key,
    this.size = 100,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            'assets/loading.json',
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to CircularProgressIndicator if Lottie fails
              return CircularProgressIndicator(
                color: color ?? Theme.of(context).primaryColor,
                strokeWidth: 3,
              );
            },
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({super.key, this.message, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LoadingAnimation(size: 120, message: message ?? 'Loading...'),
        ),
      ),
    );
  }
}

/// Inline loading widget for lists
class InlineLoading extends StatelessWidget {
  const InlineLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: LoadingAnimation(size: 60)),
    );
  }
}



