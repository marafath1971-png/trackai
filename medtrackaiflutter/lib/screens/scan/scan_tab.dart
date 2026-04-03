import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../widgets/smoothing_text.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/scan_result.dart';
import '../../theme/app_theme.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../core/utils/date_formatter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../services/share_service.dart';
import '../../services/review_service.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../widgets/common/paywall_sheet.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../core/utils/result.dart';
import '../../widgets/common/bouncing_button.dart';

class ScanTab extends StatefulWidget {
  final void Function(Medicine)? onSave;
  final VoidCallback? onClose;
  final VoidCallback? onManualAdd;
  final VoidCallback? onScanAdded;

  const ScanTab({
    super.key,
    this.onSave,
    this.onClose,
    this.onManualAdd,
    this.onScanAdded,
  });

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _cameraError = false; // NEW: Track hardware/permission errors
  bool _isScanning = false;
  File? _imageFile;
  String _selectedCategory = 'Tablet';
  int _scanStep = 0; // For multi-step animation

  late AnimationController _scanLineController;
  late AnimationController _pulseController;

  final List<String> _scanSteps = [
    'Identifying medicine...',
    'Extracting dose info...',
    'Checking interactions...',
    'Finalising results...',
  ];
  final List<String> _scanStepIcons = ['🔍', '💊', '⚡', '✅'];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tablet', 'icon': Icons.medication_rounded},
    {'name': 'Liquid', 'icon': Icons.water_drop_rounded},
    {'name': 'Spray', 'icon': Icons.air_rounded},
    {'name': 'Beauty', 'icon': Icons.auto_awesome_rounded},
  ];

  FlashMode _flashMode = FlashMode.off;
  bool _flashSupported = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (_flashSupported) {
          await _controller!.setFlashMode(_flashMode);
        }

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraError = false;
          });
        }
      } else {
        if (mounted) setState(() => _cameraError = true);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = true;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (!_flashSupported) return;

    final modes = [FlashMode.off, FlashMode.auto, FlashMode.torch];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    final nextMode = modes[nextIndex];

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
      HapticEngine.selection();
    } catch (e) {
      // Flash not supported on this device/simulator
      setState(() => _flashSupported = false);
      debugPrint('Flash not supported: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.scansUsed ?? 0) >= 3 &&
        !(state.profile?.isPremium ?? false)) {
      PaywallSheet.show(context);
      return;
    }

    try {
      HapticEngine.light();
      final XFile image = await _controller!.takePicture();
      _processImage(File(image.path));
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        state.showToast('Camera error. Please try again or pick from gallery.',
            type: 'error');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final state = Provider.of<AppState>(context, listen: false);
    if ((state.profile?.scansUsed ?? 0) >= 3 &&
        !(state.profile?.isPremium ?? false)) {
      PaywallSheet.show(context);
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _processImage(File(image.path));
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(
        tempDir.path, "${DateTime.now().millisecondsSinceEpoch}_comp.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1024,
      minHeight: 1024,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _processImage(File file) async {
    final state = Provider.of<AppState>(context, listen: false);
    setState(() {
      _imageFile = file;
      _isScanning = true;
      _scanStep = 0;
    });

    // Cycle through scan steps for animation
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted || !_isScanning) return false;
      HapticEngine.light();
      setState(() => _scanStep = (_scanStep + 1) % _scanSteps.length);
      return _isScanning;
    });

    final compressedFile = await _compressImage(file);
    final fileToScan = compressedFile ?? file;

    // Parallelize AI scan and Image upload for better UX
    final results = await Future.wait([
      GeminiService.scanMedicine(fileToScan,
          country: state.profile?.country ?? ''),
      state.uploadImage(fileToScan),
    ]);

    final response = results[0] as Result<ScanResult>;
    final cloudUrl = results[1] as String?;

    if (!mounted) return;

    response.fold(
      (success) async {
        HapticEngine.successScan();
        setState(() {
          _isScanning = false;
          // Auto-detect mapping
          if (success.isLiquid) {
            _selectedCategory = 'Liquid';
          } else if (success.isSpray ||
              success.form.toLowerCase().contains('spray')) {
            _selectedCategory = 'Spray';
          } else if (success.form.toLowerCase().contains('tablet') ||
              success.form.toLowerCase().contains('pill') ||
              success.form.toLowerCase().contains('capsule')) {
            _selectedCategory = 'Tablet';
          }
        });

        await state.incrementScanCount();

        _showResultModal(success.copyWith(
            imageUrl: cloudUrl ?? file.path,
            category: _selectedCategory,
            description: success.name.isNotEmpty ? success.name : null,
            form: success.form));
      },
      (failure) {
        // NEVER show an error to the user face. Instead, transition to "Smart Manual Entry".
        HapticEngine.selection();
        setState(() => _isScanning = false);

        _showResultModal(ScanResult(
          identified: false,
          systemBusy:
              true, // This will trigger the "Smart Assist" UI in the modal
          imageUrl: cloudUrl ?? file.path,
          category: _selectedCategory,
        ));
      },
    );
  }

  void _showResultModal(ScanResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ResultModal(
        result: result,
        onSave: (med) {
          Navigator.pop(context);
          if (widget.onSave != null) {
            widget.onSave!(med);
          } else {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.addMedicine(med);

            // Viral & Growth Loop: Share the "Magic Moment" of AI Scan
            if (med.id != 0) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  ShareService.shareAchievement(
                    title: 'New Medicine Scanned! ⚡',
                    subtitle:
                        'I just used Med AI to verify ${med.name}. Magic! ✨',
                    emoji: '🧬',
                  );

                  // Trigger review if first few scans are successful
                  if ((appState.profile?.scansUsed ?? 0) == 1 ||
                      (appState.profile?.scansUsed ?? 0) == 5) {
                    ReviewService.requestReview();
                  }
                }
              });
            }

            if (widget.onScanAdded != null) widget.onScanAdded!();
          }
        },
      ),
    );
  }

  Widget _buildCameraErrorUI() {
    final L = context.L;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: L.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.videocam_off_rounded, color: L.error, size: 32),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Camera Unavailable',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t access your camera. You can still add your medicine manually.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            BouncingButton(
              onTap: widget.onManualAdd ?? () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'ADD MANUALLY',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _initCamera,
              child: Text(
                'RETRY CAMERA',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) return _buildAnalyzingState();
    if (_cameraError) return _buildCameraErrorUI();

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // 1. Full-screen Camera Preview
          if (_isCameraInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  child: RepaintBoundary(
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms)
          else
            const Center(child: AppLoadingIndicator(size: 40)),

          // 2. Scan Frame Brackets
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 100), // Offset slightly up
              width: size.width * 0.8,
              height: size.width * 0.8,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: ScanFramePainter(
                    category: _selectedCategory,
                    primaryColor: context.L.primary,
                  ),
                  child: _buildScanningLine(),
                ),
              ),
            ),
          ).animate().scale(begin: const Offset(0.9, 0.9), delay: 200.ms),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularBtn(
                    icon: Icons.close_rounded,
                    onTap: widget.onClose ?? () => Navigator.pop(context),
                  ),
                  _buildScanLimitPill(context),
                  _buildCircularBtn(
                    icon: Icons.history_rounded,
                    onTap: () {
                      HapticEngine.selection();
                      // Future: Show scan history
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2, end: 0),

          // 4. Bottom Controls Cluster (Category + Shutter)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoryPill(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: _buildBottomControls(),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Image thumbnail with pulsing glow ──────────────────
                if (_imageFile != null)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final glow = 0.15 + _pulseController.value * 0.2;
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: glow),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_imageFile!,
                                  fit: BoxFit.cover, width: 140, height: 140),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.4 + _pulseController.value * 0.3),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.document_scanner_rounded,
                          color: AppColors.primaryBlue, size: 48),
                    ),
                  ),

                const SizedBox(height: 36),

                // ── Animated step label ────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ),
                  child: SmoothingText(
                    key: ValueKey(_scanStep),
                    text: '${_scanStepIcons[_scanStep]}  ${_scanSteps[_scanStep]}',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.2,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Step progress pills ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_scanSteps.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _scanStep ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= _scanStep
                            ? AppColors.primaryBlue
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // ── Step list ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: List.generate(_scanSteps.length, (i) {
                      final done = i < _scanStep;
                      final active = i == _scanStep;
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < _scanSteps.length - 1 ? 16 : 0),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: done || active ? 1.0 : 0.3,
                          child: Row(
                            children: [
                              // Step circle
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done
                                      ? AppColors.primaryBlue
                                      : active
                                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: done || active
                                        ? AppColors.primaryBlue
                                        : Colors.white12,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: done
                                      ? const Icon(Icons.check_rounded,
                                          size: 16, color: Colors.white)
                                      : active
                                          ? const AppLoadingIndicator(size: 14)
                                          : Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                  color: Colors.white38),
                                            ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '${_scanStepIcons[i]}  ${_scanSteps[i]}',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: done || active
                                        ? Colors.white
                                        : Colors.white38,
                                    fontWeight: active
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'AI-powered analysis in progress...',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (context, child) {
        switch (_selectedCategory) {
          case 'Liquid':
            return _buildLiquidAnimation();
          case 'Spray':
            return _buildSprayAnimation();
          case 'Beauty':
            return _buildBeautyAnimation();
          default:
            return _buildTabletAnimation();
        }
      },
    );
  }

  Widget _buildTabletAnimation() {
    return Stack(
      children: [
        Positioned(
          top: _scanLineController.value *
              (MediaQuery.of(context).size.width * 0.75),
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 4,
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                color: context.L.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: AppShadows.glow(context.L.primary, intensity: 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidAnimation() {
    return Center(
      child: Container(
        width: (MediaQuery.of(context).size.width * 0.75) *
            _scanLineController.value,
        height: (MediaQuery.of(context).size.width * 0.75) *
            _scanLineController.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.L.primary
                .withValues(alpha: 0.8 * (1.0 - _scanLineController.value)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.L.primary
                  .withValues(alpha: 0.2 * (1.0 - _scanLineController.value)),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprayAnimation() {
    return Stack(
      children: List.generate(15, (i) {
        final random = (i * 137) % 100 / 100.0;
        final animValue = (_scanLineController.value + random) % 1.0;
        return Positioned(
          left: (MediaQuery.of(context).size.width * 0.75) *
              ((i * 23) % 100 / 100.0),
          top: (MediaQuery.of(context).size.width * 0.75) * animValue,
          child: Opacity(
            opacity: 1.0 - animValue,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3), blurRadius: 4)
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBeautyAnimation() {
    return Stack(
      children: List.generate(10, (i) {
        final randomX = (i * 157) % 100 / 100.0;
        final randomY = (i * 263) % 100 / 100.0;
        final animValue = (_scanLineController.value + (i * 0.1)) % 1.0;
        return Positioned(
          left: (MediaQuery.of(context).size.width * 0.75) * randomX,
          top: (MediaQuery.of(context).size.width * 0.75) * randomY,
          child: Transform.rotate(
            angle: animValue * 3.14,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 1.0 - animValue),
              size: 18 * (1.0 - animValue),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCircularBtn(
      {required IconData icon,
      required VoidCallback onTap,
      bool isActive = false}) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? context.L.primary : context.L.card,
          shape: BoxShape.circle,
          border: Border.all(
              color: isActive ? context.L.primary : context.L.border,
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (isActive)
              BoxShadow(
                color: context.L.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child:
            Icon(icon, color: isActive ? Colors.black : Colors.white, size: 24),
      ),
    );
  }

  Widget _buildScanLimitPill(BuildContext context) {
    final state = context.watch<AppState>();
    final used = state.profile?.scansUsed ?? 0;
    final isPremium = state.profile?.isPremium ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.L.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isPremium
              ? Icon(Icons.verified_rounded, color: context.L.primary, size: 16)
              : const Text(" ✨", style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(
            isPremium ? "PRO UNLIMITED" : "$used OF 3 SCANS",
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: context.L.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.L.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['name'];
              return BouncingButton(
                onTap: () {
                  HapticEngine.selection();
                  setState(() => _selectedCategory = cat['name']);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cat['icon'],
                        size: 18,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          cat['name'],
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 6),
                        Text(
                          cat['name'],
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    IconData flashIcon;
    switch (_flashMode) {
      case FlashMode.off:
        flashIcon = Icons.flash_off_rounded;
        break;
      case FlashMode.auto:
        flashIcon = Icons.flash_auto_rounded;
        break;
      case FlashMode.torch:
        flashIcon = Icons.flashlight_on_rounded;
        break;
      default:
        flashIcon = Icons.flash_off_rounded;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularBtn(
          icon: Icons.image_outlined,
          onTap: _pickFromGallery,
        ),
        const SizedBox(width: 40), // Added spacing
        BouncingButton(
          onTap: _capturePhoto,
          scaleFactor: 0.95,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 1000.ms,
                curve: Curves.easeInOut,
              )
              .shimmer(
                  delay: 2000.ms, duration: 1500.ms, color: Colors.white24),
        ),
        const SizedBox(width: 40), // Added spacing
        _buildCircularBtn(
          icon: flashIcon,
          onTap: _toggleFlash,
          isActive: _flashMode != FlashMode.off,
        ),
      ],
    );
  }
}

class _ResultModal extends StatefulWidget {
  final ScanResult result;
  final Function(Medicine) onSave;

  const _ResultModal({required this.result, required this.onSave});

  @override
  State<_ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<_ResultModal> {
  late int _count;
  late List<ScheduleEntry> _manualSchedule;
  bool _useAutoSchedule = true;

  // Editable Controllers
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _doseController;
  late TextEditingController _formController;
  late TextEditingController _unitController; // NEW

  // Clinical Controllers
  late TextEditingController _descController;
  late TextEditingController _howController;
  late TextEditingController _sideEffectsController;
  late TextEditingController _interactionsController;
  late TextEditingController _warningsController;
  late TextEditingController _additionalController; // NEW

  // Rx Details Controllers
  late TextEditingController _pharmacyNameController;
  late TextEditingController _pharmacyPhoneController;
  late TextEditingController _rxNumberController;

  @override
  void initState() {
    super.initState();
    _count = widget.result.pillCount > 0 ? widget.result.pillCount : 30;

    _nameController = TextEditingController(text: widget.result.name);
    _brandController = TextEditingController(text: widget.result.brand);
    _doseController = TextEditingController(text: widget.result.dose);
    _formController = TextEditingController(text: widget.result.form);
    _unitController = TextEditingController(text: widget.result.unit);

    _descController = TextEditingController(text: widget.result.description);
    _howController = TextEditingController(
        text: "${widget.result.howToTake}\n\n${widget.result.whenToTake}");
    _sideEffectsController =
        TextEditingController(text: widget.result.sideEffects);
    _interactionsController =
        TextEditingController(text: widget.result.interactions);
    _warningsController = TextEditingController(text: widget.result.warnings);
    _additionalController = TextEditingController();

    _pharmacyNameController = TextEditingController();
    _pharmacyPhoneController = TextEditingController();
    _rxNumberController = TextEditingController();

    // Convert ScanResult slots to ScheduleEntry entities
    if (widget.result.scheduleSlots.isNotEmpty) {
      _manualSchedule = widget.result.scheduleSlots.map((s) {
        String ritualStr = s['ritual'] ?? 'none';
        Ritual ritual = Ritual.values.firstWhere(
          (r) => r.name == ritualStr,
          orElse: () => Ritual.none,
        );

        return ScheduleEntry(
          h: s['h'] ?? 8,
          m: s['m'] ?? 0,
          label: s['label'] ?? 'Reminder',
          days: List<int>.from(s['days'] ?? [0, 1, 2, 3, 4, 5, 6]),
          ritual: ritual != Ritual.none ? ritual : _getAutoRitual(s['h'] ?? 8),
        );
      }).toList();
    } else {
      _manualSchedule = [
        ScheduleEntry(
            h: 8,
            m: 0,
            label: 'Morning',
            days: [0, 1, 2, 3, 4, 5, 6],
            ritual: _getAutoRitual(8)),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _doseController.dispose();
    _formController.dispose();
    _unitController.dispose();
    _descController.dispose();
    _howController.dispose();
    _sideEffectsController.dispose();
    _interactionsController.dispose();
    _warningsController.dispose();
    _additionalController.dispose();

    _pharmacyNameController.dispose();
    _pharmacyPhoneController.dispose();
    _rxNumberController.dispose();
    super.dispose();
  }

  void _showAuthPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        decoration: BoxDecoration(
          color: context.L.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(
              color: context.L.border.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.L.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: context.L.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: context.L.primary.withValues(alpha: 0.2), width: 2),
              ),
              child: Center(
                  child: Text('🛡️',
                      style:
                          AppTypography.displayMedium.copyWith(fontSize: 44))),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds),
            const SizedBox(height: 28),
            Text(
              "Secure Your Health Data",
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                color: context.L.text,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Sign in now to sync your medicines and never lose your streak. It only takes a second.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.L.sub,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            BouncingButton(
              onTap: () async {
                HapticEngine.selection();
                Navigator.pop(context);
                await AuthService.signInWithGoogle();
              },
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: context.L.text,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: context.L.text.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppColors.white, shape: BoxShape.circle),
                      child: const Text("G",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.black)),
                    ),
                    const SizedBox(width: 14),
                    Text("Continue with Google",
                        style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: context.L.bg,
                            fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BouncingButton(
              onTap: () {
                HapticEngine.light();
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "Maybe Later",
                  style: AppTypography.labelLarge.copyWith(
                      color: context.L.sub.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReviewHelp() {
    final L = context.L;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: L.text),
            const SizedBox(width: 12),
            const Expanded(
                child: Text(
                    "Everything is editable! Tap any text field to correct or add details.")),
          ],
        ),
        backgroundColor: L.card,
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: context.L.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: context.L.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: L.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.result.systemBusy)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: L.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: L.primary.withValues(alpha: 0.2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: L.primary.withValues(alpha: 0.05),
                              blurRadius: 20,
                              spreadRadius: 2),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: L.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: const Center(
                                child:
                                    Text("✨", style: TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SMART ASSIST ACTIVE",
                                  style: AppTypography.labelSmall.copyWith(
                                    color: L.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Our AI is offline but your photo is ready. Please confirm the details below.",
                                  style: AppTypography.bodySmall.copyWith(
                                    color: L.text.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),

                  // Verification Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(
                          widget.result.identified, widget.result.systemBusy),
                      BouncingButton(
                        onTap: () {
                          HapticEngine.light();
                          _showReviewHelp();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: L.fill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: L.border.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Review Details",
                                style: AppTypography.labelMedium.copyWith(
                                  color: L.text.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.help_outline_rounded,
                                  size: 14,
                                  color: L.text.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Main Title & Category (Now Editable)
                  _buildEditableField(
                    controller: _nameController,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    hint: widget.result.category == 'Beauty'
                        ? "Product Name"
                        : "Medicine Name",
                    L: L,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildEditableChip(
                              controller: _brandController,
                              icon: "🏢",
                              hint: "Brand",
                              L: L)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildEditableChip(
                              controller: _doseController,
                              icon: "⚡",
                              hint: "Dose",
                              L: L)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildEditableChip(
                              controller: _formController,
                              icon: "📦",
                              hint: "Form",
                              L: L)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditableChip(
                          controller: _unitController,
                          icon: "📐",
                          hint: "Unit (ml, mg, tablets)",
                          L: L,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Pharmacy & Rx
                  _buildSectionHeader("🏥 PHARMACY & REFILL", L),
                  _buildExpandableCard(
                    title: "Pharmacy Name",
                    icon: Icons.local_pharmacy_rounded,
                    controller: _pharmacyNameController,
                    L: L,
                    hint: "e.g. CVS, Walgreens (Optional)",
                  ),
                  _buildExpandableCard(
                    title: "Pharmacy Phone",
                    icon: Icons.phone_rounded,
                    controller: _pharmacyPhoneController,
                    L: L,
                    hint: "e.g. 555-0123 (Optional)",
                  ),
                  _buildExpandableCard(
                    title: "Rx Number",
                    icon: Icons.receipt_long_rounded,
                    controller: _rxNumberController,
                    L: L,
                    hint: "e.g. 1234567-89 (Optional)",
                  ),

                  const SizedBox(height: 32),

                  // Info Sections
                  _buildSectionHeader(
                      widget.result.category == 'Beauty'
                          ? "✨ PRODUCT INFO"
                          : "ℹ️ CLINICAL INFO",
                      L),
                  _buildExpandableCard(
                    title: "Medical Purpose",
                    icon: Icons.info_outline_rounded,
                    controller: _descController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "How to Take",
                    icon: Icons.menu_book_rounded,
                    controller: _howController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "Side Effects",
                    icon: Icons.error_outline_rounded,
                    controller: _sideEffectsController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "Interactions",
                    icon: Icons.swap_calls_rounded,
                    controller: _interactionsController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "Warnings",
                    icon: Icons.warning_amber_rounded,
                    controller: _warningsController,
                    L: L,
                    accentColor: context.L.text,
                  ),

                  // Additional/Personal Notes
                  _buildExpandableCard(
                    title: "Personal Notes",
                    icon: Icons.note_add_rounded,
                    controller: _additionalController,
                    L: L,
                    accentColor: context.L.text,
                    hint:
                        "Add any special instructions or doctor's notes here...",
                  ),

                  const SizedBox(height: 24),

                  // Dosing Logic Section
                  _buildSectionHeader("⏰ REMINDER SCHEDULE", L),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: L.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleBtn(
                              "Auto suggested ✨",
                              _useAutoSchedule,
                              () => setState(() => _useAutoSchedule = true),
                              L),
                        ),
                        Expanded(
                          child: _buildToggleBtn(
                              "Manual config ⚙️",
                              !_useAutoSchedule,
                              () => setState(() => _useAutoSchedule = false),
                              L),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_useAutoSchedule)
                    _buildAutoScheduleView(L)
                  else
                    _buildManualScheduleView(L),

                  const SizedBox(height: 32),

                  // Inventory section
                  _buildSectionHeader(
                      widget.result.category == 'Liquid'
                          ? "💧 LIQUID INVENTORY"
                          : "📦 INVENTORY",
                      L),
                  const SizedBox(height: 16),
                  _buildInventorySelector(L),

                  const SizedBox(height: 48),

                  // Primary Action
                  BouncingButton(
                    onTap: () {
                      HapticEngine.successScan();
                      final med = Medicine(
                        id: DateTime.now().millisecondsSinceEpoch,
                        name: _nameController.text,
                        brand: _brandController.text,
                        dose: _doseController.text,
                        form: _formController.text,
                        category: widget.result.category,
                        count: _count,
                        totalCount: _count,
                        imageUrl: widget.result.imageUrl,
                        notes:
                            "PURPOSE:\n${_descController.text}\n\nINSTRUCTIONS:\n${_howController.text}\n\nWARNINGS:\n${_warningsController.text}\n\nNOTES:\n${_additionalController.text}",
                        courseStartDate: todayStr(),
                        unit: _unitController.text,
                        schedule: _manualSchedule,
                        refillInfo: (_pharmacyNameController.text.isNotEmpty ||
                                _pharmacyPhoneController.text.isNotEmpty ||
                                _rxNumberController.text.isNotEmpty)
                            ? RefillInfo(
                                pharmacyName:
                                    _pharmacyNameController.text.trim(),
                                pharmacyPhone:
                                    _pharmacyPhoneController.text.trim(),
                                rxNumber: _rxNumberController.text.trim(),
                                totalQuantity: _count.toDouble(),
                                currentInventory: _count.toDouble(),
                                refillThreshold: 10,
                              )
                            : null,
                      );
                      widget.onSave(med);

                      // If NOT logged in, show auth prompt
                      if (!AuthService.isLoggedIn) {
                        _showAuthPrompt(context);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: context.L.text,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: context.L.text.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: context.L.bg),
                          const SizedBox(width: 12),
                          Text(
                            "Confirm & Save Medicine",
                            style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: context.L.bg,
                                letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                      delay: 3.seconds,
                      duration: 2.seconds,
                      color: L.bg.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool identified, bool systemBusy) {
    final L = context.L;

    String label = identified ? "AI VERIFIED" : "MANUAL REVIEW";
    IconData icon =
        identified ? Icons.verified_rounded : Icons.help_center_rounded;
    Color color = identified ? L.text : L.sub;
    Color bg = identified ? L.fill : L.fill.withValues(alpha: 0.5);

    if (systemBusy) {
      label = "SMART ASSIST";
      icon = Icons.auto_awesome_rounded;
      color = L.primary;
      bg = L.primary.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required double fontSize,
    required FontWeight fontWeight,
    required String hint,
    required AppThemeColors L,
  }) {
    return TextField(
      controller: controller,
      style: AppTypography.headlineMedium.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: L.text,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium
            .copyWith(color: L.text.withValues(alpha: 0.3)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEditableChip({
    required TextEditingController controller,
    required String icon,
    required String hint,
    required AppThemeColors L,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: L.fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.border),
      ),
      child: Row(
        children: [
          Text(icon, style: AppTypography.bodySmall.copyWith(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.labelMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.labelMedium
                    .copyWith(color: L.text.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeColors L) {
    return Text(
      title,
      style: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w900,
        color: L.text.withValues(alpha: 0.5),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required AppThemeColors L,
    Color? accentColor,
    String? hint,
  }) {
    // Show if text not empty OR if it's the "Personal Notes" field
    if (controller.text.isEmpty && title != "Personal Notes") {
      return const SizedBox();
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: L.fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: accentColor ?? L.text.withValues(alpha: 0.5),
                  size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: null,
            style: AppTypography.bodyMedium.copyWith(
              color: L.text.withValues(alpha: 0.6),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMedium
                  .copyWith(color: L.text.withValues(alpha: 0.3)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySelector(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Quantity",
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w800, color: L.text)),
              Text(
                  widget.result.category == 'Liquid'
                      ? "volume detected"
                      : "${_unitController.text} supply detected",
                  style: AppTypography.bodySmall
                      .copyWith(color: L.text.withValues(alpha: 0.5))),
            ],
          ),
          Row(
            children: [
              _ModalQtyBtn(
                icon: Icons.remove_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _count = (_count - 1).clamp(1, 999));
                },
              ),
              const SizedBox(width: 16),
              Text(
                "$_count",
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: L.text,
                ),
              ),
              const SizedBox(width: 16),
              _ModalQtyBtn(
                icon: Icons.add_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _count++);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
      String label, bool active, VoidCallback onTap, AppThemeColors L) {
    return BouncingButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? L.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: active ? L.text : L.text.withValues(alpha: 0.5),
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoScheduleView(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.L.fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.L.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: context.L.text, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI suggested schedule by frequency",
                  style: AppTypography.labelMedium.copyWith(
                    color: L.text.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._manualSchedule
              .asMap()
              .entries
              .map((e) => _buildScheduleItem(e.key, e.value, L)),
        ],
      ),
    );
  }

  Widget _buildManualScheduleView(AppThemeColors L) {
    return Column(
      children: [
        ..._manualSchedule
            .asMap()
            .entries
            .map((e) => _buildScheduleItem(e.key, e.value, L)),
        const SizedBox(height: 12),
        BouncingButton(
          onTap: () {
            HapticEngine.light();
            setState(() {
              _manualSchedule.add(ScheduleEntry(
                  h: 12,
                  m: 0,
                  label: _getAutoLabel(12),
                  ritual: _getAutoRitual(12),
                  days: [0, 1, 2, 3, 4, 5, 6]));
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_time_rounded,
                    size: 20, color: L.text.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Text("Add custom time",
                    style: AppTypography.labelLarge.copyWith(
                        color: L.text.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getAutoLabel(int h) {
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }

  Ritual _getAutoRitual(int h) {
    if (h >= 6 && h <= 9) return Ritual.afterBreakfast;
    if (h >= 11 && h <= 14) return Ritual.afterLunch;
    if (h >= 17 && h <= 20) return Ritual.afterDinner;
    if (h >= 21) return Ritual.beforeSleep;
    return Ritual.none;
  }

  String _getRitualLabel(Ritual ritual) {
    switch (ritual) {
      case Ritual.beforeBreakfast:
        return 'Before Breakfast';
      case Ritual.withBreakfast:
        return 'With Breakfast';
      case Ritual.afterBreakfast:
        return 'After Breakfast';
      case Ritual.beforeLunch:
        return 'Before Lunch';
      case Ritual.withLunch:
        return 'With Lunch';
      case Ritual.afterLunch:
        return 'After Lunch';
      case Ritual.beforeDinner:
        return 'Before Dinner';
      case Ritual.withDinner:
        return 'With Dinner';
      case Ritual.afterDinner:
        return 'After Dinner';
      case Ritual.beforeSleep:
        return 'Before Sleep';
      default:
        return 'No Meal Ritual';
    }
  }

  Widget _buildScheduleItem(int idx, ScheduleEntry s, AppThemeColors L) {
    final timeStr = fmtTime(s.h, s.m, context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: L.fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              BouncingButton(
                onTap: () async {
                  HapticEngine.selection();
                  final result = await ModernTimePicker.show(
                    context,
                    initialTime: TimeOfDay(hour: s.h, minute: s.m),
                    title: "Edit Time",
                  );
                  if (result != null) {
                    setState(() {
                      s.h = result.hour;
                      s.m = result.minute;
                      s.label = _getAutoLabel(result.hour);
                      if (s.ritual == Ritual.none) {
                        s.ritual = _getAutoRitual(result.hour);
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: L.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm_rounded,
                          color: context.L.text, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BouncingButton(
                    onTap: () {
                      HapticEngine.light();
                      _showRitualPicker(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.ritual != Ritual.none
                            ? L.primary.withValues(alpha: 0.1)
                            : L.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: s.ritual != Ritual.none
                              ? L.primary.withValues(alpha: 0.3)
                              : L.border,
                        ),
                      ),
                      child: Text(
                        _getRitualLabel(s.ritual).toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: s.ritual != Ritual.none ? L.green : L.sub,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.label,
                    style: AppTypography.labelLarge.copyWith(
                      color: L.text.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _manualSchedule.removeAt(idx);
              });
            },
            icon: Icon(Icons.remove_circle_outline_rounded,
                color: L.red.withValues(alpha: 0.5)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showRitualPicker(ScheduleEntry s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.L.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: context.L.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select Meal Ritual",
                style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w900, color: context.L.text)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: Ritual.values.map((r) {
                  final isSelected = s.ritual == r;
                  return ListTile(
                    onTap: () {
                      setState(() => s.ritual = r);
                      Navigator.pop(context);
                    },
                    title: Text(_getRitualLabel(r),
                        style: AppTypography.bodyLarge.copyWith(
                            color:
                                isSelected ? context.L.green : context.L.text,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500)),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            color: context.L.green)
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ModalQtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.L.fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: L.border, width: 1.5),
        ),
        child: Icon(icon, size: 22, color: L.text),
      ),
    );
  }
}

class ScanFramePainter extends CustomPainter {
  final String category;
  final Color primaryColor;
  ScanFramePainter({required this.category, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    switch (category) {
      case 'Liquid':
        _paintLiquidFrame(canvas, size, paint, glowPaint);
        break;
      case 'Spray':
        _paintSprayFrame(canvas, size, paint, glowPaint);
        break;
      case 'Beauty':
        _paintBeautyFrame(canvas, size, paint, glowPaint);
        break;
      default:
        _paintTabletFrame(canvas, size, paint, glowPaint);
    }
  }

  void _paintTabletFrame(
      Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    const cornerSize = 48.0;
    final path = Path();
    // Top Left
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);
    // Top Right
    path.moveTo(size.width - cornerSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerSize);
    // Bottom Left
    path.moveTo(0, size.height - cornerSize);
    path.lineTo(0, size.height);
    path.lineTo(cornerSize, size.height);
    // Bottom Right
    path.moveTo(size.width - cornerSize, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height - cornerSize);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _paintLiquidFrame(
      Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2.2, glowPaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2.2, paint);
  }

  void _paintSprayFrame(
      Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    final center = Offset(size.width / 2, size.height / 2);
    const armSize = 40.0;
    const gap = 20.0;

    final path = Path();
    // Crosshair arms
    path.moveTo(center.dx, gap);
    path.lineTo(center.dx, gap + armSize);
    path.moveTo(center.dx, size.height - gap);
    path.lineTo(center.dx, size.height - gap - armSize);
    path.moveTo(gap, center.dy);
    path.lineTo(gap + armSize, center.dy);
    path.moveTo(size.width - gap, center.dy);
    path.lineTo(size.width - gap - armSize, center.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _paintBeautyFrame(
      Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    final path = Path();
    const inset = 30.0;
    path.moveTo(size.width / 2, inset);
    path.quadraticBezierTo(
        size.width - inset, inset, size.width - inset, size.height / 2);
    path.quadraticBezierTo(size.width - inset, size.height - inset,
        size.width / 2, size.height - inset);
    path.quadraticBezierTo(inset, size.height - inset, inset, size.height / 2);
    path.quadraticBezierTo(inset, inset, size.width / 2, inset);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.category != category;
}
