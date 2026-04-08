import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../models/constants.dart';
import '../../../core/utils/haptic_engine.dart';

class CompleteProfileCard extends StatelessWidget {
  const CompleteProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    // Define tasks and check completion
    final List<_ProfileTask> tasks = [
      _ProfileTask(
        id: 'age',
        title: 'Add your age',
        subtitle: 'For better health insights',
        icon: Icons.cake_rounded,
        isDone: profile.age.isNotEmpty,
        onTap: () => _showAgePicker(context, state),
      ),
      _ProfileTask(
        id: 'gender',
        title: 'Set your gender',
        subtitle: 'Personalises your guidance',
        icon: Icons.person_outline_rounded,
        isDone: profile.gender.isNotEmpty,
        onTap: () => _showSinglePicker(
            context, state, 'gender', 'Select Gender', kGenders),
      ),
      _ProfileTask(
        id: 'forgetting',
        title: 'When do you forget?',
        subtitle: 'Optimises your reminders',
        icon: Icons.psychology_rounded,
        isDone: profile.forgetting.isNotEmpty,
        onTap: () => _showSinglePicker(
            context, state, 'forgetting', 'Forget Pattern', kForgetPatterns),
      ),
      _ProfileTask(
        id: 'doctor',
        title: 'Doctor visits',
        subtitle: 'Track your medical frequency',
        icon: Icons.medical_services_outlined,
        isDone: profile.doctorVisits.isNotEmpty,
        onTap: () => _showSinglePicker(
            context, state, 'doctorVisits', 'Doctor Visits', kDoctorVisits),
      ),
      _ProfileTask(
        id: 'motivation',
        title: 'What motivates you?',
        subtitle: profile.motivation.isEmpty
            ? 'Personalised encouragement'
            : profile.motivation.join(', '),
        icon: Icons.wb_sunny_outlined,
        isDone: profile.motivation.isNotEmpty,
        onTap: () => _showMultiPicker(
            context, state, 'motivation', 'Select Motivation', kMotivation),
      ),
    ];

    final doneCount = tasks.where((t) => t.isDone).length;
    if (doneCount == tasks.length) return const SizedBox.shrink();

    final progress = doneCount / tasks.length;
    final L = context.L;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.neumorphic,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: AppTypography.titleLarge.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unlock more personalised insights',
                        style: AppTypography.bodySmall.copyWith(color: L.sub),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: L.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTypography.labelLarge.copyWith(
                        color: L.secondary, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: L.border,
            color: L.secondary,
            minHeight: 3,
          ),
          const SizedBox(height: 8),
          ...tasks
              .where((t) => !t.isDone)
              .take(2)
              .map((task) => _TaskItem(task: task, L: L)),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  void _showAgePicker(BuildContext context, AppState state) {
    final L = context.L;
    final controller = TextEditingController(text: state.profile?.age ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(c).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        decoration: BoxDecoration(
          color: context.L.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How old are you?', style: AppTypography.headlineMedium),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 35',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  state.saveProfile(
                      state.profile!.copyWith(age: controller.text));
                  Navigator.pop(c);
                  HapticEngine.success();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: L.secondary,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSinglePicker(BuildContext context, AppState state, String field,
      String title, List<Map<String, String>> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.L.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTypography.headlineMedium),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
                  leading: Text(opt['e']!,
                      style: AppTypography.displayLarge.copyWith(fontSize: 24)),
                  title: Text(opt['v']!),
                  onTap: () {
                    final Map<String, dynamic> updates = {field: opt['v']};
                    state.updateProfileFromMap(updates);
                    Navigator.pop(c);
                    HapticEngine.selection();
                  },
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showMultiPicker(BuildContext context, AppState state, String field,
      String title, List<Map<String, String>> options) {
    final L = context.L;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) {
          final profile = state.profile;
          final selected = List<String>.from(profile?.motivation ?? []);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: L.bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTypography.headlineMedium),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final val = opt['v']!;
                  final isSel = selected.contains(val);
                  return CheckboxListTile(
                    secondary: Text(opt['e']!,
                        style:
                            AppTypography.displayLarge.copyWith(fontSize: 24)),
                    title: Text(val),
                    value: isSel,
                    activeColor: L.secondary,
                    onChanged: (checked) {
                      setModalState(() {
                        if (checked == true) {
                          if (!selected.contains(val)) selected.add(val);
                        } else {
                          selected.remove(val);
                        }
                      });
                      HapticEngine.selection();
                    },
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      state.updateProfileFromMap({field: selected});
                      Navigator.pop(c);
                      HapticEngine.success();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: L.secondary,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Selection'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTask {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final VoidCallback onTap;

  _ProfileTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.onTap,
  });
}

class _TaskItem extends StatelessWidget {
  final _ProfileTask task;
  final AppThemeColors L;
  const _TaskItem({required this.task, required this.L});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: task.onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: L.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(task.icon, color: L.secondary, size: 20),
      ),
      title: Text(task.title, style: AppTypography.labelLarge),
      subtitle: Text(task.subtitle,
          style: AppTypography.bodySmall.copyWith(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
