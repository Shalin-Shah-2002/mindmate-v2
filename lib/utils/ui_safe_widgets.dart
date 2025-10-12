import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// A collection of overflow-safe widgets and utilities to prevent UI rendering errors
class UISafeWidgets {
  UISafeWidgets._();

  /// Creates a safe Column that prevents overflow by using MainAxisSize.min
  /// and adding flexible behavior to children when needed
  static Widget safeColumn({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    List<Widget> children = const <Widget>[],
    bool makeChildrenFlexible = false,
  }) {
    return Column(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: makeChildrenFlexible
          ? children.map((child) => Flexible(child: child)).toList()
          : children,
    );
  }

  /// Creates a safe Row that prevents overflow by using MainAxisSize.min
  /// and adding flexible behavior to children when needed
  static Widget safeRow({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    List<Widget> children = const <Widget>[],
    bool makeChildrenFlexible = false,
  }) {
    return Row(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: makeChildrenFlexible
          ? children.map((child) => Flexible(child: child)).toList()
          : children,
    );
  }

  /// Creates a text widget that is guaranteed to handle overflow gracefully
  static Widget safeText(
    String text, {
    Key? key,
    TextStyle? style,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    bool softWrap = true,
    TextAlign? textAlign,
    TextDirection? textDirection,
    double? textScaleFactor,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
  }) {
    return Text(
      text,
      key: key,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign,
      textDirection: textDirection,
      // textScaleFactor is deprecated; use textScaler instead
      textScaler: textScaleFactor != null
          ? TextScaler.linear(textScaleFactor)
          : null,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  /// Wraps any widget with overflow protection using ClipRect
  static Widget overflowSafe({
    required Widget child,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return ClipRect(clipBehavior: clipBehavior, child: child);
  }

  /// Creates a constrained container that prevents overflow by limiting dimensions
  static Widget constrainedContainer({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    double? maxWidth,
    double? maxHeight,
    double? minWidth = 0.0,
    double? minHeight = 0.0,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Clip clipBehavior = Clip.none,
  }) {
    final effectiveConstraints = BoxConstraints(
      minWidth: minWidth ?? 0.0,
      minHeight: minHeight ?? 0.0,
      maxWidth: maxWidth ?? double.infinity,
      maxHeight: maxHeight ?? double.infinity,
    );

    return Container(
      key: key,
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      constraints: constraints ?? effectiveConstraints,
      child: child,
    );
  }

  /// Creates a ListView that handles empty states and prevents scroll issues
  static Widget safeListView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = true,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    Widget? prototypeItem,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return ListView(
      key: key,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics ?? const ClampingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      prototypeItem: prototypeItem,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      children: children,
    );
  }

  /// Creates a scrollable widget that prevents overflow in constrained spaces
  static Widget scrollableSafe({
    required Widget child,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics ?? const ClampingScrollPhysics(),
      padding: padding,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// Extension methods for making existing widgets overflow-safe
extension OverflowSafeExtensions on Widget {
  /// Wraps the widget with overflow protection
  Widget get overflowSafe => UISafeWidgets.overflowSafe(child: this);

  /// Wraps the widget in a Flexible widget
  Widget get flexible => Flexible(child: this);

  /// Wraps the widget in an Expanded widget
  Widget get expanded => Expanded(child: this);

  /// Makes the widget scrollable when it might overflow
  Widget scrollableWhenNeeded({
    Axis scrollDirection = Axis.vertical,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    return UISafeWidgets.scrollableSafe(
      scrollDirection: scrollDirection,
      physics: physics,
      padding: padding,
      child: this,
    );
  }

  /// Constrains the widget to prevent overflow
  Widget constrained({
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) {
    return UISafeWidgets.constrainedContainer(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      minWidth: minWidth,
      minHeight: minHeight,
      child: this,
    );
  }
}

/// Utility class for responsive design that prevents overflow on different screen sizes
class ResponsiveUtils {
  static double safeWidth(
    BuildContext context, {
    double? maxWidth,
    double percentage = 1.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = screenWidth * percentage;
    return maxWidth != null
        ? calculatedWidth > maxWidth
              ? maxWidth
              : calculatedWidth
        : calculatedWidth;
  }

  static double safeHeight(
    BuildContext context, {
    double? maxHeight,
    double percentage = 1.0,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final calculatedHeight = screenHeight * percentage;
    return maxHeight != null
        ? calculatedHeight > maxHeight
              ? maxHeight
              : calculatedHeight
        : calculatedHeight;
  }

  static EdgeInsets safePadding(
    BuildContext context, {
    double horizontal = 16.0,
    double vertical = 16.0,
  }) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: vertical + mediaQuery.padding.top,
      bottom: vertical + mediaQuery.padding.bottom,
    );
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
}

/// Custom scroll physics that prevents overscroll issues
class SafeScrollPhysics extends ClampingScrollPhysics {
  const SafeScrollPhysics({super.parent});

  @override
  SafeScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SafeScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => super.minFlingVelocity * 2.0;

  @override
  double get maxFlingVelocity => super.maxFlingVelocity * 0.8;
}
