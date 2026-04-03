import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RefinedSheetWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? icon;
  final bool scrollable;
  final EdgeInsets? padding;

  const RefinedSheetWrapper({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.scrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    Widget content = Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
              AppSpacing.screenPadding, AppSpacing.l),
      child: child,
    );

    if (scrollable) {
      content = Flexible(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: content,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset : bottomPadding),
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: L.onBg.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: L.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: L.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: L.sub, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Flexible(child: content),
        ],
      ),
    );
  }
}
