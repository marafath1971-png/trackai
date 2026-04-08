import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_theme.dart';
import '../shared/shared_widgets.dart';

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
  final bool showProBadge; // New: optional PRO badge next to title
  final bool showBack; // New: show back button
  final VoidCallback? onBack; // New: back button press
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
    this.showProBadge = false,
    this.showBack = false,
    this.onBack,
    this.onTap,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(80 + (bottomHeight ?? (bottom != null ? 60 : 0)));

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final topPad = MediaQuery.of(context).padding.top;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: 250.ms,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
          decoration: BoxDecoration(
            color: (backgroundColor ?? L.meshBg).withValues(alpha: isScrolled || blurred ? 0.8 : 0.0),
            border: Border(
              bottom: BorderSide(
                color: (isScrolled || blurred) ? L.border.withValues(alpha: 0.08) : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBack) ...[
                  BouncingButton(
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 20),
                  ),
                  const SizedBox(width: 20),
                ] else if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 20),
                ],
                
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBrand) ...[
                        _buildBrandRow(L),
                      ] else ...[
                        if (subtitle != null)
                          Text(
                            subtitle!.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.4),
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        if (title != null || titleWidget != null)
                          titleWidget ?? Text(
                            title!,
                            style: AppTypography.headlineMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              height: 1.1,
                              letterSpacing: -1.0,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                if (actions != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!.map((a) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: a,
                    )).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
          'MedAI',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: L.text,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        if (showProBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: L.text.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Text(
              'PRO',
              style: AppTypography.labelSmall.copyWith(
                color: L.bg,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
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
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.neumorphic,
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
      backgroundColor: L.meshBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? Center(
              child: HeaderActionBtn(
                onTap: onBack!,
                backgroundColor: L.meshBg.withValues(alpha: 0.6),
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
        ],
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
        title: Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
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
