import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../../theme/app_theme.dart';

class CourseCompletionDialog extends StatelessWidget {
  final Medicine med;
  final VoidCallback onArchive;

  const CourseCompletionDialog(
      {super.key, required this.med, required this.onArchive});

  static Future<void> show(
      BuildContext context, Medicine med, VoidCallback onArchive) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CourseCompletionDialog(med: med, onArchive: onArchive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉',
                  style: AppTypography.headlineLarge.copyWith(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Course Completed!',
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w800, color: L.text),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job finishing your course of ${med.name}. You\'ve successfully completed all prescribed doses.',
                textAlign: TextAlign.center,
                style:
                    AppTypography.bodyMedium.copyWith(color: L.sub, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: L.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: L.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration:
                          BoxDecoration(color: L.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Achievement Unlocked',
                              style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800, color: L.green)),
                          Text('100% Adherence for this course',
                              style: AppTypography.labelSmall
                                  .copyWith(color: L.sub.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onArchive();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Text('Archive & Finish',
                          style: AppTypography.labelLarge
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: AppTypography.labelLarge
                        .copyWith(color: L.sub, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
