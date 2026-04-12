import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BorderSide? border;
  final double radius;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceLg),
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.border,
    this.radius = AppTokens.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBorder = border ??
        BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.9,
        );

    final decoration = BoxDecoration(
      color: gradient == null
          ? (backgroundColor ?? Theme.of(context).colorScheme.surface)
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.fromBorderSide(resolvedBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );

    final content = Padding(
      padding: padding,
      child: child,
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}