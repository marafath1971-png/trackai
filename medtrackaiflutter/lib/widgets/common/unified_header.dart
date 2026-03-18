import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

class UnifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String? title;
  final Widget? titleWidget; // Added for flexible title styling
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? bottomHeight;
  final Color? backgroundColor;
  final bool showBrand;
  final bool isScrolled;
  final bool blurred;
  final bool showBorder;
  final VoidCallback? onTap;

  const UnifiedHeader({
    super.key,
    this.leading,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.bottom,
    this.bottomHeight,
    this.blurred = true,
    this.showBorder = true,
    this.backgroundColor,
    this.showBrand = false,
    this.isScrolled = false,
    this.onTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      122 + (bottomHeight ?? (bottom != null ? 60 : 0)));

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bg = backgroundColor ?? L.bg;
    Widget child = Container(
      decoration: BoxDecoration(
        color: blurred ? bg.withValues(alpha: isScrolled ? 0.9 : 0.8) : bg,
        border: showBorder 
          ? Border(
              bottom: BorderSide(
                color: isScrolled ? L.border : Colors.transparent,
                width: 1.0,
              ),
            )
          : null,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, 8),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showBrand) ...[
                          _buildBrandRow(L)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                          const SizedBox(height: 8),
                          if (title != null || titleWidget != null) 
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: titleWidget ?? Text(
                                title!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: L.text.withValues(alpha: 0.6),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                        ] else ...[
                          if (titleWidget != null || title != null)
                            Row(
                              children: [
                                titleWidget ?? Text(
                                  title!,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: L.text,
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
                        ],
                        if (subtitle != null)
                          Padding(
                            padding: EdgeInsets.only(left: showBrand ? 2 : 0),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: L.sub,
                                height: 1.2,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: a,
                              ))
                          .toList(),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: 0.05),
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    ),
  );

    if (blurred) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      );
    }
    return child;
  }

  Widget _buildBrandRow(AppThemeColors L) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/home_logo.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Text(
          'Med AI',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: L.text,
            letterSpacing: -0.8,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class HeaderActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const HeaderActionBtn({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class SliverUnifiedHeader extends StatelessWidget {
  final String title;
  final Widget? background;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final double expandedHeight;

  const SliverUnifiedHeader({
    super.key,
    required this.title,
    this.background,
    this.actions,
    this.onBack,
    this.expandedHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: L.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? Center(
              child: HeaderActionBtn(
                onTap: onBack!,
                backgroundColor: L.bg.withValues(alpha: 0.6),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            )
          : null,
      actions: [
        if (actions != null) ...[
          ...actions!,
          const SizedBox(width: 12),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: L.text,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: background,
      ),
    );
  }
}
