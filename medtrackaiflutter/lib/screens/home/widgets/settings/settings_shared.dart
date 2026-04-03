import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/bouncing_button.dart';
import '../../../../core/utils/haptic_engine.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final Widget child;
  const SettingsSection({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(title!.toUpperCase(),
              style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: L.sub)),
        ),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: L.border.withValues(alpha: 0.3), width: 1.0)),
        child: child,
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class SettingsModalRow extends StatelessWidget {
  final dynamic icon; // String or IconData
  final Color iconBg;
  final String label;
  final String? sub;
  final Widget? right;
  final VoidCallback? onClick;
  final bool border;
  final bool first, last;

  const SettingsModalRow({
    super.key,
    required this.icon,
    this.iconBg = const Color(0xFF111111),
    required this.label,
    this.sub,
    this.right,
    this.onClick,
    this.border = true,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onClick,
      scaleFactor: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.only(
            topLeft: first ? const Radius.circular(30) : Radius.zero,
            topRight: first ? const Radius.circular(30) : Radius.zero,
            bottomLeft: last ? const Radius.circular(30) : Radius.zero,
            bottomRight: last ? const Radius.circular(30) : Radius.zero,
          ),
          border: border
              ? Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.3), width: 1.0))
              : null,
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(16)),
            child: Center(
                child: icon is String
                    ? Text(icon as String,
                        style: AppTypography.titleLarge.copyWith(fontSize: 16))
                    : Icon(icon as IconData, size: 15, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w600, color: L.text),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                if (sub != null)
                  Text(sub!,
                      style: AppTypography.bodySmall.copyWith(color: L.sub)),
              ])),
          if (right != null)
            right!
          else if (onClick != null)
            Icon(Icons.chevron_right_rounded, size: 16, color: L.sub),
        ]),
      ),
    );
  }
}

class SettingsEditField extends StatelessWidget {
  final String label, placeholder;
  final TextEditingController ctrl;
  final AppThemeColors L;
  final TextInputType keyboard;
  final bool border;

  const SettingsEditField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.placeholder,
    required this.L,
    this.keyboard = TextInputType.text,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: L.card,
          border: border
              ? Border(bottom: BorderSide(color: L.border, width: 1.0))
              : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.6, color: L.sub)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: AppTypography.bodyLarge
              .copyWith(fontWeight: FontWeight.w600, color: L.text),
          decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: AppTypography.bodyLarge.copyWith(color: L.sub),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero),
        ),
      ]),
    );
  }
}

class SettingsSelectRow extends StatelessWidget {
  final String label;
  final bool isSel, border;
  final VoidCallback onClick;
  final AppThemeColors L;
  final bool first, last;

  const SettingsSelectRow({
    super.key,
    required this.label,
    required this.isSel,
    required this.onClick,
    required this.L,
    this.border = true,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: () {
        HapticEngine.selection();
        onClick();
      },
      scaleFactor: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: first ? const Radius.circular(30) : Radius.zero,
              topRight: first ? const Radius.circular(30) : Radius.zero,
              bottomLeft: last ? const Radius.circular(30) : Radius.zero,
              bottomRight: last ? const Radius.circular(30) : Radius.zero,
            ),
            border: border
                ? Border(bottom: BorderSide(color: L.border, width: 1.0))
                : null),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(label,
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w600, color: L.text),
                overflow: TextOverflow.ellipsis),
          ),
          if (isSel)
            const Icon(Icons.check_rounded, color: Color(0xFF111111), size: 16),
        ]),
      ),
    );
  }
}

class SettingsStatCard extends StatelessWidget {
  final String label, val, sub, emoji;
  final AppThemeColors L;

  const SettingsStatCard({
    super.key,
    required this.label,
    required this.val,
    required this.sub,
    required this.emoji,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: L.border.withValues(alpha: 0.3), width: 1.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: AppTypography.labelLarge.copyWith(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: L.sub,
                      letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const Spacer(),
          Text(val,
              style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: L.text,
                  letterSpacing: -1)),
          Text(sub,
              style: AppTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.w600, color: L.sub)),
        ],
      ),
    );
  }
}
