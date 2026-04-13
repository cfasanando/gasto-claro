import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_status_chip.dart';
import 'app_surface_card.dart';

class AppEntityCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final String? trailing;
  final AppStatusChip? statusChip;
  final List<Widget> metadata;
  final List<Widget> actions;
  final VoidCallback? onTap;

  const AppEntityCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
    this.statusChip,
    this.metadata = const [],
    this.actions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    );

    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppTokens.ink500,
    );

    final trailingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: AppTokens.ink900,
      letterSpacing: -0.3,
    );

    final eyebrowStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
    );

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingBadge(
                icon: icon,
                color: accentColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(eyebrow!, style: eyebrowStyle),
                      const SizedBox(height: 6),
                    ],
                    Text(title, style: titleStyle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!, style: subtitleStyle),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Text(
                  trailing!,
                  style: trailingStyle,
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
          if (metadata.isNotEmpty || statusChip != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...metadata,
                if (statusChip != null) statusChip!,
              ],
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class AppEntityMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const AppEntityMeta({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: AppTokens.ink500,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTokens.ink700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LeadingBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}