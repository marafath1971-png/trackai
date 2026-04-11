import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

class MedCard extends StatelessWidget {
  final Medicine med;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const MedCard({
    super.key,
    required this.med,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final adh =
        context.select<AppState, int>((s) => s.getAdherenceForMed(med.id));
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);

    final displayName = (showGeneric && med.genericName.isNotEmpty)
        ? med.genericName
        : med.name;
    final friendlyName = _toTitleCase(displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncingButton(
        onTap: onView,
        scaleFactor: 0.98,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // ── Leading Icon (Industrial Circle) ──
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _categoryEmoji(med.category),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            friendlyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '12:57pm', // Placeholder time
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: L.text),
                        const SizedBox(width: 4),
                        Text(
                          '${med.dose} dose',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                            child: _BuildMiniStat(
                                icon: Icons.medication_rounded,
                                label: med.form,
                                color: Colors.blue)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _BuildMiniStat(
                            icon: Icons.calendar_today_rounded,
                            label: '$adh%',
                            color: adh >= 100
                                ? const Color(0xFF10B981)
                                : (adh >= 80 ? Colors.orange : L.error),
                          ).animate(
                            target: adh >= 100 ? 1 : 0,
                            onPlay: (c) => c.repeat(reverse: true),
                          ).shimmer(
                            duration: 2.seconds,
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                            child: _BuildMiniStat(
                                icon: Icons.category_rounded,
                                label: med.category,
                                color: Colors.purple)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BuildMiniStat(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: L.sub.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _toTitleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _categoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case 'tablet':
      return '💊';
    case 'capsule':
      return '💊';
    case 'liquid':
      return '💧';
    case 'spray':
      return '💨';
    case 'injection':
      return '💉';
    case 'cream':
      return '🧴';
    case 'drops':
      return '🪷';
    case 'patch':
      return '🩹';
    case 'inhaler':
      return '🌬️';
    default:
      return '💊';
  }
}
