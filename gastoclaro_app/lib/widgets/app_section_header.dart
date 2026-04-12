import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    );

    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTokens.ink500,
      height: 1.35,
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: subtitleStyle),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = action != null && constraints.maxWidth < 680;

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textBlock,
              const SizedBox(height: 12),
              action!,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textBlock),
            if (action != null) ...[
              const SizedBox(width: 12),
              action!,
            ],
          ],
        );
      },
    );
  }
}