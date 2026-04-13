import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_modal_sheet.dart';

Future<bool?> showDestructiveActionSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
  String cancelLabel = 'Cancelar',
  IconData icon = Icons.delete_outline,
}) {
  return showAppModalSheet<bool>(
    context: context,
    builder: (_) => _AppDestructiveActionSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
    ),
  );
}

class _AppDestructiveActionSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;

  const _AppDestructiveActionSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTokens.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Icon(
              icon,
              color: AppTokens.danger,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.ink500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(
                color: AppTokens.warning.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'Esta acción no se puede deshacer.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTokens.ink700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}