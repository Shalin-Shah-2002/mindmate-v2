import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isOwnMessage;
  final String senderName;
  final DateTime timestamp;
  final double? safetyScore;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.senderName,
    required this.timestamp,
    this.safetyScore,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOwnMessage
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isOwnMessage
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isOwnMessage
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage)
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (!isOwnMessage) const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: isOwnMessage ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOwnMessage
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (safetyScore != null && safetyScore! < 0.8) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning,
                        size: 12,
                        color: isOwnMessage
                            ? Colors.white.withOpacity(0.7)
                            : Colors.orange.shade600,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
