import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/constants.dart';
import '../../../theme/app_theme.dart';

class AddHeader extends StatelessWidget {
  final int step;
  final AppThemeColors L;
  final VoidCallback onBack;
  const AddHeader(
      {super.key, required this.step, required this.L, required this.onBack});
  @override
  Widget build(BuildContext context) {
    final title = step == 1
        ? "Add Caregiver"
        : step == 2
            ? "Share QR Code"
            : "Caregiver Active!";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
            onTap: onBack,
            child: SizedBox(
                width: 24,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: L.text, size: 18))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w700, color: L.text)),
          Text('Step $step of 3',
              style: AppTypography.labelLarge
                  .copyWith(fontSize: 12, color: L.sub)),
        ]),
      ]),
      const SizedBox(height: 24),
      Row(
          children: [1, 2, 3]
              .map((n) => Expanded(
                  child: Container(
                      margin: EdgeInsets.only(right: n == 3 ? 0 : 8),
                      height: 5,
                      decoration: BoxDecoration(
                          color: step >= n
                              ? L.text
                              : L.fill.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)))))
              .toList()),
      const SizedBox(height: 32),
    ]);
  }
}

class AddCgStep1 extends StatelessWidget {
  final TextEditingController nameCtrl, contactCtrl;
  final String relation, avatar;
  final int alertDelay;
  final ValueChanged<String> onRelChange, onAvatarChange;
  final ValueChanged<int> onDelayChange;
  final AppThemeColors L;
  final VoidCallback onBack;
  final Future<void> Function() onNext;
  const AddCgStep1(
      {super.key,
      required this.nameCtrl,
      required this.contactCtrl,
      required this.relation,
      required this.avatar,
      required this.alertDelay,
      required this.onRelChange,
      required this.onAvatarChange,
      required this.onDelayChange,
      required this.L,
      required this.onBack,
      required this.onNext});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: L.meshBg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(step: 1, L: L, onBack: onBack),

                      // Avatar
                      Text('CHOOSE AVATAR',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: kCgAvatars
                              .map((a) => GestureDetector(
                                    onTap: () => onAvatarChange(a),
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: avatar == a
                                              ? L.text
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: avatar == a
                                              ? null
                                              : AppShadows.neumorphic,
                                        ),
                                        child: Center(
                                            child: Text(a,
                                                style: AppTypography
                                                    .headlineLarge
                                                    .copyWith(
                                                        fontSize: 22,
                                                        color: avatar == a
                                                            ? L.bg
                                                            : null)))),
                                  ))
                              .toList()),
                      const SizedBox(height: 20),

                      // Name
                      Text('FULL NAME *',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppShadows.neumorphic,
                            border: nameCtrl.text.isNotEmpty
                                ? Border.all(color: L.text, width: 1.5)
                                : null),
                        child: TextField(
                            controller: nameCtrl,
                            style: AppTypography.bodySmall
                                .copyWith(fontSize: 15, color: L.text),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'e.g. Sarah Johnson',
                                hintStyle: AppTypography.bodySmall.copyWith(
                                    color: L.sub.withValues(alpha: 0.5)))),
                      ),

                      // Relationship
                      Text('RELATIONSHIP',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          children: [
                            'Spouse',
                            'Parent',
                            'Son',
                            'Daughter',
                            'Sibling',
                            'Friend',
                            'Doctor',
                            'Caregiver'
                          ]
                              .map((r) => GestureDetector(
                                    onTap: () => onRelChange(r),
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 13, vertical: 7),
                                        decoration: BoxDecoration(
                                            color: relation == r
                                                ? L.text
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            boxShadow: relation == r
                                                ? null
                                                : AppShadows.neumorphic,
                                            border: relation == r
                                                ? Border.all(color: L.text)
                                                : null),
                                        child: Text(r,
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: relation == r
                                                        ? L.bg
                                                        : L.sub))),
                                  ))
                              .toList()),
                      const SizedBox(height: 16),

                      // Phone
                      Text('PHONE (OPTIONAL — FOR SMS BACKUP)',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppShadows.neumorphic,
                            border: contactCtrl.text.isNotEmpty
                                ? Border.all(color: L.text, width: 1.5)
                                : null),
                        child: TextField(
                            controller: contactCtrl,
                            style: AppTypography.bodySmall
                                .copyWith(fontSize: 15, color: L.text),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '+880 1XXX-XXXXXX',
                                hintStyle: AppTypography.bodySmall.copyWith(
                                    color: L.sub.withValues(alpha: 0.5)))),
                      ),

                      // Alert Delay
                      Text('ALERT AFTER MISSED DOSE BY',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 8),
                      Row(children: [
                        DelayBtn(
                            delay: 0,
                            label: 'Now',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                        const SizedBox(width: 6),
                        DelayBtn(
                            delay: 15,
                            label: '15 min',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                        const SizedBox(width: 6),
                        DelayBtn(
                            delay: 30,
                            label: '30 min',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                        const SizedBox(width: 6),
                        DelayBtn(
                            delay: 60,
                            label: '1 hour',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                      ]),
                      const SizedBox(height: 28),

                      GestureDetector(
                          onTap: nameCtrl.text.trim().isEmpty ? null : onNext,
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: nameCtrl.text.trim().isEmpty
                                    ? L.fill.withValues(alpha: 0.1)
                                    : L.text,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: nameCtrl.text.trim().isEmpty
                                    ? null
                                    : AppShadows.neumorphic,
                              ),
                              child: Text('GENERATE QR CODE →',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: nameCtrl.text.trim().isEmpty
                                          ? L.sub.withValues(alpha: 0.4)
                                          : L.bg)))),
                    ]))),
      );
}

class DelayBtn extends StatelessWidget {
  final int delay, current;
  final String label;
  final ValueChanged<int> onTap;
  final AppThemeColors L;
  const DelayBtn(
      {super.key,
      required this.delay,
      required this.current,
      required this.label,
      required this.onTap,
      required this.L});
  @override
  Widget build(BuildContext context) => Expanded(
      child: GestureDetector(
          onTap: () => onTap(delay),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: current == delay ? L.text : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: current == delay ? null : AppShadows.neumorphic,
            ),
            child: Text(label,
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: current == delay
                        ? L.bg
                        : L.sub.withValues(alpha: 0.6))),
          )));
}

class AddCgStep2 extends StatefulWidget {
  final Caregiver cg;
  final String inviteCode;
  final AppThemeColors L;
  final VoidCallback onNext;
  const AddCgStep2(
      {super.key,
      required this.cg,
      required this.inviteCode,
      required this.L,
      required this.onNext});

  @override
  State<AddCgStep2> createState() => _AddCgStep2State();
}

class _AddCgStep2State extends State<AddCgStep2> {
  String _scanState = 'idle';

  @override
  void initState() {
    super.initState();
    // Start listening to AppState for status changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  void _checkStatus() {
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);

    // Check if the caregiver is already active
    final currentCg = state.caregivers.firstWhere(
      (c) => c.inviteCode == widget.inviteCode || c.id == widget.cg.id,
      orElse: () => widget.cg,
    );

    if (currentCg.status == 'active' && _scanState == 'idle') {
      _handleActivation();
    } else {
      // Re-check on next frame/notification if not active
      state.addListener(_onStateChange);
    }
  }

  void _onStateChange() {
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    final currentCg = state.caregivers.firstWhere(
      (c) => c.inviteCode == widget.inviteCode || c.id == widget.cg.id,
      orElse: () => widget.cg,
    );

    if (currentCg.status == 'active' && _scanState == 'idle') {
      state.removeListener(_onStateChange);
      _handleActivation();
    }
  }

  void _handleActivation() async {
    setState(() => _scanState = 'done');
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.onNext();
  }

  @override
  void dispose() {
    // Ensure listener is removed
    Provider.of<AppState>(context, listen: false)
        .removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;

    return Scaffold(
        backgroundColor: L.meshBg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(
                          step: 2, L: L, onBack: () => Navigator.pop(context)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.neumorphic,
                        ),
                        child: Row(children: [
                          Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: L.greenLight,
                                  borderRadius: BorderRadius.circular(24)),
                              child: Center(
                                  child: Text(cg.avatar,
                                      style: AppTypography.headlineLarge
                                          .copyWith(fontSize: 26)))),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(cg.name,
                                    style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                                Text(
                                    '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                    style: AppTypography.labelSmall
                                        .copyWith(color: L.sub)),
                              ])),
                        ]),
                      ),
                      Text(
                          'Share the QR or invite code with ${cg.name}. The app will automatically update once they join.',
                          style: AppTypography.bodySmall.copyWith(
                              fontSize: 14, color: L.sub, height: 1.5)),
                      const SizedBox(height: 24),
                      Center(
                          child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            ...AppShadows.neumorphic,
                            BoxShadow(
                                color: L.green.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: -10,
                                offset: const Offset(0, 15)),
                          ],
                        ),
                        child: QrImageView(
                          data: widget
                              .inviteCode, // Just the code for easy parity
                          size: 210,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: Color(0xFF111111)),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Color(0xFF111111)),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(
                              duration: 2.seconds,
                              color: L.green.withValues(alpha: 0.1))),
                      const SizedBox(height: 28),
                      Center(
                          child: Text('OR USE INVITE CODE',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: L.sub,
                                  letterSpacing: 1.5))),
                      const SizedBox(height: 8),
                      Center(
                          child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.neumorphic,
                        ),
                        child: Text(cg.inviteCode ?? '------',
                            style: AppTypography.displayLarge.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: L.text,
                                letterSpacing: 6)),
                      )),
                      const SizedBox(height: 16),
                      Center(
                          child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: widget.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied! ✓')));
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppShadows.neumorphic,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded,
                                    color: L.text, size: 14),
                                const SizedBox(width: 8),
                                Text('Copy Code',
                                    style: AppTypography.labelLarge.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: L.text,
                                        letterSpacing: 0.5)),
                              ],
                            )),
                      )),
                      const SizedBox(height: 48),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.neumorphic,
                        ),
                        child: Column(
                          children: [
                            if (_scanState == 'idle') ...[
                              SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: L.green)),
                              const SizedBox(height: 12),
                              Text('Waiting for caregiver to join...',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: L.sub)),
                            ] else ...[
                              Icon(Icons.check_circle_rounded,
                                  color: L.green, size: 32),
                              const SizedBox(height: 8),
                              Text('Success! Caregiver added.',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: L.text)),
                            ]
                          ],
                        ),
                      ),
                    ]))));
  }
}

class HowItWorksRow extends StatelessWidget {
  final String emoji, title, desc;
  final bool isLast;
  final AppThemeColors L;
  const HowItWorksRow(
      {super.key,
      required this.emoji,
      required this.title,
      required this.desc,
      required this.isLast,
      required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.1), width: 1))),
      child: Row(children: [
        SizedBox(
            width: 24,
            child: Text(emoji,
                style: AppTypography.bodyMedium.copyWith(fontSize: 18))),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w700, color: L.text)),
          Text(desc,
              style:
                  AppTypography.bodySmall.copyWith(fontSize: 12, color: L.sub)),
        ]))
      ]),
    );
  }
}

class AddCgStep3 extends StatelessWidget {
  final Caregiver cg;
  final AppThemeColors L;
  final VoidCallback onDone;
  const AddCgStep3(
      {super.key, required this.cg, required this.L, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: L.meshBg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddHeader(step: 3, L: L, onBack: onDone),
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.neumorphic,
                        ),
                        child: Row(children: [
                          Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: L.greenLight,
                                  borderRadius: BorderRadius.circular(24)),
                              child: Center(
                                  child: Text(cg.avatar,
                                      style: AppTypography.headlineLarge
                                          .copyWith(fontSize: 28)))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(cg.name,
                                    style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                                Text(
                                    '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                    style: AppTypography.labelSmall
                                        .copyWith(color: L.sub)),
                              ])),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: L.text.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(99)),
                            child: Text('● Active',
                                style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: L.text,
                                    letterSpacing: 0.5)),
                          ),
                        ]),
                      ),
                      Text('THEY CAN NOW:',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: L.sub)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.neumorphic,
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HowItWorksRow(
                                  emoji: '📊',
                                  title: 'See your daily adherence',
                                  desc: 'Live dashboard with today\'s doses',
                                  isLast: false,
                                  L: L),
                              HowItWorksRow(
                                  emoji: '⚠️',
                                  title: 'Get missed-dose alerts',
                                  desc:
                                      'Notified after ${cg.alertDelay} min if you miss a dose',
                                  isLast: false,
                                  L: L),
                              HowItWorksRow(
                                  emoji: '📋',
                                  title: 'View your medicine list',
                                  desc: 'All your medications at a glance',
                                  isLast: true,
                                  L: L),
                            ]),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                          onTap: onDone,
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: L.text,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: AppShadows.neumorphic,
                              ),
                              child: Text('Done',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: L.bg,
                                      letterSpacing: 1.0)))),
                    ]))));
  }
}
