import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/unified_header.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../widgets/common/mesh_gradient.dart';
import 'widgets/body_impact_card.dart';
import 'widgets/inline_ai_coach.dart';
// ══════════════════════════════════════════════════════════════════════
// MEDICINE DETAIL SCREEN (Cal AI Industrial Hub Refined)
// ══════════════════════════════════════════════════════════════════════

class MedicineDetailScreen extends StatefulWidget {
  final int medId;
  final VoidCallback onBack;
  final bool initialEditMode;

  const MedicineDetailScreen({
    super.key,
    required this.medId,
    required this.onBack,
    this.initialEditMode = false,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late bool _editMode;
  late Map<String, dynamic> _editFields;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _editMode = widget.initialEditMode;
    _resetEdit();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetEdit() {
    final state = Provider.of<AppState>(context, listen: false);
    final med = state.meds.firstWhere((m) => m.id == widget.medId,
        orElse: () => state.meds.first);
    _editFields = {
      'name': med.name,
      'brand': med.brand,
      'dose': med.dose,
      'form': med.form,
      'category': med.category,
      'notes': med.notes,
      'count': med.count.toString(),
      'totalCount': med.totalCount.toString(),
      'refillAt': med.refillAt.toString(),
      'intakeInstructions': med.intakeInstructions,
      'pharmacyName': med.refillInfo?.pharmacyName ?? '',
      'pharmacyPhone': med.refillInfo?.pharmacyPhone ?? '',
      'rxNumber': med.refillInfo?.rxNumber ?? '',
      'price': med.price?.toString() ?? '',
      'currency': med.currency ?? '',
      'color': med.color,
    };
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final med = context.select<AppState, Medicine>((state) => state.meds
        .firstWhere((m) => m.id == widget.medId,
            orElse: () =>
                state.meds.isNotEmpty ? state.meds.first : Medicine.empty()));

    if (med.id == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onBack());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final adherence = context
        .select<AppState, int>((s) => s.getAdherenceForMed(widget.medId));
    final historyCount = context.select<AppState, ({int taken, int total})>(
        (s) => s.getHistoryCountForMed(widget.medId));
    final medColor = hexToColor(med.color);

    return Scaffold(
      backgroundColor: L.meshBg,
      body: Stack(
        children: [
          _editMode
              ? _buildEditMode(med, L)
              : _buildViewMode(med, adherence, historyCount, medColor, L),
        ],
      ),
    );
  }

  Widget _buildViewMode(Medicine med, int adherence,
      ({int taken, int total}) historyCount, Color medColor, AppThemeColors L) {
    return RawScrollbar(
      controller: _scrollController,
      thumbColor: L.text.withValues(alpha: 0.1),
      radius: const Radius.circular(10),
      thickness: 4,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverHeader(med, medColor, L),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (med.intakeInstructions.isNotEmpty &&
                      med.intakeInstructions != 'None') ...[
                    _buildIntakeChip(med.intakeInstructions, L),
                    const SizedBox(height: 24),
                  ],
                  _buildBentoMetrics(med, adherence, L),
                  const SizedBox(height: 16),
                  _buildQuickActions(med, context.read<AppState>(), L),
                  const SizedBox(height: 24),

                  if (med.aiSafetyProfile != null && (med.aiSafetyProfile!.mechanismOfAction.isNotEmpty && med.aiSafetyProfile!.mechanismOfAction != 'Details about how this medication works in your body will appear here.')) ...[
                    Builder(builder: (context) {
                      final impact = BodyImpactSummary(
                        mechanismOfAction: med.aiSafetyProfile!.mechanismOfAction,
                        onsetMinutes: med.aiSafetyProfile!.onsetMinutes,
                        peakHours: med.aiSafetyProfile!.peakHours,
                        durationHours: med.aiSafetyProfile!.durationHours,
                        bodySystems: med.aiSafetyProfile!.bodySystems,
                        timelineEffects: med.aiSafetyProfile!.timelineEffects,
                        ahaFacts: med.aiSafetyProfile!.ahaFacts,
                      );
                      return BodyImpactCard(
                        impact: impact,
                        onAskAIPressed: () => InlineAiCoach.show(context, med, impact: impact),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
                    }),
                    const SizedBox(height: 24),
                  ],

                  _buildSafetyPanel(med, L),
                  const SizedBox(height: 24),
                  _buildHistorySection(med, adherence, historyCount.taken,
                      historyCount.total, L),
                  const SizedBox(height: 24),
                  _buildScheduleSection(med, context.read<AppState>(), L),
                  const SizedBox(height: 24),
                  _buildSpecificationsSection(med, L),
                  const SizedBox(height: 24),
                  _buildSettingsSection(med, context.read<AppState>(), L),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(Medicine med, AppThemeColors L) {
    return Column(
      children: [
        // ── SYSTEM BREADCRUMB HEADER ──
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
          decoration: BoxDecoration(
            color: L.meshBg,
            border: Border(
                bottom: BorderSide(
                    color: L.text.withValues(alpha: 0.05), width: 0.5)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Text('MEDICINE',
                      style: AppTypography.labelSmall.copyWith(
                          color: L.text.withValues(alpha: 0.8),
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/',
                        style: TextStyle(
                            color: L.sub.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ),
                  Text('EDIT DETAILS',
                      style: AppTypography.labelSmall.copyWith(
                          color: L.primary,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                ]),
              ),
              UnifiedHeader(
                title: med.name,
                showBack: false,
                actions: [
                  HeaderActionBtn(
                    child: const Text('✕', style: TextStyle(fontSize: 18)),
                    onTap: () {
                      HapticEngine.selection();
                      setState(() {
                        _resetEdit();
                        _editMode = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: RawScrollbar(
            controller: _scrollController,
            thumbColor: L.text.withValues(alpha: 0.1),
            radius: const Radius.circular(10),
            thickness: 4,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                children: [
                  _buildEditForm(med, context.read<AppState>(), L),
                ],
              ),
            ),
          ),
        ),

        // ── SAVE ACTION BAR ──
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: L.meshBg,
            border: Border(
                top: BorderSide(
                    color: L.text.withValues(alpha: 0.05), width: 0.5)),
          ),
          child: BouncingButton(
            onTap: () {
              HapticEngine.success();
              _save(med, context.read<AppState>());
            },
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.neumorphic,
              ),
              child: Center(
                child: Text('SAVE CHANGES',
                    style: AppTypography.labelLarge.copyWith(
                        color: L.bg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader(Medicine med, Color medColor, AppThemeColors L) {
    return SliverAppBar(
      expandedHeight: 380,
      backgroundColor: L.meshBg,
      elevation: 0,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      title: _scrollController.hasClients && _scrollController.offset > 240
          ? Text(med.name.toUpperCase(),
              style: AppTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0))
          : null,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          children: [
            // Atmospheric Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      medColor.withValues(alpha: 0.15),
                      L.meshBg,
                    ],
                  ),
                ),
              ),
            ),

            // Mesh Layer
            Positioned.fill(
                child: MeshGradient(
                    colors: [L.meshBg, medColor.withValues(alpha: 0.05)])),

            // Hero Content
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'med_${med.id}',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: AppRadius.roundSquircle,
                        border: Border.all(
                            color: L.border.withValues(alpha: 0.1), width: 0.5),
                        boxShadow: AppShadows.neumorphic,
                      ),
                      child: MedImage(
                        imageUrl: med.imageUrl,
                        width: 140,
                        height: 140,
                        borderRadius: 28,
                        placeholder: Center(
                          child: Text(
                            _getCategoryEmoji(med.category),
                            style: const TextStyle(fontSize: 56),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: L.text,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      med.brand.isNotEmpty
                          ? med.brand.toUpperCase()
                          : 'GENERIC_SPEC',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.bg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      med.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 16),
        alignment: Alignment.centerLeft,
        child: HeaderActionBtn(
          onTap: widget.onBack,
          child: const Text('←', style: TextStyle(fontSize: 20)),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          alignment: Alignment.centerRight,
          child: HeaderActionBtn(
            onTap: () {
              HapticEngine.selection();
              setState(() {
                _resetEdit();
                _editMode = true;
              });
            },
            child: const Text('🖊️', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyPanel(Medicine med, AppThemeColors L) {
    final isAntibiotic = med.category.toLowerCase().contains('antibiotic');
    if (!isAntibiotic) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: AppShadows.neumorphic,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Text(
              "🛡️",
              style: TextStyle(
                fontSize: 140,
                color: L.bg.withValues(alpha: 0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "PROTOCOL",
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ANTIBIOTIC DETECTED',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: L.text.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MANDATORY COURSE COMPLETION',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: L.text,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This medication must be finished entirely. Do not stop early, even if symptoms vanish. Pathogens can remain and build resistance.',
                        style: AppTypography.bodySmall.copyWith(
                          color: L.text.withValues(alpha: 0.7),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: L.text.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: L.text.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Text("🛡️", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Safety measure active: Completing the full course prevents antibiotic resistance.",
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.text.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetrics(Medicine med, int adherence, AppThemeColors L) {
    final pct =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final nextDose = _getNextDoseTime(med.schedule);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DiagnosticCard(
                label: 'ADHERENCE',
                value: adherence == -1 ? '••' : '$adherence%',
                icon: '📈',
                color: L.text,
                L: L,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DiagnosticCard(
                label: 'NEXT_DOSE',
                value: nextDose,
                icon: '⏱️',
                color: L.text,
                L: L,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DiagnosticCard(
          label: 'INVENTORY_RESERVE',
          value: '${med.count} UNITS',
          icon: '📦',
          color: L.text,
          L: L,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STOCK_LEVEL',
                      style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: L.sub.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w900)),
                  Text('${(pct * 100).toInt()}%',
                      style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: L.text,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              _ModernStockBar(pct: pct, isLow: med.count <= med.refillAt, L: L),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Medicine med, AppState state, AppThemeColors L) {
    final isLow = med.count <= med.refillAt;
    return Row(
      children: [
        // ── RESTOCK ──
        Expanded(
          child: BouncingButton(
            onTap: () => _showRestockSheet(med, state, L),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isLow
                    ? Colors.orange.withValues(alpha: 0.08)
                    : L.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLow
                      ? Colors.orange.withValues(alpha: 0.3)
                      : L.border.withValues(alpha: 0.08),
                  width: isLow ? 1.0 : 0.5,
                ),
                boxShadow: AppShadows.neumorphic,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isLow ? '📦' : '🔄',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    isLow ? 'RESTOCK' : 'RESTOCK',
                    style: AppTypography.labelSmall.copyWith(
                      color: isLow ? Colors.orange : L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (isLow)
                    Text(
                      'LOW SUPPLY',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.orange.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── LOG FLEXIBLE DOSE ──
        Expanded(
          child: BouncingButton(
            onTap: () {
              HapticEngine.doseTaken();
              state.logPrnDose(
                med.id,
                'Flexible Dose',
                TimeOfDay.now().format(context),
              );
              state.showToast('Flexible dose logged ✓');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: L.border.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                boxShadow: AppShadows.neumorphic,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💊', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    'LOG DOSE',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'AS NEEDED',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRestockSheet(Medicine med, AppState state, AppThemeColors L) {
    HapticEngine.selection();
    int addAmount = 30;
    showModalBottomSheet(
      context: context,
      backgroundColor: L.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: L.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 28),
                Text('RESTOCK INVENTORY',
                    style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: L.text,
                        letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Add units to ${med.name}',
                    style: AppTypography.bodySmall
                        .copyWith(color: L.sub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RestockBtn(
                      label: '− 10',
                      onTap: () =>
                          setSheetState(() => addAmount = (addAmount - 10).clamp(10, 365)),
                      L: L,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text('$addAmount',
                            style: AppTypography.displayLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: L.text,
                                fontSize: 52,
                                letterSpacing: -2.0)),
                        Text('UNITS',
                            style: AppTypography.labelSmall.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                fontSize: 10)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    _RestockBtn(
                      label: '+ 10',
                      onTap: () =>
                          setSheetState(() => addAmount = (addAmount + 10).clamp(10, 365)),
                      L: L,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                BouncingButton(
                  onTap: () {
                    HapticEngine.success();
                    final newCount = med.count + addAmount;
                    state.updateMedicine(med.copyWith(count: newCount));
                    state.showToast('+$addAmount units added ✓');
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: L.text,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text('CONFIRM RESTOCK',
                          style: AppTypography.labelLarge.copyWith(
                              color: L.bg,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNextDoseTime(List<ScheduleEntry> schedule) {
    if (schedule.isEmpty) return '--:--';
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;

    final sorted = List<ScheduleEntry>.from(schedule)
      ..sort((a, b) => (a.h * 60 + a.m).compareTo(b.h * 60 + b.m));

    for (var s in sorted) {
      if (s.h * 60 + s.m > nowMins) {
        return '${s.h.toString().padLeft(2, '0')}:${s.m.toString().padLeft(2, '0')}';
      }
    }
    return '${sorted.first.h.toString().padLeft(2, '0')}:${sorted.first.m.toString().padLeft(2, '0')}';
  }

  Widget _buildIntakeChip(String intake, AppThemeColors L) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🍽️", style: TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Text(intake.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    fontSize: 11,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            label: 'FREQUENCY_MATRIX',
            icon: '⏰',
            L: L,
            trailing: _HeaderAction(
                icon: '➕',
                label: 'ADD_SLOT',
                onTap: () async {
                  HapticEngine.selection();
                  final result = await ModernTimePicker.show(context,
                      initialTime: TimeOfDay.now(), title: "Add Reminder");
                  if (result != null) {
                    final newEntry = ScheduleEntry(
                        id: 'manual_${result.hour}_${result.minute}',
                        h: result.hour,
                        m: result.minute,
                        label: _getAutoLabel(result.hour),
                        days: const [1, 2, 3, 4, 5, 6, 0]);
                    _showRitualPicker(med.id, -1, newEntry, isNew: true);
                  }
                },
                L: L)),
        const SizedBox(height: 12),
        if (med.schedule.isEmpty)
          _buildEmptyCard('NO_ACTIVE_REMINDERS', '🔕', L)
        else
          SquircleCard(
            padding: EdgeInsets.zero,
            child: Column(
                children: med.schedule
                    .asMap()
                    .entries
                    .map((e) => _buildScheduleCard(med, e.value, e.key, L,
                        e.key == med.schedule.length - 1))
                    .toList()),
          ),
      ],
    );
  }

  Widget _buildScheduleCard(
      Medicine med, ScheduleEntry s, int idx, AppThemeColors L, bool isLast) {
    final medColor = hexToColor(med.color);
    return Container(
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.03), width: 0.5))),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: () async {
          HapticEngine.selection();
          final result = await ModernTimePicker.show(context,
              initialTime: TimeOfDay(hour: s.h, minute: s.m),
              title: "Edit Reminder");
          if (result != null) {
            final updatedEntry = s.copyWith(
                h: result.hour,
                m: result.minute,
                label: _getAutoLabel(result.hour));
            _showRitualPicker(med.id, idx, updatedEntry, isNew: false);
          }
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: s.enabled ? medColor.withValues(alpha: 0.1) : L.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              s.h < 12 ? "☀️" : "🌙",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
                '${s.h.toString().padLeft(2, '0')}:${s.m.toString().padLeft(2, '0')}',
                style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: s.enabled ? L.text : L.sub)),
            const SizedBox(width: 12),
            Text(
                (s.ritual != Ritual.none ? s.ritual.displayName : s.label)
                    .toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: L.sub,
                    letterSpacing: 1.0)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .asMap()
                  .entries
                  .map((day) => s.days.contains(day.key) ? day.value : '•')
                  .join('  '),
              style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: s.enabled
                      ? L.text.withValues(alpha: 0.6)
                      : L.sub.withValues(alpha: 0.3),
                  letterSpacing: 2)),
        ),
        trailing: AppToggle(
          value: s.enabled,
          onChanged: (v) {
            HapticEngine.selection();
            context.read<AppState>().toggleSchedule(med.id, idx);
          },
        ),
      ),
    );
  }

  Widget _buildHistorySection(
      Medicine med, int adh, int taken, int total, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'STABILITY_MATRIX', icon: '📊', L: L),
        const SizedBox(height: 12),
        SquircleCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(label: 'TAKEN', value: '$taken', color: L.text, L: L),
                  _Metric(
                      label: 'MISSED',
                      value: '${total - taken}',
                      color: L.error,
                      L: L),
                  _Metric(label: 'SCORE', value: '$adh%', color: L.text, L: L),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: L.border.withValues(alpha: 0.05)),
              const SizedBox(height: 24),
              const _HistoryMatrix(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificationsSection(Medicine med, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'TECHNICAL_SPECS', icon: '🔬', L: L),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SpecTile(label: 'FORM', value: med.form, icon: '💊', L: L),
              _SpecTile(
                  label: 'CATEGORY', value: med.category, icon: '🏷️', L: L),
              _SpecTile(label: 'UNIT', value: med.unit, icon: '⚖️', L: L),
              _SpecTile(
                  label: 'START', value: med.courseStartDate, icon: '🗓️', L: L),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'DATA_MANAGEMENT', icon: '🔐', L: L),
        const SizedBox(height: 12),
        SquircleCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ManagementTile(
                  icon: '➕',
                  title: 'Quick Refill (+10)',
                  color: L.text,
                  onTap: () {
                    HapticEngine.success();
                    state.updateMed(med.id, count: med.count + 10);
                  },
                  L: L),
              _ManagementTile(
                  icon: '🗑️',
                  title: 'Decommission Medicine',
                  color: L.error,
                  onTap: () {
                    HapticEngine.alertWarning();
                    state.deleteMed(med.id);
                    widget.onBack();
                  },
                  L: L,
                  isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      children: [
        _FormSection(label: 'IDENTITY', icon: '👤', L: L, children: [
          _ModernTextField(
              label: 'Medicine Name',
              value: _editFields['name'],
              onChanged: (v) => _editFields['name'] = v,
              L: L),
          _ModernTextField(
              label: 'Brand Name',
              value: _editFields['brand'],
              onChanged: (v) => _editFields['brand'] = v,
              L: L,
              isLast: true),
        ]),
        const SizedBox(height: 20),
        _FormSection(label: 'CONFIGURATION', icon: '🧬', L: L, children: [
          _ModernTextField(
              label: 'Dosage',
              value: _editFields['dose'],
              onChanged: (v) => _editFields['dose'] = v,
              L: L),
          _ModernTextField(
              label: 'Form',
              value: _editFields['form'],
              onChanged: (v) => _editFields['form'] = v,
              L: L,
              isLast: true),
        ]),
        const SizedBox(height: 20),
        _FormSection(label: 'LOGISTICS', icon: '📦', L: L, children: [
          _ModernTextField(
              label: 'Current Count',
              value: _editFields['count'],
              onChanged: (v) => _editFields['count'] = v,
              L: L,
              keyboard: TextInputType.number),
          _ModernTextField(
              label: 'Refill Alert',
              value: _editFields['refillAt'],
              onChanged: (v) => _editFields['refillAt'] = v,
              L: L,
              keyboard: TextInputType.number,
              isLast: true),
        ]),
      ],
    );
  }

  void _save(Medicine med, AppState state) {
    final updated = med.copyWith(
      name: _editFields['name'],
      brand: _editFields['brand'],
      dose: _editFields['dose'],
      form: _editFields['form'],
      category: _editFields['category'],
      notes: _editFields['notes'],
      intakeInstructions: _editFields['intakeInstructions'],
      count: int.tryParse(_editFields['count']) ?? med.count,
      totalCount: int.tryParse(_editFields['totalCount']) ?? med.totalCount,
      refillAt: int.tryParse(_editFields['refillAt']) ?? med.refillAt,
      refillInfo: med.refillInfo?.copyWith(
          pharmacyName: _editFields['pharmacyName'],
          pharmacyPhone: _editFields['pharmacyPhone'],
          rxNumber: _editFields['rxNumber']),
      price: double.tryParse(_editFields['price']),
      currency: _editFields['currency'],
      color: _editFields['color'],
    );
    state.updateMedDirect(updated);
    setState(() => _editMode = false);
  }

  String _getAutoLabel(int hour) {
    if (hour >= 5 && hour < 11) return 'Morning';
    if (hour >= 11 && hour < 16) return 'Afternoon';
    if (hour >= 16 && hour < 21) return 'Evening';
    return 'Night';
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tablet':
      case 'pill':
        return '💊';
      case 'syrup':
      case 'liquid':
        return '🧪';
      case 'injection':
        return '💉';
      case 'cream':
      case 'ointment':
        return '🧴';
      case 'drops':
        return '💧';
      case 'inhaler':
        return '🌬️';
      default:
        return '📦';
    }
  }

  void _showRitualPicker(int medId, int scheduleIdx, ScheduleEntry s,
      {bool isNew = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ctx.L.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: ctx.L.shadowSoft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: ctx.L.border,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text("Select Meal Ritual",
                style: AppTypography.headlineMedium
                    .copyWith(fontWeight: FontWeight.w900, color: ctx.L.text)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: Ritual.values.map((r) {
                  final isSelected = s.ritual == r;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onTap: () {
                      final updated = s.copyWith(ritual: r);
                      if (isNew) {
                        context.read<AppState>().addSchedule(medId, updated);
                      } else {
                        context
                            .read<AppState>()
                            .updateSchedule(medId, scheduleIdx, updated);
                      }
                      Navigator.pop(ctx);
                    },
                    title: Text(r.name.toUpperCase(),
                        style: AppTypography.bodyLarge.copyWith(
                            color: isSelected ? ctx.L.primary : ctx.L.text,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w500)),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: ctx.L.primary)
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

  Widget _buildEmptyCard(String text, String icon, AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(text,
              style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ── MODERN UI COMPONENTS ──────────────────────────────────────────

class _DiagnosticCard extends StatelessWidget {
  final String label, value;
  final String icon;
  final Color color;
  final AppThemeColors L;
  final Widget? child;

  const _DiagnosticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.L,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: SquircleCard(
        padding: const EdgeInsets.all(16),
        child: child ??
            Column(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 10)),
                    Text(icon, style: const TextStyle(fontSize: 12))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.2, 1.2),
                            duration: 2000.ms),
                  ],
                ),
                const Spacer(),
                Text(value,
                    style: AppTypography.displayLarge.copyWith(
                        fontSize: 24,
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0)),
              ],
            ),
      ),
    );
  }
}

class _ModernStockBar extends StatelessWidget {
  final double pct;
  final bool isLow;
  final AppThemeColors L;
  const _ModernStockBar(
      {required this.pct, required this.isLow, required this.L});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        width: double.infinity,
        color: L.fill,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: 1000.ms,
              curve: Curves.easeOutQuart,
              left: 0,
              top: 0,
              bottom: 0,
              width: (MediaQuery.of(context).size.width - 80) * pct,
              child: Container(
                decoration: BoxDecoration(
                  color: isLow ? L.error : L.text,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String icon;
  final Widget? trailing;
  final AppThemeColors L;
  const _SectionHeader(
      {required this.label,
      required this.icon,
      this.trailing,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 10)),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _HeaderAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return BouncingButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
            boxShadow: AppShadows.neumorphic,
          ),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 10)),
          ]),
        ));
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final Color color;
  final AppThemeColors L;
  const _Metric(
      {required this.label,
      required this.value,
      required this.color,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: AppTypography.displayLarge.copyWith(
              fontSize: 32,
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0)),
      Text(label,
          style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              color: L.sub,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0)),
    ]);
  }
}

class _HistoryMatrix extends StatelessWidget {
  const _HistoryMatrix();
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 4.0;
            const count = 28;
            final itemWidth =
                (constraints.maxWidth - (spacing * (count - 1))) / count;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(count, (i) {
                final isTaken = i % 5 != 0;
                return Container(
                  width: itemWidth,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isTaken ? L.text : L.fill,
                    borderRadius: BorderRadius.circular(4),
                    border: isTaken
                        ? null
                        : Border.all(
                            color: L.border.withValues(alpha: 0.05),
                            width: 0.5),
                    boxShadow: isTaken ? null : AppShadows.neumorphic,
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HISTORY_MATRIX_28D',
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0)),
            Text('OPTIMAL_STABILITY',
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0)),
          ],
        ),
      ],
    );
  }
}

class _SpecTile extends StatelessWidget {
  final String label, value;
  final String icon;
  final AppThemeColors L;
  const _SpecTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.L});
  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.of(context).size.width - 52) / 2; // Adjusted for 12px gap
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.border.withValues(alpha: 0.05), width: 0.5),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'UNDEFINED' : value.toUpperCase(),
              style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final AppThemeColors L;
  final bool isLast;
  const _ManagementTile(
      {required this.icon,
      required this.title,
      required this.color,
      required this.onTap,
      required this.L,
      this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                        color: L.border.withValues(alpha: 0.03), width: 0.5))),
        child: ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Text(icon, style: const TextStyle(fontSize: 22)),
            title: Text(title.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 11,
                    letterSpacing: 1.0)),
            trailing: Text('→',
                style: TextStyle(
                    color: L.sub.withValues(alpha: 0.3),
                    fontSize: 18,
                    fontWeight: FontWeight.w900))));
  }
}

class _FormSection extends StatelessWidget {
  final String label;
  final String icon;
  final List<Widget> children;
  final AppThemeColors L;
  const _FormSection(
      {required this.label,
      required this.icon,
      required this.children,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  fontSize: 10))),
      SquircleCard(padding: EdgeInsets.zero, child: Column(children: children)),
    ]);
  }
}

class _ModernTextField extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  final AppThemeColors L;
  final TextInputType keyboard;
  final bool isLast;
  const _ModernTextField(
      {required this.label,
      required this.value,
      required this.onChanged,
      required this.L,
      this.keyboard = TextInputType.text,
      this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.03), width: 0.5))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 10)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboard,
            maxLines: 1,
            style: AppTypography.titleMedium
                .copyWith(color: L.text, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent),
          ),
        ]),
      ),
    );
  }
}

// ── Restock Stepper Button ───────────────────────────────────────────
class _RestockBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _RestockBtn(
      {required this.label, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
