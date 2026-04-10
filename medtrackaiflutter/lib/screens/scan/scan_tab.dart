import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
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
import '../../widgets/shared/shared_widgets.dart';
import '../medicine/widgets/body_impact_card.dart';
import '../medicine/widgets/inline_ai_coach.dart';
import '../../core/utils/logger.dart';
import '../../core/error/failures.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tablet', 'icon': '💊'},
    {'name': 'Liquid', 'icon': '🔬'},
    {'name': 'Spray', 'icon': '🫧'},
    {'name': 'Beauty', 'icon': '✨'},
  ];

  FlashMode _flashMode = FlashMode.off;
  final bool _flashSupported = true;

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
      // 1. Explicit Permission Check for better DX
      final status = await Permission.camera.request().timeout(const Duration(seconds: 5));
      if (!status.isGranted) {
        if (mounted) setState(() => _cameraError = true);
        return;
      }

      _cameras = await availableCameras().timeout(const Duration(seconds: 5));
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          // Downgraded to medium for better stability across emulators/legacy devices
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize().timeout(const Duration(seconds: 10));
        if (_flashSupported) {
          await _controller!.setFlashMode(_flashMode).timeout(const Duration(seconds: 2));
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
      if (nextMode == FlashMode.torch) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else if (nextMode == FlashMode.auto) {
        await _controller!.setFlashMode(FlashMode.auto);
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }
      setState(() => _flashMode = nextMode);
      HapticEngine.selection();
    } catch (e) {
      // Fallback
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

    // Cycle through scan steps for animation (Accelerated to feel like Cal AI)
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || !_isScanning) return false;
      HapticEngine.light();
      setState(() => _scanStep = (_scanStep + 1) % _scanSteps.length);
      return _isScanning;
    });

    final compressedFile = await _compressImage(file);
    final fileToScan = compressedFile ?? file;

    // Validate file exists before processing
    if (!await fileToScan.exists()) {
      setState(() {
        _isScanning = false;
        _cameraError = true;
      });
      _showErrorDialog(
          'Unable to access the captured image. Please try again.');
      return;
    }

    // Parallelize AI scan and Image upload for better UX
    // Wrapped in a catch-all to prevent app crashes on network-failure components
    List<dynamic> results;
    try {
      results = await Future.wait([
        GeminiService.scanMedicine(fileToScan,
            country: state.profile?.country ?? ''),
        state.uploadImage(fileToScan),
      ]).timeout(const Duration(seconds: 40));
    } catch (e) {
      appLogger.e('[ScanTab] Processing pipeline failure', error: e);

      // Check for file system errors and provide specific messaging
      String errorMessage = 'Pipeline failed. Please try again.';
      if (e.toString().contains('FileSystemException') ||
          e.toString().contains('not found') ||
          e.toString().contains('Cannot read')) {
        errorMessage =
            'Unable to read the image file. Please try capturing a new photo.';
      }

      // Fallback to empty results to trigger Manual Entry mode
      results = [Error<ScanResult>(ScanFailure(errorMessage)), null];
    }

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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.L.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: context.L.error, size: 24),
            const SizedBox(width: 12),
            Text('Scan Error',
                style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900, color: context.L.text)),
          ],
        ),
        content: Text(message,
            style: AppTypography.bodyMedium
                .copyWith(color: context.L.sub, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: AppTypography.labelLarge.copyWith(
                    color: context.L.text, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
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
                        'I just used MedAI to verify ${med.name}. Magic! ✨',
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
                border: Border.all(
                    color: L.error.withValues(alpha: 0.1), width: 0.5),
              ),
              child: const Center(
                  child: Text('📸', style: TextStyle(fontSize: 32))),
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
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    'ADD MANUALLY',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
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
          if (_isCameraInitialized &&
              _controller != null &&
              _controller!.value.previewSize != null)
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

          // 2. Scan Frame Brackets (Pro Minimalist)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 60), // Lowered from 120
              width: size.width * 0.8,
              height: size.width * 0.8,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ProScanFramePainter(
                    category: _selectedCategory,
                  ),
                  child: _buildScanningLine(),
                ),
              ),
            ),
          ).animate().scale(begin: const Offset(0.95, 0.95), duration: 600.ms),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularBtn(
                    icon: Icons.close_rounded,
                    onTap: widget.onClose ?? () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(child: _buildScanLimitPill(context)),
                  ),
                  const SizedBox(width: 8),
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
                padding: const EdgeInsets.only(
                    bottom: 64), // Lowered from 160 to follow user request
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoryPill(),
                    const SizedBox(height: 20), // Slightly reduced from 24
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
    final L = context.L;
    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: L.bg),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Hero Scanner Visual (Pro B&W) ──────────────────
                    if (_imageFile != null)
                      _buildPulsingThumbnail(L)
                    else
                      const Text('🔬', style: TextStyle(fontSize: 64)),

                    const SizedBox(height: 64),

                    // ── Progress & Steps ──
                    _buildStepIndicator(L),

                    const SizedBox(height: 48),

                    AnimatedSwitcher(
                      duration: 300.ms,
                      child: Text(
                        _scanSteps[_scanStep].toUpperCase(),
                        key: ValueKey(_scanStep),
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PRECISION SCANNING • VER 2.6',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(
                  'PRO_LINK_ENCRYPTED',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingThumbnail(AppThemeColors L) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = 0.05 + _pulseController.value * 0.1;
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: glow),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_imageFile!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        L.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    border: Border.all(
                      color: L.border.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                _buildScanningEffect(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanningEffect() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (context, _) {
        return Positioned(
          top: _scanLineController.value * 180,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: context.L.text,
              boxShadow: [
                BoxShadow(
                    color: context.L.text.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2)
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(AppThemeColors L) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_scanSteps.length, (i) {
        final isActive = i == _scanStep;
        final isDone = i < _scanStep;
        return Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: 400.ms,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? L.text : L.card,
                  border: Border.all(
                    color: isActive || isDone
                        ? L.text
                        : L.border.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check_rounded, size: 16, color: L.bg)
                      : isActive
                          ? AppLoadingIndicator(size: 14, color: L.text)
                          : Text('${i + 1}',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.3),
                                fontWeight: FontWeight.w900,
                              )),
                ),
              ),
              if (i < _scanSteps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: isDone
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        );
      }),
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
            return _buildProTabletAnimation();
        }
      },
    );
  }

  Widget _buildProTabletAnimation() {
    final color = context.isDark ? context.L.secondary : Colors.white;
    return Stack(
      children: [
        Positioned(
          top: _scanLineController.value *
              (MediaQuery.of(context).size.width * 0.7),
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 2.5,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 15, spreadRadius: 3)
                ],
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child:
            Icon(icon, color: isActive ? Colors.black : Colors.white, size: 22),
      ),
    );
  }

  Widget _buildScanLimitPill(BuildContext context) {
    final state = context.watch<AppState>();
    final used = state.profile?.scansUsed ?? 0;
    final isPremium = state.profile?.isPremium ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isPremium
              ? const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 14)
              : const Text("✨", style: TextStyle(fontSize: 12)),
          const SizedBox(width: 10),
          Text(
            isPremium ? "PREMIUM UNLIMITED" : "$used / 3 SCANS",
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 25,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        cat['icon'],
                        style: TextStyle(
                          fontSize: 18,
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['name'].toUpperCase(),
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.5),
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircularBtn(
            icon: Icons.image_outlined,
            onTap: _pickFromGallery,
          ),
          const SizedBox(width: 24),
          BouncingButton(
            onTap: _capturePhoto,
            scaleFactor: 0.95,
            child: Container(
              width: 80,
              height: 80,
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
          const SizedBox(width: 24),
          _buildCircularBtn(
            icon: flashIcon,
            onTap: _toggleFlash,
            isActive: _flashMode != FlashMode.off,
          ),
        ],
      ),
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
      _manualSchedule =
          widget.result.scheduleSlots.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        String ritualStr = s['ritual'] ?? 'none';
        Ritual ritual = Ritual.values.firstWhere(
          (r) => r.name == ritualStr,
          orElse: () => Ritual.none,
        );

        return ScheduleEntry(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}_$idx',
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
            id: 'init_${DateTime.now().millisecondsSinceEpoch}',
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.L.text.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            const Text('🛡️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 28),
            Text(
              "Secure Your Data",
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                color: context.L.text,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Sign in to sync your medicines and maintain your medical history safely.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.L.sub,
                fontSize: 15,
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
                      decoration: BoxDecoration(
                          color: context.L.bg, shape: BoxShape.circle),
                      child: Text("G",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: context.L.text,
                              fontSize: 12)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: context.L.bg, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              "Everything is editable. Tap to correct details.",
              style: AppTypography.labelMedium
                  .copyWith(color: context.L.bg, fontWeight: FontWeight.w700),
            )),
          ],
        ),
        backgroundColor: context.L.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: L.meshBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          // Wrap the scrollable content in a Size-bounded container to avoid layout errors
          SizedBox(
            height: MediaQuery.of(context).size.height *
                0.75, // Provide reasonable height for modal content
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.result.systemBusy)
                    _buildSmartAssistBanner(L)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),

                  // ── 1. Hero Magic Section ──────────────────
                  _buildHeroSection(L).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.95, 0.95),
                      curve: Curves.easeOutQuart),

                  const SizedBox(height: 20),

                  // ── 2. Safety Analytics (The "Aha" Moment) ──────────────────
                  _buildSafetyAdvisory(L)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideX(begin: 0.1),

                  const SizedBox(height: 12),

                  _buildMagicSummary(L)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideX(begin: -0.1),

                  const SizedBox(height: 16),

                  if (widget.result.bodyImpact != null) ...[
                    BodyImpactCard(
                      impact: widget.result.bodyImpact!,
                      onAskAIPressed: () {
                        // Create a temporary Medicine instance for the coach context
                        final tempMed = Medicine(
                          id: 0,
                          name: _nameController.text,
                          brand: _brandController.text,
                          dose: _doseController.text,
                          form: _formController.text,
                          category: widget.result.category,
                          count: 0,
                          totalCount: 0,
                          courseStartDate: todayStr(),
                          unit: _unitController.text,
                          intakeInstructions: _howController.text,
                        );
                        InlineAiCoach.show(context, tempMed,
                            impact: widget.result.bodyImpact);
                      },
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms)
                        .slideX(begin: -0.1),
                    const SizedBox(height: 32),
                  ],

                  // ── 3. Quick Actions ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildHeaderAction(Icons.share_rounded, () {
                        HapticEngine.selection();
                        ShareService.shareAchievement(
                            title: 'AI Scan Result',
                            subtitle: 'Checking ${_nameController.text}');
                      }, L),
                      const SizedBox(width: 8),
                      _buildHeaderAction(
                          Icons.help_outline_rounded, _showReviewHelp, L),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const SizedBox(height: 20),

                  // Main Title & Category (Now Editable)
                  // ── Hero Analysis Bento Grid ──────────────────
                  _StaggeredBentoGrid(
                    children: [
                      _BentoMetricTile(
                        flex: 2,
                        title: "ID_NAME",
                        icon: "📛",
                        child: _buildEditableField(
                          controller: _nameController,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          hint: "Medicine Name",
                          L: L,
                        ),
                      ),
                      _BentoMetricTile(
                        flex: 1,
                        title: "ID_BRAND",
                        icon: "🏷️",
                        child: _buildEditableField(
                          controller: _brandController,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          hint: "Brand",
                          L: L,
                        ),
                      ),
                      _BentoMetricTile(
                        flex: 1,
                        title: "ID_REQD_DOSE",
                        icon: "📏",
                        child: _buildEditableField(
                          controller: _doseController,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          hint: "Dose",
                          L: L,
                        ),
                      ),
                      _BentoMetricTile(
                        flex: 1,
                        title: "ID_FORM",
                        icon: "📦",
                        child: _buildEditableField(
                          controller: _formController,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          hint: "Form",
                          L: L,
                        ),
                      ),
                      _BentoMetricTile(
                        flex: 1,
                        title: "ID_UNIT",
                        icon: "⚖️",
                        child: _buildEditableField(
                          controller: _unitController,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          hint: "Unit",
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
                    emoji: "🏥",
                    controller: _pharmacyNameController,
                    L: L,
                    hint: "e.g. CVS, Walgreens (Optional)",
                  ),
                  _buildExpandableCard(
                    title: "Pharmacy Phone",
                    emoji: "📞",
                    controller: _pharmacyPhoneController,
                    L: L,
                    hint: "e.g. 555-0123 (Optional)",
                  ),
                  _buildExpandableCard(
                    title: "Rx Number",
                    emoji: "🆔",
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
                    emoji: "ℹ️",
                    controller: _descController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "How to Take",
                    emoji: "📖",
                    controller: _howController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "Side Effects",
                    emoji: "🤮",
                    controller: _sideEffectsController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "Interactions",
                    emoji: "🔀",
                    controller: _interactionsController,
                    L: L,
                    accentColor: context.L.text,
                  ),
                  _buildExpandableCard(
                    title: "Warnings",
                    emoji: "⚠️",
                    controller: _warningsController,
                    L: L,
                    accentColor: context.L.text,
                  ),

                  // Additional/Personal Notes
                  _buildExpandableCard(
                    title: "Personal Notes",
                    emoji: "📝",
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
                      border: Border.all(
                          color: L.border.withValues(alpha: 0.1), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleBtn(
                              "Auto suggested 🪄",
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

                      if (!AuthService.isLoggedIn) {
                        _showAuthPrompt(context);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: L.text,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: L.text.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("🔒", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 12),
                            Text(
                              "SECURE & FINALIZE",
                              style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: L.bg,
                                  letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAssistBanner(AppThemeColors L) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: L.text.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Text("✨", style: AppTypography.bodyLarge),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SMART ASSIST ACTIVE",
                    style: AppTypography.labelSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text("Verify detected details below.",
                    style: AppTypography.bodySmall
                        .copyWith(color: L.sub, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(
      IconData icon, VoidCallback onTap, AppThemeColors L) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.neumorphic,
        ),
        child: Icon(icon, size: 18, color: L.text.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildStatusBadge(bool identified, bool systemBusy) {
    final L = context.L;
    String label = identified ? "VERIFIED" : "MANUAL";
    String emoji = identified ? '✅' : '📝';
    Color color = L.text;

    if (systemBusy) {
      label = "SMART_ASSIST";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 10,
              )),
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
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyLarge
            .copyWith(color: L.text.withValues(alpha: 0.2)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
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

  // ── NEW PREMIUM UI COMPONENTS ──────────────────

  Widget _buildHeroSection(AppThemeColors L) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        image: widget.result.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.result.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.2), BlendMode.darken),
              )
            : null,
      ),
      child: Stack(
        children: [
          if (widget.result.imageUrl == null)
            const Center(child: Text('💊', style: TextStyle(fontSize: 64))),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: L.bg.withValues(alpha: 0.8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(widget.result.identified,
                              widget.result.systemBusy),
                          const Spacer(),
                          if (widget.result.confidence == 'high')
                            Text("⚡ 98% MATCH",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: L.text)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEditableField(
                        controller: _nameController,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        hint: "Medicine Name",
                        L: L,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicSummary(AppThemeColors L) {
    String summary = widget.result.ahaMoment ?? widget.result.description;
    if (summary.isEmpty) {
      summary =
          "Detected ${widget.result.name} ${widget.result.dose}. Tap to refine medical purpose.";
    }

    final bool isAha =
        widget.result.ahaMoment != null && widget.result.ahaMoment!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: L.text.withValues(alpha: 0.1), shape: BoxShape.circle),
            child:
                Text(isAha ? "💡" : "🧠", style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAha ? "AHA DISCOVERY" : "AI INSIGHT",
                    style: AppTypography.labelSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: AppTypography.bodyMedium.copyWith(
                      color: L.text, fontWeight: FontWeight.w700, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAdvisory(AppThemeColors L) {
    final isAntibiotic = widget.result.isAntibiotic;
    final hasWarning = widget.result.warnings.isNotEmpty ||
        widget.result.sideEffects.contains('severe') ||
        widget.result.sideEffects.contains('danger');

    if (!isAntibiotic && !hasWarning) return const SizedBox();

    final Color accent = isAntibiotic ? Colors.orangeAccent : Colors.redAccent;
    final String label =
        isAntibiotic ? "ANTIBIOTIC COURSE" : "MEDICAL ADVISORY";
    final String msg = isAntibiotic
        ? "Finish the entire course as prescribed. Do not skip doses."
        : "Safety concerns detected. Review warnings before finalize.";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(isAntibiotic ? "🧪" : "⚠️",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(label,
                  style: AppTypography.labelMedium.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(msg,
              style: AppTypography.bodySmall.copyWith(
                  color: L.text.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  height: 1.4)),
          if (isAntibiotic) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text("ℹ️", style: TextStyle(fontSize: 12, color: accent)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Completion is vital for effectiveness.",
                      style: AppTypography.labelSmall
                          .copyWith(color: accent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required String emoji,
    required TextEditingController controller,
    required AppThemeColors L,
    Color? accentColor,
    String? hint,
  }) {
    if (controller.text.isEmpty && title != "Personal Notes") {
      return const SizedBox();
    }

    final bool isDengerous = title == "Side Effects" ||
        title == "Warnings" ||
        title == "Interactions";
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: isDengerous
                      ? Colors.redAccent
                      : L.sub.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (isDengerous)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "DANGER",
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLines: null,
            style: AppTypography.bodyMedium.copyWith(
              color: L.text,
              height: 1.6,
              fontWeight: isDengerous ? FontWeight.w800 : FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodySmall
                  .copyWith(color: L.sub.withValues(alpha: 0.3)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.neumorphic,
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
          color: active ? L.text : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? null : AppShadows.neumorphic,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelLarge.copyWith(
            color: active ? L.bg : L.sub,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoScheduleView(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1),
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
                  id: 'man_${DateTime.now().millisecondsSinceEpoch}',
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
              color: L.card,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: L.border.withValues(alpha: 0.1), width: 1),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.neumorphic,
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
          color: context.L.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
              color: context.L.border.withValues(alpha: 0.1), width: 1),
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

class _BentoMetricTile extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;
  final int flex;

  const _BentoMetricTile({
    required this.title,
    required this.icon,
    required this.child,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Flexible(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Text(
                  title.replaceFirst('ID_', '').toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StaggeredBentoGrid extends StatelessWidget {
  final List<Widget> children;
  const _StaggeredBentoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [children[0]]), // Large title tile
        const SizedBox(height: 4),
        Row(
          children: [
            children[1], // Brand
            children[2], // Dose
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            children[3], // Form
            children[4], // Unit
          ],
        ),
      ],
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
          color: context.L.text.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: L.border, width: 1),
        ),
        child: Icon(icon, size: 20, color: L.text),
      ),
    );
  }
}

class _ProScanFramePainter extends CustomPainter {
  final String category;
  _ProScanFramePainter({required this.category});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double len = 20.0;

    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom Left
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);

    // Center Crosshair
    const double crossLen = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(center.dx - crossLen, center.dy),
        Offset(center.dx + crossLen, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - crossLen),
        Offset(center.dx, center.dy + crossLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanFramePainter extends CustomPainter {
  final String category;
  final Color primaryColor;
  ScanFramePainter({required this.category, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Focus Overlay (Glass Look)
    final rectPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(32)),
        rectPaint);

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
    const cornerSize = 40.0;
    const padding = 20.0;
    final path = Path();

    // Top Left
    path.moveTo(padding, padding + cornerSize);
    path.lineTo(padding, padding);
    path.lineTo(padding + cornerSize, padding);

    // Top Right
    path.moveTo(size.width - padding - cornerSize, padding);
    path.lineTo(size.width - padding, padding);
    path.lineTo(size.width - padding, padding + cornerSize);

    // Bottom Left
    path.moveTo(padding, size.height - padding - cornerSize);
    path.lineTo(padding, size.height - padding);
    path.lineTo(padding + cornerSize, size.height - padding);

    // Bottom Right
    path.moveTo(size.width - padding - cornerSize, size.height - padding);
    path.lineTo(size.width - padding, size.height - padding);
    path.lineTo(size.width - padding, size.height - padding - cornerSize);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _paintLiquidFrame(
      Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2.5, glowPaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2.5, paint);
  }

  void _paintSprayFrame(
      Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    final center = Offset(size.width / 2, size.height / 2);
    const armSize = 30.0;
    const gap = 30.0;
    final path = Path();

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
    const inset = 40.0;
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
