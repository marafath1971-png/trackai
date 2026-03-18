import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.emoji = '📝',
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Emoji Container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: L.fill,
              shape: BoxShape.circle,
              border: Border.all(color: L.border, width: 1.0),
            ),
            child: Center(
              child: icon != null 
                ? Icon(icon, size: 40, color: L.sub)
                : Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: -8, duration: 2000.ms, curve: Curves.easeInOut)
           .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms),
          
          const SizedBox(height: AppSpacing.xl),
          
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: L.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: AppSpacing.s),
          
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: L.sub,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
          
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.m),
                decoration: BoxDecoration(
                  color: L.primary,
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  boxShadow: [
                    BoxShadow(
                      color: L.text.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: L.onPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ],
      ),
    );
  }
}
