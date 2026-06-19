import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class StatusCornerCard extends StatelessWidget {
  const StatusCornerCard({
    required this.title,
    required this.message,
    this.progress,
    this.icon,
    this.bottom = 18,
    this.right = 18,
    this.onClose,
    super.key,
  });

  final String title;
  final String message;
  final double? progress;
  final Widget? icon;
  final double bottom;
  final double right;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Positioned(
      right: right,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  icon ??
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (onClose != null)
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
