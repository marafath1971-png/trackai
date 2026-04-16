import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../core/utils/haptic_engine.dart';

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
        onTap: () {
          HapticEngine.selection();
          onView();
        },
        scaleFactor: 0.96,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Row(
            children: [
              // ── Leading Icon (Glowing Container) ──
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (med.isCritical ? L.error : L.primary).withValues(alpha: 0.2), 
                      (med.isCritical ? L.error : L.primary).withValues(alpha: 0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (med.isCritical ? L.error : L.primary).withValues(alpha: 0.5), 
                    width: 1.5
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (med.isCritical ? L.error : L.primary).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2
                    )
                  ]
                ),
                child: MedImage(
                  imageUrl: med.imageUrl,
                  borderRadius: 18,
                  placeholder: Center(
                    child: Icon(
                      Icons.medication_rounded,
                      size: 32,
                      color: (med.isCritical ? L.error : L.primary).withValues(alpha: 0.1),
                    ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack),
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
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.5
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.more_horiz_rounded, color: L.sub.withValues(alpha: 0.5), size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: L.text.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded,
                                  size: 14, color: L.text.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(
                                '${med.dose} dose',
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.text.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ]
                          )
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                            child: _BuildMiniStat(
                                icon: Icons.medication_rounded,
                                label: med.form,
                                color: const Color(0xFF4C9EEB))),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _BuildMiniStat(
                            icon: Icons.calendar_today_rounded,
                            label: '$adh%',
                            color: adh >= 100
                                ? const Color(0xFF10B981)
                                : (adh >= 80 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
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
                                color: const Color(0xFFA855F7))),
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


