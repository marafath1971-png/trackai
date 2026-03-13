import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/scan_result.dart';
import '../../theme/app_theme.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../core/utils/date_formatter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../widgets/common/modern_time_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await _controller!.initialize();
        await _controller!.setFlashMode(_flashMode);
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Camera initialization error: $e');
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
      HapticFeedback.selectionClick();
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

    try {
      HapticFeedback.mediumImpact();
      final XFile image = await _controller!.takePicture();
      _processImage(File(image.path));
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _processImage(File(image.path));
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, "${DateTime.now().millisecondsSinceEpoch}_comp.jpg");
    
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
    setState(() {
      _imageFile = file;
      _isScanning = true;
      _scanStep = 0;
    });

    // Cycle through scan steps for animation
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted || !_isScanning) return false;
      setState(() => _scanStep = (_scanStep + 1) % _scanSteps.length);
      return _isScanning;
    });

    final compressedFile = await _compressImage(file);
    final fileToScan = compressedFile ?? file;
    
    final response = await GeminiService.scanMedicine(fileToScan);

    if (!mounted) return;

    response.fold(
      (success) {
        setState(() => _isScanning = false);
        _showResultModal(success.copyWith(
          imageUrl: file.path, 
          category: _selectedCategory,
          description: success.name
        ));
      },
      (failure) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Scan Error: ${failure.message}"),
            backgroundColor: context.L.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
            if (widget.onScanAdded != null) widget.onScanAdded!();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) return _buildAnalyzingState();

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-screen Camera Preview
          if (_isCameraInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Scan Frame Brackets
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 100), // Offset slightly up
              width: size.width * 0.8,
              height: size.width * 0.8,
              child: CustomPaint(
                painter: ScanFramePainter(category: _selectedCategory),
                child: _buildScanningLine(),
              ),
            ),
          ).animate().scale(begin: const Offset(0.9, 0.9), delay: 200.ms),

          // 3. Header Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: _buildHeader(),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2, end: 0),

          // 4. Bottom Controls Cluster (Category + Shutter)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120, // Raised to avoid nav bar overlap
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCategoryPill(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _buildBottomControls(),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image Preview with animated glow
                if (_imageFile != null)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final glow = 0.2 + _pulseController.value * 0.4;
                      return Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA3E635).withValues(alpha: glow),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),

                // Logo / Ghost
                Image.asset(
                  'assets/images/ghost_scan.png',
                  width: 80,
                  errorBuilder: (c, e, s) => const Text('🤖', style: TextStyle(fontSize: 64)),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 900.ms),

                const SizedBox(height: 32),

                // Step indicator text (animated transition)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    '${_scanStepIcons[_scanStep]}  ${_scanSteps[_scanStep]}',
                    key: ValueKey(_scanStep),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Step progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_scanSteps.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _scanStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _scanStep
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Step list
                ...List.generate(_scanSteps.length, (i) {
                  final done = i < _scanStep;
                  final active = i == _scanStep;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: done || active ? 1.0 : 0.25,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? Colors.white
                                  : active
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: done || active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.1),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                                  : active
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text('${i + 1}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _scanSteps[i],
                            style: TextStyle(
                              color: done || active ? Colors.white : Colors.white38,
                              fontSize: 14,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
          left: 10,
          right: 10,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 20,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
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
            color: Colors.white
                .withValues(alpha: 0.8 * (1.0 - _scanLineController.value)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white
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
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 4)],
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Small Ghost Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/images/ghost_scan.png',
              width: 24,
              errorBuilder: (c, e, s) =>
                  const Text("👻", style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
        const Text(
          "Scanner",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        _buildCircularBlurBtn(
          icon: Icons.close,
          onTap: widget.onClose ?? () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildCircularBlurBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat['name']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 6),
                          Text(
                            cat['name'],
                            style: const TextStyle(
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
        _buildCircularBlurBtn(
          icon: Icons.image_outlined,
          onTap: _pickFromGallery,
        ),
        const SizedBox(width: 40), // Added spacing
        GestureDetector(
          onTap: _capturePhoto,
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
              .shimmer(delay: 2000.ms, duration: 1500.ms, color: Colors.white24),
        ),
        const SizedBox(width: 40), // Added spacing
        _buildCircularBlurBtn(
          icon: flashIcon,
          onTap: _toggleFlash,
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
  
  // Clinical Controllers
  late TextEditingController _descController;
  late TextEditingController _howController;
  late TextEditingController _sideEffectsController;
  late TextEditingController _interactionsController;
  late TextEditingController _warningsController;
  late TextEditingController _additionalController; // NEW

  @override
  void initState() {
    super.initState();
    _count = widget.result.pillCount > 0 ? widget.result.pillCount : 30;

    _nameController = TextEditingController(text: widget.result.name);
    _brandController = TextEditingController(text: widget.result.brand);
    _doseController = TextEditingController(text: widget.result.dose);
    _formController = TextEditingController(text: widget.result.form);
    
    _descController = TextEditingController(text: widget.result.description);
    _howController = TextEditingController(text: "${widget.result.howToTake}\n\n${widget.result.whenToTake}");
    _sideEffectsController = TextEditingController(text: widget.result.sideEffects);
    _interactionsController = TextEditingController(text: widget.result.interactions);
    _warningsController = TextEditingController(text: widget.result.warnings);
    _additionalController = TextEditingController();

    // Convert ScanResult slots to ScheduleEntry entities
    if (widget.result.scheduleSlots.isNotEmpty) {
      _manualSchedule = widget.result.scheduleSlots.map((s) => ScheduleEntry(
        h: s['h'] ?? 8,
        m: s['m'] ?? 0,
        label: s['label'] ?? 'Reminder',
        days: List<int>.from(s['days'] ?? [0, 1, 2, 3, 4, 5, 6]),
      )).toList();
    } else {
      _manualSchedule = [
        ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [0, 1, 2, 3, 4, 5, 6]),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _doseController.dispose();
    _formController.dispose();
    _descController.dispose();
    _howController.dispose();
    _sideEffectsController.dispose();
    _interactionsController.dispose();
    _warningsController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  void _showAuthPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFA3E635).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 24),
            const Text(
              "Secure Your Data",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Sign in now to sync your medicines and never lose your streak. It only takes a second.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthService.signInWithGoogle();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("G", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.L.text)),
                    SizedBox(width: 12),
                    Text("Continue with Google", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Maybe Later",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showReviewHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFFA3E635)),
            SizedBox(width: 12),
            Expanded(child: Text("Everything is editable! Tap any text field to correct or add details.")),
          ],
        ),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.9),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
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
                  // Verification Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(widget.result.identified),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showReviewHelp();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: L.fill,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Review Details",
                                style: TextStyle(
                                  color: L.text.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.help_outline_rounded, size: 14, color: L.text.withValues(alpha: 0.3)),
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
                    hint: "Medicine Name",
                    L: L,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildEditableChip(controller: _brandController, icon: "🏢", hint: "Brand", L: L)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEditableChip(controller: _doseController, icon: "⚡", hint: "Dose", L: L)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEditableChip(controller: _formController, icon: "📦", hint: "Form", L: L)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Info Sections
                  _buildSectionHeader("ℹ️ CLINICAL INFO", L),
                  _buildExpandableCard(
                    title: "Medical Purpose",
                    icon: Icons.info_outline_rounded,
                    controller: _descController,
                    L: L,
                    accentColor: const Color(0xFFA3E635),
                  ),
                  _buildExpandableCard(
                    title: "How to Take",
                    icon: Icons.menu_book_rounded,
                    controller: _howController,
                    L: L,
                    accentColor: const Color(0xFFA3E635),
                  ),
                  _buildExpandableCard(
                    title: "Side Effects",
                    icon: Icons.error_outline_rounded,
                    controller: _sideEffectsController,
                    L: L,
                    accentColor: const Color(0xFFA3E635),
                  ),
                  _buildExpandableCard(
                    title: "Interactions",
                    icon: Icons.swap_calls_rounded,
                    controller: _interactionsController,
                    L: L,
                    accentColor: const Color(0xFFA3E635),
                  ),
                  _buildExpandableCard(
                    title: "Warnings",
                    icon: Icons.warning_amber_rounded,
                    controller: _warningsController,
                    L: L,
                    accentColor: const Color(0xFFA3E635),
                  ),

                  // Additional/Personal Notes
                  _buildExpandableCard(
                    title: "Personal Notes",
                    icon: Icons.note_add_rounded,
                    controller: _additionalController,
                    L: L,
                    accentColor: const Color(0xFFA3E635),
                    hint: "Add any special instructions or doctor's notes here...",
                  ),

                  const SizedBox(height: 24),

                  // Dosing Logic Section
                  _buildSectionHeader("⏰ REMINDER SCHEDULE", L),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleBtn("Auto suggested ✨", _useAutoSchedule,
                              () => setState(() => _useAutoSchedule = true), L),
                        ),
                        Expanded(
                          child: _buildToggleBtn("Manual config ⚙️", !_useAutoSchedule,
                              () => setState(() => _useAutoSchedule = false), L),
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
                  _buildSectionHeader("📦 INVENTORY", L),
                  const SizedBox(height: 16),
                  _buildInventorySelector(L),

                  const SizedBox(height: 48),

                  // Primary Action
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
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
                          notes: "PURPOSE:\n${_descController.text}\n\nINSTRUCTIONS:\n${_howController.text}\n\nWARNINGS:\n${_warningsController.text}\n\nNOTES:\n${_additionalController.text}",
                          courseStartDate: todayStr(),
                          schedule: _manualSchedule,
                        );
                        widget.onSave(med);

                        // If NOT logged in, show auth prompt
                        if (!AuthService.isLoggedIn) {
                          _showAuthPrompt(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA3E635),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded),
                          SizedBox(width: 12),
                          Text(
                            "Confirm & Save Medicine",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(delay: 3.seconds, duration: 2.seconds, color: Colors.white24),
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

  Widget _buildStatusBadge(bool identified) {
    final color = const Color(0xFFA3E635);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: identified ? color.withValues(alpha: 0.15) : Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: identified ? color.withValues(alpha: 0.3) : Colors.black26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(identified ? Icons.verified_rounded : Icons.help_center_rounded,
              color: identified ? color : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            identified ? "AI VERIFIED" : "MANUAL REVIEW",
            style: TextStyle(
              color: identified ? color : Colors.grey,
              fontSize: 11,
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
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: L.text,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: L.text.withValues(alpha: 0.2)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: L.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: L.text.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: L.text.withValues(alpha: 0.2)),
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

  Widget _buildRichChip(String text, AppThemeColors L) {
    if (text.endsWith(' ') || text.trim().length <= 2) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: L.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: L.text.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeColors L) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: L.text.withValues(alpha: 0.4),
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
    if (controller.text.isEmpty && title != "Personal Notes") return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor ?? L.text.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
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
            style: TextStyle(
              color: L.text.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: L.text.withValues(alpha: 0.2)),
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
        color: L.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Quantity",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.text)),
              Text("Total supply detected",
                  style: TextStyle(
                      fontSize: 12,
                      color: L.text.withValues(alpha: 0.4))),
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
                style: TextStyle(
                  fontSize: 24,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? L.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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
          style: TextStyle(
            color: active ? L.text : L.text.withValues(alpha: 0.4),
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoScheduleView(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFA3E635).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA3E635).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA3E635), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI suggested schedule by frequency",
                  style: TextStyle(
                    color: L.text.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._manualSchedule.asMap().entries.map((e) => _buildScheduleItem(e.key, e.value, L)),
        ],
      ),
    );
  }

  Widget _buildManualScheduleView(AppThemeColors L) {
    return Column(
      children: [
        ..._manualSchedule.asMap().entries.map((e) => _buildScheduleItem(e.key, e.value, L)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _manualSchedule.add(ScheduleEntry(
                  h: 12, m: 0, label: _getAutoLabel(12), days: [0, 1, 2, 3, 4, 5, 6]));
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_time_rounded,
                    size: 20, color: L.text.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Text("Add custom time",
                    style: TextStyle(
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

  Widget _buildScheduleItem(int idx, ScheduleEntry s, AppThemeColors L) {
    final timeStr =
        "${s.h.toString().padLeft(2, '0')}:${s.m.toString().padLeft(2, '0')}";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
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
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: L.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: L.border.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded, color: Color(0xFFA3E635), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
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
                  Text(
                    s.label.toUpperCase(),
                    style: TextStyle(
                      color: L.sub,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Daily Reminder",
                    style: TextStyle(
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
            icon: Icon(Icons.remove_circle_outline_rounded, color: L.red.withValues(alpha: 0.7)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: L.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: L.border.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 22, color: L.text),
      ),
    );
  }
}


class ScanFramePainter extends CustomPainter {
  final String category;
  ScanFramePainter({required this.category});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);


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

  void _paintTabletFrame(Canvas canvas, Size size, Paint paint, Paint glowPaint) {
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

  void _paintLiquidFrame(Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2.2, glowPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2.2, paint);
  }

  void _paintSprayFrame(Canvas canvas, Size size, Paint paint, Paint glowPaint) {
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

  void _paintBeautyFrame(Canvas canvas, Size size, Paint paint, Paint glowPaint) {
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
