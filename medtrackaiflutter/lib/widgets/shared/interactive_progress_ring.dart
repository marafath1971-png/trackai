import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InteractiveProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;
  final Widget? child;
  final String? label;
  final String? valueText;
  final VoidCallback? onTap;

  const InteractiveProgressRing({
    super.key,
    required this.progress,
    this.size = 140,
    this.color,
    this.child,
    this.label,
    this.valueText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: L.border.withValues(alpha: 0.05), width: 1.5),
          boxShadow: L.shadowSoft,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: L.border.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color ?? L.secondary),
                    strokeCap: StrokeCap.round,
                  ),
                  if (child != null) child!,
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(label!,
                        style: AppTypography.labelLarge.copyWith(
                            color: L.sub, letterSpacing: 1.2, fontSize: 11)),
                  if (valueText != null) ...[
                    const SizedBox(height: 4),
                    Text(valueText!,
                        style: AppTypography.titleLarge.copyWith(
                            color: L.text, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: L.sub, size: 24),
          ],
        ),
      ),
    );
  }
}
