import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global overflow error handler and debugger utilities
class OverflowHandler {
  static bool _debugOverflowEnabled = true;
  static List<String> _overflowLog = [];

  /// Initialize the overflow handler with global settings
  static void initialize({bool debugOverflowEnabled = true}) {
    _debugOverflowEnabled = debugOverflowEnabled;

    // Set up global error handling for rendering overflows
    if (kDebugMode && _debugOverflowEnabled) {
      FlutterError.onError = (FlutterErrorDetails details) {
        // Log overflow errors for debugging
        if (details.exception.toString().contains('overflowed') ||
            details.exception.toString().contains('RenderFlex')) {
          _logOverflowError(details);
        }

        // Call the default error handler
        FlutterError.presentError(details);
      };
    }
  }

  /// Log overflow errors for debugging purposes
  static void _logOverflowError(FlutterErrorDetails details) {
    final errorMessage = details.exception.toString();
    final timestamp = DateTime.now().toIso8601String();

    _overflowLog.add('[$timestamp] OVERFLOW ERROR: $errorMessage');

    if (kDebugMode) {
      debugPrint('🚨 OVERFLOW DETECTED: $errorMessage');
      debugPrint('Stack trace: ${details.stack}');
    }
  }

  /// Get all logged overflow errors
  static List<String> getOverflowLog() => List.from(_overflowLog);

  /// Clear the overflow log
  static void clearOverflowLog() => _overflowLog.clear();

  /// Check if debug overflow is enabled
  static bool get isDebugOverflowEnabled => _debugOverflowEnabled;

  /// Create a widget that catches and handles overflow errors
  static Widget catchOverflow({
    required Widget child,
    Widget? fallbackWidget,
    Function(FlutterErrorDetails)? onOverflow,
  }) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          if (e.toString().contains('overflow') ||
              e.toString().contains('RenderFlex')) {
            if (onOverflow != null) {
              onOverflow(FlutterErrorDetails(exception: e));
            }

            return fallbackWidget ??
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                );
          }
          rethrow;
        }
      },
    );
  }

  /// Wrap any widget with automatic overflow protection
  static Widget wrapWithProtection({
    required Widget child,
    bool enableClipping = true,
    bool enableScrolling = false,
    Axis scrollDirection = Axis.vertical,
  }) {
    Widget protectedChild = child;

    // Add clipping protection
    if (enableClipping) {
      protectedChild = ClipRect(
        clipBehavior: Clip.hardEdge,
        child: protectedChild,
      );
    }

    // Add scrolling if requested
    if (enableScrolling) {
      protectedChild = SingleChildScrollView(
        scrollDirection: scrollDirection,
        physics: const ClampingScrollPhysics(),
        child: protectedChild,
      );
    }

    return protectedChild;
  }
}

/// Error boundary widget that catches overflow and other rendering errors
class OverflowErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final Function(FlutterErrorDetails)? onError;

  const OverflowErrorBoundary({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.onError,
  });

  @override
  State<OverflowErrorBoundary> createState() => _OverflowErrorBoundaryState();
}

class _OverflowErrorBoundaryState extends State<OverflowErrorBoundary> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallbackWidget ?? _buildDefaultErrorWidget();
    }

    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (e, stackTrace) {
          _handleError(
            FlutterErrorDetails(
              exception: e,
              stack: stackTrace,
              context: ErrorDescription('OverflowErrorBoundary'),
            ),
          );

          return widget.fallbackWidget ?? _buildDefaultErrorWidget();
        }
      },
    );
  }

  void _handleError(FlutterErrorDetails details) {
    setState(() {
      _hasError = true;
      _errorDetails = details;
    });

    widget.onError?.call(details);

    if (kDebugMode) {
      debugPrint('Error caught by OverflowErrorBoundary: ${details.exception}');
    }
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          const Text(
            'UI Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kDebugMode
                ? _errorDetails?.exception.toString() ?? 'Unknown error'
                : 'Something went wrong',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Mixin for widgets that want to be overflow-safe by default
mixin OverflowSafeMixin<T extends StatefulWidget> on State<T> {
  Widget wrapWithOverflowProtection(Widget child) {
    return OverflowHandler.wrapWithProtection(
      child: child,
      enableClipping: true,
    );
  }

  Widget buildSafeColumn({
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required List<Widget> children,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }

  Widget buildSafeRow({
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required List<Widget> children,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Global configuration for overflow handling
abstract class OverflowConfig {
  static const bool enableDebugLogging = true;
  static const bool enableGlobalErrorHandling = true;
  static const bool enableClippingByDefault = true;
  static const double defaultMaxWidth = 400.0;
  static const double defaultMaxHeight = 600.0;
  static const EdgeInsets defaultSafePadding = EdgeInsets.all(16.0);
  static const Clip defaultClipBehavior = Clip.hardEdge;
}
