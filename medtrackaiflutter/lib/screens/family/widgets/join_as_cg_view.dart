import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_loading_indicator.dart';

class JoinAsCaregiverView extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onBack;
  final Function(Caregiver) onJoined;
  const JoinAsCaregiverView(
      {super.key,
      required this.state,
      required this.L,
      required this.onBack,
      required this.onJoined});

  @override
  State<JoinAsCaregiverView> createState() => _JoinAsCaregiverViewState();
}

class _JoinAsCaregiverViewState extends State<JoinAsCaregiverView> {
  final _codeCtrl = TextEditingController();
  final _scannerCtrl = MobileScannerController();
  bool _isChecking = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkCode(String code) async {
    if (code.length < 6) return;
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      await widget.state.joinCareTeam(code);
      // If we reach here, joinCareTeam succeeded (didn't throw).
      // The FamilyTab will switch views based on state update or we can call onJoined.
      widget.onJoined(Caregiver(
        id: 0,
        name: 'Member',
        relation: 'Family',
        patientUid: '',
        addedAt: '',
      ));
    } catch (e) {
      setState(() => _error = e.toString().contains('Invalid')
          ? "Invalid code"
          : "Connection error");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return Scaffold(
        backgroundColor: L.meshBg,
        body: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              GestureDetector(
                  onTap: widget.onBack,
                  child: Icon(Icons.close_rounded, color: L.text, size: 24)),
              const SizedBox(width: 14),
              Text('Join as Caregiver',
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: L.text)),
            ]),
          ),
          Expanded(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Scan the QR code or enter the invite code to start monitoring.',
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 14, color: L.sub, height: 1.5)),
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: AppShadows.neumorphic,
                                border: Border.all(color: L.green, width: 2.5)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: MobileScanner(
                                controller: _scannerCtrl,
                                onDetect: (capture) {
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue != null) {
                                      final raw = barcode.rawValue!;
                                      // Extract code from URL if needed
                                      final code = raw.contains('code=')
                                          ? raw.split('code=').last
                                          : raw;
                                      if (!_isChecking) _checkCode(code);
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                            child: Text('OR ENTER CODE',
                                style: AppTypography.labelLarge.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: L.sub,
                                    letterSpacing: 1.5))),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppShadows.neumorphic,
                              border: _error != null ? Border.all(color: L.red, width: 1.5) : null),
                          child: TextField(
                            controller: _codeCtrl,
                            style: AppTypography.displayLarge.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: L.text,
                                letterSpacing: 4),
                            textAlign: TextAlign.center,
                            onChanged: (val) {
                              if (val.length == 6) _checkCode(val);
                            },
                            decoration: const InputDecoration(
                                border: InputBorder.none, hintText: '000000'),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Center(
                              child: Text(_error!,
                                  style: AppTypography.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: L.red,
                                      fontWeight: FontWeight.w600))),
                        ],
                        const SizedBox(height: 40),
                        GestureDetector(
                            onTap: () => _checkCode(_codeCtrl.text),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 17),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: _isChecking ? L.greenLight : L.green,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: _isChecking ? null : AppShadows.neumorphic,
                                ),
                                child: _isChecking
                                    ? const AppLoadingIndicator(size: 20)
                                    : Text('Verify and Join',
                                        style: AppTypography.titleLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Colors.black)))),
                        const SizedBox(height: 40),
                      ]))),
        ])));
  }
}
