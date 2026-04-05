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
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Text(title!.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 10,
                      color: L.sub.withValues(alpha: 0.6))),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: L.border.withValues(alpha: 0.1), thickness: 1)),
            ],
          ),
        ),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: L.border.withValues(alpha: 0.3), width: 1.0)),
        child: child,
      ),
      const SizedBox(height: 28),
    ]);
  }
}

class SettingsModalRow extends StatelessWidget {
  final dynamic icon; // String or IconData
  final Color? iconBg;
  final String label;
  final String? sub;
  final Widget? right;
  final VoidCallback? onClick;
  final bool border;
  final bool first, last;

  const SettingsModalRow({
    super.key,
    required this.icon,
    this.iconBg,
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
    final Color bg = iconBg ?? L.text;
    
    return BouncingButton(
      onTap: onClick,
      scaleFactor: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: first ? const Radius.circular(24) : Radius.zero,
            topRight: first ? const Radius.circular(24) : Radius.zero,
            bottomLeft: last ? const Radius.circular(24) : Radius.zero,
            bottomRight: last ? const Radius.circular(24) : Radius.zero,
          ),
          border: border
              ? Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.2), width: 1.0))
              : null,
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: bg.withValues(alpha: 0.08), 
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bg.withValues(alpha: 0.15), width: 1)),
            child: Center(
                child: icon is String
                    ? Text(icon as String,
                        style: AppTypography.titleLarge.copyWith(fontSize: 16))
                    : Icon(icon as IconData, size: 16, color: bg)),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700, color: L.text, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(sub!,
                        style: AppTypography.bodySmall.copyWith(color: L.sub, fontWeight: FontWeight.w500)),
                  ),
              ])),
          if (right != null)
            right!
          else if (onClick != null)
            Icon(Icons.chevron_right_rounded, size: 18, color: L.sub.withValues(alpha: 0.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          color: L.card,
          border: border
              ? Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.2), width: 1.0))
              : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w900, letterSpacing: 1.2, color: L.sub, fontSize: 9)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: AppTypography.bodyLarge
              .copyWith(fontWeight: FontWeight.w700, color: L.text, fontSize: 16),
          decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: AppTypography.bodyLarge.copyWith(color: L.sub.withValues(alpha: 0.3)),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: first ? const Radius.circular(24) : Radius.zero,
              topRight: first ? const Radius.circular(24) : Radius.zero,
              bottomLeft: last ? const Radius.circular(24) : Radius.zero,
              bottomRight: last ? const Radius.circular(24) : Radius.zero,
            ),
            border: border
                ? Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.2), width: 1.0))
                : null),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(label,
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w700, color: L.text, fontSize: 15),
                overflow: TextOverflow.ellipsis),
          ),
          if (isSel)
            Icon(Icons.check_circle_rounded, color: L.text, size: 20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: L.border.withValues(alpha: 0.3), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: L.text.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: L.sub.withValues(alpha: 0.6),
                      fontSize: 9,
                      letterSpacing: 1.0),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const Spacer(),
          Text(val,
              style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: L.text,
                  letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.w700, color: L.sub.withValues(alpha: 0.5), fontSize: 10)),
        ],
      ),
    );
  }
}
