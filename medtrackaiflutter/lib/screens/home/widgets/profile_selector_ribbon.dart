import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../family/add_family_member_screen.dart';

class ProfileSelectorRibbon extends StatelessWidget {
  const ProfileSelectorRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primaryProfile = state.profile;
    final familyMembers = primaryProfile?.familyMembers ?? [];
    final activeProfile = state.activeProfile;
    final L = context.L;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Family Hub',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: L.sub.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: familyMembers.length + 2, // Primary + Members + Add
            itemBuilder: (context, index) {
              // 1. Primary Profile
              if (index == 0) {
                final isSelected = activeProfile == null;
                return _ProfileAvatar(
                  name: 'Me',
                  isSelected: isSelected,
                  onTap: () => state.switchProfile(null),
                  color: const Color(0xFF6366F1), // Industrial Indigo
                );
              }

              // 2. Family Members
              if (index <= familyMembers.length) {
                final member = familyMembers[index - 1];
                final isSelected = activeProfile?.id == member.id;
                return _ProfileAvatar(
                  name: member.name,
                  avatar: member.avatar,
                  isCritical: member.isCritical,
                  isSelected: isSelected,
                  onTap: () => state.switchProfile(member),
                  color: _getProfileColor(index),
                );
              }

              // 3. Add Button
              return _AddProfileButton(
                onTap: () {
                  HapticEngine.selection();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddFamilyMemberScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getProfileColor(int index) {
    final colors = [
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatar;
  final bool isCritical;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _ProfileAvatar({
    required this.name,
    this.avatar,
    this.isCritical = false,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : L.card,
                    border: Border.all(
                      color: isSelected 
                          ? color.withValues(alpha: 0.3) 
                          : (isCritical ? Colors.red.withValues(alpha: 0.5) : L.border.withValues(alpha: 1.0)),
                      width: isSelected ? 3 : (isCritical ? 1.5 : 1),
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ] : L.shadowSoft,
                  ),
                  child: Center(
                    child: avatar != null && avatar!.isNotEmpty
                        ? Text(
                            avatar!,
                            style: const TextStyle(fontSize: 24),
                          )
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: isSelected ? Colors.white : L.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
                if (isCritical)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: isSelected ? L.text : L.sub.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 64,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.fill.withValues(alpha: 0.5),
                border: Border.all(
                  color: L.border.withValues(alpha: 1.0),
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
              child: Icon(Icons.add_rounded, color: L.sub, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: L.sub.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
