import 'package:flutter/material.dart';

class SafetyWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const SafetyWarningBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.close, size: 16, color: Colors.red.shade600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
