import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../../core/utils/haptic_engine.dart';

class QuickLogSymptom extends StatelessWidget {
  const QuickLogSymptom({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    final commonSymptoms = [
      {'name': 'Pain', 'icon': Icons.local_hospital_rounded},
      {'name': 'Energy', 'icon': Icons.bolt_rounded},
      {'name': 'Mood', 'icon': Icons.sentiment_satisfied_rounded},
      {'name': 'Sleep', 'icon': Icons.bedtime_rounded},
      {'name': 'Nausea', 'icon': Icons.sick_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HOW ARE YOU FEELING?', 
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 11,
                  color: L.sub,
                  letterSpacing: 1.2,
                )),
              Text('DAILY LOG',
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 10,
                  color: L.secondary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w900,
                )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            scrollDirection: Axis.horizontal,
            itemCount: commonSymptoms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final symptom = commonSymptoms[index];
              return _SymptomButton(
                name: symptom['name'] as String,
                icon: symptom['icon'] as IconData,
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
  final IconData icon;
  final AppThemeColors L;

  const _SymptomButton({
    required this.name,
    required this.icon,
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
        width: 85,
        decoration: BoxDecoration(
          color: widget.L.card,
          borderRadius: AppRadius.roundM,
          border: Border.all(color: widget.L.border, width: 1.0),
          boxShadow: widget.L.shadowSoft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.L.fill,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.L.text, size: 20),
            ),
            const SizedBox(height: 12),
            Text(widget.name, 
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                color: widget.L.text,
                fontWeight: FontWeight.w700,
              )),
          ],
        ),
      ),
    );
  }

  void _showSeverityPicker(BuildContext context) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SeverityBottomSheet(
        name: widget.name,
        icon: widget.icon,
        L: widget.L,
      ),
    );
  }
}

class _SeverityBottomSheet extends StatefulWidget {
  final String name;
  final IconData icon;
  final AppThemeColors L;

  const _SeverityBottomSheet({
    required this.name,
    required this.icon,
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
      decoration: BoxDecoration(
        color: widget.L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
          Icon(widget.icon, size: 48, color: widget.L.secondary),
          const SizedBox(height: 16),
          Text('How is your ${widget.name.toLowerCase()}?', 
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            _severity <= 3 ? 'Mild / Normal' : (_severity <= 7 ? 'Moderate' : 'Severe'),
            style: AppTypography.labelLarge.copyWith(color: widget.L.sub),
          ),
          const SizedBox(height: 40),
          Slider(
            value: _severity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: widget.L.secondary,
            inactiveColor: widget.L.fill,
            onChanged: (v) {
              setState(() => _severity = v);
              HapticEngine.light();
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(color: widget.L.sub)),
              Text('10', style: TextStyle(color: widget.L.sub)),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final symptom = Symptom(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: widget.name,
                  severity: _severity.round(),
                  timestamp: DateTime.now(),
                );
                context.read<AppState>().logSymptom(symptom);
                Navigator.pop(context);
                HapticEngine.success();
                context.read<AppState>().showToast('Logged ${widget.name}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.L.text,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundL),
              ),
              child: const Text('Log Entry', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
