import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/modals/daily_log_sheet.dart';
import '../../../widgets/common/app_loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuickLogSymptom extends StatelessWidget {
  const QuickLogSymptom({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    final commonSymptoms = [
      {'name': 'Pain', 'emoji': '💆'},
      {'name': 'Energy', 'emoji': '⚡'},
      {'name': 'Mood', 'emoji': '🎭'},
      {'name': 'Sleep', 'emoji': '💤'},
      {'name': 'Nausea', 'emoji': '🤢'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SYMPTOM TRACKING',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w900,
                  )),
              GestureDetector(
                onTap: () {
                  HapticEngine.selection();
                  DailyLogSheet.show(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: L.text.withValues(alpha: 0.05),
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: L.border.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('VIEW ALL',
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 10,
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          )),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: L.text, size: 8),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            scrollDirection: Axis.horizontal,
            itemCount: commonSymptoms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final symptom = commonSymptoms[index];
              return _SymptomButton(
                name: symptom['name'] as String,
                emoji: symptom['emoji'] as String,
                L: L,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SymptomButton extends StatefulWidget {
  final String name;
  final String emoji;
  final AppThemeColors L;

  const _SymptomButton({
    required this.name,
    required this.emoji,
    required this.L,
  });

  @override
  State<_SymptomButton> createState() => _SymptomButtonState();
}

class _SymptomButtonState extends State<_SymptomButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSeverityPicker(context),
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: widget.L.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: widget.L.border.withValues(alpha: 0.08), width: 0.5),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(widget.emoji, 
                style: const TextStyle(fontSize: 24))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds, curve: Curves.easeInOut),
            ),
            const SizedBox(height: 14),
            Text(widget.name.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 10,
                  color: widget.L.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                )),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(0.98, 0.98), duration: 2.seconds, curve: Curves.easeInOut);
  }

  void _showSeverityPicker(BuildContext context) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SeverityBottomSheet(
        name: widget.name,
        emoji: widget.emoji,
        L: widget.L,
      ),
    );
  }
}

class _SeverityBottomSheet extends StatefulWidget {
  final String name;
  final String emoji;
  final AppThemeColors L;

  const _SeverityBottomSheet({
    required this.name,
    required this.emoji,
    required this.L,
  });

  @override
  State<_SeverityBottomSheet> createState() => _SeverityBottomSheetState();
}

class _SeverityBottomSheetState extends State<_SeverityBottomSheet> {
  double _severity = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: ShapeDecoration(
        color: widget.L.bg,
        shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.L.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Text(widget.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('How is your ${widget.name.toLowerCase()}?',
              style: AppTypography.headlineMedium
                  .copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            _severity <= 3
                ? 'Mild / Normal'
                : (_severity <= 7 ? 'Moderate' : 'Severe'),
            style: AppTypography.labelLarge.copyWith(color: widget.L.sub),
          ),
          const SizedBox(height: 48),
          
          // --- Premium Segmented Severity Selector ---
          Column(
            children: [
              SizedBox(
                height: 54,
                child: Row(
                  children: List.generate(10, (index) {
                    final value = index + 1;
                    final isSelected = _severity.round() == value;
                    final isLeading = index == 0;
                    final isTrailing = index == 9;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _severity = value.toDouble());
                          HapticEngine.selection();
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          margin: EdgeInsets.only(
                            right: isTrailing ? 0 : 4,
                            left: isLeading ? 0 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? widget.L.text 
                                : widget.L.card.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: widget.L.border.withValues(alpha: 0.08), width: 0.5),
                          ),
                          child: Center(
                            child: Text(
                              '$value',
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected ? widget.L.bg : widget.L.sub,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MILD', style: AppTypography.labelSmall.copyWith(color: widget.L.sub, fontSize: 9, letterSpacing: 1.0)),
                  Text('MODERATE', style: AppTypography.labelSmall.copyWith(color: widget.L.sub, fontSize: 9, letterSpacing: 1.0)),
                  Text('SEVERE', style: AppTypography.labelSmall.copyWith(color: widget.L.sub, fontSize: 9, letterSpacing: 1.0)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          Consumer<AppState>(builder: (context, state, _) {
            if (state.analyzingSymptom) {
              return Column(
                children: [
                  const AppLoadingIndicator(size: 24),
                  const SizedBox(height: 12),
                  Text('AI analyzing symptom...',
                      style: AppTypography.labelMedium
                          .copyWith(color: widget.L.sub)),
                ],
              );
            }

            if (state.symptomAnalysis != null) {
              final analysis = state.symptomAnalysis!;
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.L.card.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: widget.L.purple.withValues(alpha: 0.2), width: 0.5),
                      boxShadow: AppShadows.neumorphic,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: widget.L.purple, size: 16),
                        const SizedBox(width: 8),
                        Text('AI CLINICAL INSIGHT',
                            style: AppTypography.labelLarge.copyWith(
                                color: widget.L.purple,
                                fontSize: 10,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(analysis.body,
                        style: AppTypography.bodySmall.copyWith(
                            color: widget.L.text,
                            height: 1.5,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    if (analysis.steps.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.steps
                            .map((step) => GestureDetector(
                                  onTap: () =>
                                      state.executeStepAction(step, context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: ShapeDecoration(
                                      color: widget.L.purple.withValues(alpha: 0.1),
                                      shape: ContinuousRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: widget.L.purple.withValues(alpha: 0.2)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt_rounded,
                                            color: widget.L.purple, size: 10),
                                        const SizedBox(width: 4),
                                        Text(step,
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                    color: widget.L.purple,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(analysis.title,
                        style: AppTypography.labelSmall.copyWith(
                            color: widget.L.sub,
                            fontSize: 10,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Got it',
                            style: AppTypography.titleMedium.copyWith(
                                color: widget.L.secondary,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
            }

            return SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  final symptom = Symptom(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: widget.name,
                    severity: _severity.round(),
                    timestamp: DateTime.now(),
                  );
                  context.read<AppState>().logSymptom(symptom);
                  HapticEngine.success();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.L.text,
                  foregroundColor: widget.L.bg,
                  elevation: 0,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Text('LOG ENTRY',
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 14)),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
