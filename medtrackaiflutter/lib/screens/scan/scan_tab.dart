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
import '../../core/utils/date_formatter.dart';

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

  late AnimationController _scanLineController;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tablet', 'icon': Icons.medication_rounded},
    {'name': 'Liquid', 'icon': Icons.water_drop_rounded},
    {'name': 'Spray', 'icon': Icons.air_rounded},
    {'name': 'Beauty', 'icon': Icons.auto_awesome_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
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

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
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

  Future<void> _processImage(File file) async {
    setState(() {
      _imageFile = file;
      _isScanning = true;
    });

    final response = await GeminiService.scanMedicine(file);

    if (!mounted) return;

    response.fold(
      (success) {
        setState(() {
          _isScanning = false;
        });
        _showResultModal(
            success.copyWith(imageUrl: file.path, category: _selectedCategory));
      },
      (failure) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
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
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Scan Frame Brackets
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 60), // Offset slightly up
              width: size.width * 0.78,
              height: size.width * 0.78,
              child: CustomPaint(
                painter: ScanFramePainter(category: _selectedCategory),
                child: _buildScanningLine(),
              ),
            ),
          ),

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
          ),

          // 4. Bottom Controls Cluster (Category + Shutter)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 90,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCategoryPill(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _buildBottomControls(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image Preview with Glow
            if (_imageFile != null)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA3E635).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 40),
            // Ghost Character
            Image.asset(
              'assets/images/ghost_scan.png',
              width: 120,
              errorBuilder: (c, e, s) => const Icon(
                  Icons.face_retouching_natural,
                  size: 80,
                  color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const Text(
              "Analysing medicine...",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Identifying pill type, dose, and name",
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
          ],
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
              color: const Color(0xFFA3E635),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA3E635).withValues(alpha: 0.8),
                  blurRadius: 20,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: const Color(0xFFA3E635).withValues(alpha: 0.4),
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
            color: const Color(0xFFA3E635)
                .withValues(alpha: 1.0 - _scanLineController.value),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA3E635)
                  .withValues(alpha: 0.3 * (1.0 - _scanLineController.value)),
              blurRadius: 20,
              spreadRadius: 10,
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
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFA3E635),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0xFFA3E635), blurRadius: 8)],
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
              color: const Color(0xFFA3E635).withValues(alpha: 1.0 - animValue),
              size: 20 * (1.0 - animValue),
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
                  onTap: () => setState(() => _selectedCategory = cat['name']),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircularBlurBtn(
          icon: Icons.image_outlined,
          onTap: _pickFromGallery,
        ),
        GestureDetector(
          onTap: _capturePhoto,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
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
          ),
        ),
        _buildCircularBlurBtn(
          icon: Icons.flash_off_rounded,
          onTap: () {},
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
  int _count = 30;
  List<ScheduleEntry> _manualSchedule = [
    ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [1, 2, 3, 4, 5, 6, 0]),
  ];
  bool _useAutoSchedule = true;

  @override
  void initState() {
    super.initState();
    // Simplified schedule (March 11th style)
    _manualSchedule = [
      ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [1, 2, 3, 4, 5, 6, 0]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.85),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: L.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Header Icon & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA3E635).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Color(0xFFA3E635), size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Identified",
                        style: TextStyle(
                          color: Color(0xFFA3E635),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Review & Confirm",
                  style: TextStyle(
                      color: L.text.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Med Card
            Text(
              "💊 ${widget.result.name}",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: L.text,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChip("🏷️ ${widget.result.brand}", L),
                const SizedBox(width: 8),
                _buildChip("📊 ${widget.result.dose}", L),
              ],
            ),
            const SizedBox(height: 24),


            // Dosing Schedule Section
            Text(
              "⏰ Dosing Schedule",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: L.text),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleBtn("Auto Magic ✨", _useAutoSchedule,
                        () => setState(() => _useAutoSchedule = true), L),
                  ),
                  Expanded(
                    child: _buildToggleBtn("Manual ⚙️", !_useAutoSchedule,
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

            const Divider(height: 48),

            // Quantity Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Inventory",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: L.text)),
                    Text("Total Pill Count",
                        style: TextStyle(
                            fontSize: 12,
                            color: L.text.withValues(alpha: 0.5))),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _ModalQtyBtn(
                        icon: Icons.remove,
                        onTap: () =>
                            setState(() => _count = (_count - 1).clamp(1, 999)),
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          "$_count",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: L.text),
                        ),
                      ),
                      _ModalQtyBtn(
                        icon: Icons.add,
                        onTap: () => setState(() => _count++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  final med = Medicine(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: widget.result.name,
                    brand: widget.result.brand,
                    dose: widget.result.dose,
                    form: widget.result.form,
                    category: widget.result.category,
                    count: _count,
                    totalCount: _count,
                    imageUrl: widget.result.imageUrl,
                    notes: widget.result.description,
                    courseStartDate: todayStr(),
                    schedule: _manualSchedule,
                  );
                  widget.onSave(med);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA3E635),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  "Confirm & Add Schedule",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: L.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: L.text.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w700),
      ),
    );
  }


  Widget _buildToggleBtn(
      String label, bool active, VoidCallback onTap, AppThemeColors L) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? L.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? L.text : L.text.withValues(alpha: 0.5),
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoScheduleView(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA3E635).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFA3E635).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded,
                  color: Color(0xFFA3E635), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI suggested a standard course based on this medicine type.",
                  style: TextStyle(
                      color: L.text.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._manualSchedule.map((s) => _buildScheduleItem(s, L)),
        ],
      ),
    );
  }

  Widget _buildManualScheduleView(AppThemeColors L) {
    return Column(
      children: [
        ..._manualSchedule.map((s) => _buildScheduleItem(s, L)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _manualSchedule.add(ScheduleEntry(
                  h: 12, m: 0, label: 'Custom', days: [1, 2, 3, 4, 5, 6, 0]));
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: L.border, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 20, color: L.text.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text("Add Reminder Time",
                    style: TextStyle(
                        color: L.text.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleEntry s, AppThemeColors L) {
    final timeStr =
        "${s.h.toString().padLeft(2, '0')}:${s.m.toString().padLeft(2, '0')}";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled_rounded,
                  color: L.text.withValues(alpha: 0.3), size: 18),
              const SizedBox(width: 12),
              Text(
                s.label,
                style: TextStyle(
                    color: L.text, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          Text(
            timeStr,
            style: TextStyle(
                color: L.text, fontWeight: FontWeight.w900, fontSize: 16),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: L.border),
        ),
        child: Icon(icon, size: 20, color: L.text),
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

    switch (category) {
      case 'Liquid':
        _paintLiquidFrame(canvas, size, paint);
        break;
      case 'Spray':
        _paintSprayFrame(canvas, size, paint);
        break;
      case 'Beauty':
        _paintBeautyFrame(canvas, size, paint);
        break;
      default:
        _paintTabletFrame(canvas, size, paint);
    }
  }

  void _paintTabletFrame(Canvas canvas, Size size, Paint paint) {
    const cornerSize = 48.0;
    // Top Left
    canvas.drawPath(
        Path()
          ..moveTo(0, cornerSize)
          ..lineTo(0, 0)
          ..lineTo(cornerSize, 0),
        paint);
    // Top Right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - cornerSize, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, cornerSize),
        paint);
    // Bottom Left
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - cornerSize)
          ..lineTo(0, size.height)
          ..lineTo(cornerSize, size.height),
        paint);
    // Bottom Right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - cornerSize, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - cornerSize),
        paint);
  }

  void _paintLiquidFrame(Canvas canvas, Size size, Paint paint) {
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  void _paintSprayFrame(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);
    const armSize = 30.0;
    const gap = 10.0;

    // Crosshair arms
    canvas.drawLine(
        Offset(center.dx, gap), Offset(center.dx, gap + armSize), paint);
    canvas.drawLine(Offset(center.dx, size.height - gap),
        Offset(center.dx, size.height - gap - armSize), paint);
    canvas.drawLine(
        Offset(gap, center.dy), Offset(gap + armSize, center.dy), paint);
    canvas.drawLine(Offset(size.width - gap, center.dy),
        Offset(size.width - gap - armSize, center.dy), paint);
  }

  void _paintBeautyFrame(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    const inset = 20.0;
    path.moveTo(size.width / 2, inset);
    path.quadraticBezierTo(
        size.width - inset, inset, size.width - inset, size.height / 2);
    path.quadraticBezierTo(size.width - inset, size.height - inset,
        size.width / 2, size.height - inset);
    path.quadraticBezierTo(inset, size.height - inset, inset, size.height / 2);
    path.quadraticBezierTo(inset, inset, size.width / 2, inset);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.category != category;
}
