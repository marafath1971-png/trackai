import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/unified_header.dart';
import '../../core/utils/haptic_engine.dart';
import 'widgets/medicine_safety_card.dart';
import '../../widgets/common/bouncing_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../core/utils/refill_helper.dart';

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
  bool _editMode = false;
  late Map<String, dynamic> _editFields;

  @override
  void initState() {
    super.initState();
    _editMode = widget.initialEditMode;
    _resetEdit();
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
      // RefillInfo fields - with null safety
      'pharmacyName': med.refillInfo?.pharmacyName ?? '',
      'pharmacyPhone': med.refillInfo?.pharmacyPhone ?? '',
      'rxNumber': med.refillInfo?.rxNumber ?? '',
      'price': med.price?.toString() ?? '',
      'currency': med.currency ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final med = context.select<AppState, Medicine>((s) => s.meds
        .firstWhere((m) => m.id == widget.medId, orElse: () => s.meds.first));
    final adh = context
        .select<AppState, int>((s) => s.getAdherenceForMed(widget.medId));
    final historyCount = context.select<AppState, ({int taken, int total})>(
        (s) => s.getHistoryCountForMed(widget.medId));
    final medColor = hexToColor(med.color);

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Non-blur mesh depth ornaments
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.sizeOf(context).height *
                0.2, // Use a calculated offset
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.primary.withValues(alpha: 0.03),
              ),
            ),
          ),

          _editMode
              ? SafeArea(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: Icon(Icons.close_rounded, color: L.sub),
                                  onPressed: () {
                                    HapticEngine.selection();
                                    setState(() {
                                      _resetEdit();
                                      _editMode = false;
                                    });
                                  },
                                ),
                              ),
                              Text('Edit Medication',
                                  style: AppTypography.titleMedium.copyWith(
                                      color: L.text,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildEditForm(med, context.read<AppState>(), L)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.05),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                )
              : Scrollbar(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      _buildSliverHeader(med, medColor, L),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (med.intakeInstructions.isNotEmpty &&
                                  med.intakeInstructions != 'None')
                                _buildIntakeChip(med.intakeInstructions, L),
                              if (med.halalStatus != null &&
                                  med.halalStatus != 'none' &&
                                  med.halalStatus!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildHalalBadge(
                                    med.halalStatus!, med.halalNote, L),
                              ],
                              if ((med.intakeInstructions.isNotEmpty &&
                                      med.intakeInstructions != 'None') ||
                                  (med.halalStatus != null &&
                                      med.halalStatus != 'none'))
                                const SizedBox(height: 32),
                              _buildStatsCards(med, adh, L),
                              const SizedBox(height: AppSpacing.sectionGap),
                              MedicineSafetyCard(med: med),
                              const SizedBox(height: AppSpacing.sectionGap),
                              _buildScheduleSection(
                                  med, context.read<AppState>(), L),
                              const SizedBox(height: AppSpacing.sectionGap),
                              _buildHistorySection(med, adh, historyCount.taken,
                                  historyCount.total, L),
                              const SizedBox(height: AppSpacing.sectionGap),
                              _buildSpecificationsSection(med, L),
                              const SizedBox(height: AppSpacing.sectionGap),
                              _buildSettingsSection(
                                  med, context.read<AppState>(), L),
                              const SizedBox(height: AppSpacing.bottomBuffer),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(Medicine med, Color medColor, AppThemeColors L) {
    return SliverUnifiedHeader(
      title: (context.select<AppState, bool>(
                  (s) => s.profile?.showGenericNames ?? false) &&
              med.genericName.isNotEmpty)
          ? med.genericName
          : med.name,
      onBack: widget.onBack,
      actions: [
        HeaderActionBtn(
          onTap: () {
            HapticEngine.selection();
            setState(() {
              _resetEdit();
              _editMode = true;
            });
          },
          child: const Icon(Icons.edit_note_rounded, size: 20),
        ),
        const SizedBox(width: 8),
        HeaderActionBtn(
          onTap: () {
            HapticEngine.selection();
          },
          child: const Icon(Icons.share_rounded, size: 18),
        ),
      ],
      background: Stack(
        alignment: Alignment.center,
        children: [
          // Premium background gradient/blur
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    medColor.withValues(alpha: 0.25),
                    L.bg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Glass circle glow
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medColor.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: medColor.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: 'med_${med.id}',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: medColor.withValues(alpha: 0.2), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: medColor.withValues(alpha: 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: MedImage(
                    imageUrl: med.imageUrl,
                    width: 120,
                    height: 120,
                    borderRadius: 99,
                    placeholder: Center(
                      child: Text(
                          med.name.isNotEmpty
                              ? med.name[0].toUpperCase()
                              : '💊',
                          style: AppTypography.headlineLarge
                              .copyWith(fontSize: 56)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (med.brand.isNotEmpty ||
                  (context.select<AppState, bool>(
                          (s) => s.profile?.showGenericNames ?? false) &&
                      med.name.isNotEmpty))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: medColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: Text(
                      ((context.select<AppState, bool>((s) =>
                                  s.profile?.showGenericNames ?? false) &&
                              med.genericName.isNotEmpty)
                          ? med.name
                          : med.brand),
                      style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700, color: medColor)),
                ),
              if (med.refillInfo?.rxNumber != null &&
                  med.refillInfo!.rxNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: L.text.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                    border: Border.all(color: L.border.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 12, color: L.sub),
                      const SizedBox(width: 6),
                      Text('Rx: ${med.refillInfo!.rxNumber}',
                          style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600, color: L.sub)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildHalalBadge(String status, String? note, AppThemeColors L) {
    final S = AppLocalizations.of(context)!;
    Color color = L.sub;
    String text = S.halalUncertain;
    IconData icon = Icons.help_outline_rounded;

    if (status.toLowerCase().contains('safe') ||
        status.toLowerCase().contains('halal')) {
      color = L.success;
      text = S.halalSafe;
      icon = Icons.verified_user_rounded;
    } else if (status.toLowerCase().contains('gelatin') ||
        status.toLowerCase().contains('pork') ||
        status.toLowerCase().contains('non')) {
      color = L.error;
      text = S.gelatinWarning;
      icon = Icons.warning_amber_rounded;
    }

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(text,
                    style: AppTypography.labelLarge
                        .copyWith(fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(note,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall
                      .copyWith(color: L.sub, fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntakeChip(String intake, AppThemeColors L) {
    String emoji = '💊';
    if (intake.contains('Food')) emoji = '🍞';
    if (intake.contains('Meals')) emoji = '🍽️';
    if (intake.contains('Water')) emoji = '💧';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: Border.all(color: L.border.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: AppTypography.titleLarge),
            const SizedBox(width: 8),
            Text(intake,
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.w800, color: L.text)),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), delay: 200.ms),
    );
  }

  Widget _buildStatsCards(Medicine med, int adh, AppThemeColors L) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border, width: 1.5),
            ),
            child: Column(
              children: [
                Text('ADHERENCE',
                    style: AppTypography.labelLarge.copyWith(
                        color: L.sub,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Text(adh == -1 ? 'NEW' : '$adh%',
                    style: AppTypography.displayLarge.copyWith(
                        color: adh >= 80
                            ? L.secondary
                            : (adh >= 50 ? L.warning : L.error),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border, width: 1.5),
            ),
            child: Column(
              children: [
                Text('STOCK LEFT',
                    style: AppTypography.labelLarge.copyWith(
                        color: L.sub,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${med.count}',
                        style: AppTypography.displayLarge.copyWith(
                            color: med.count <= med.refillAt ? L.error : L.text,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0)),
                    const SizedBox(width: 4),
                    Text(med.unit.toLowerCase(),
                        style: AppTypography.labelSmall.copyWith(
                            color: L.sub, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildScheduleSection(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('Reminders'),
            TextButton.icon(
              onPressed: () async {
                HapticEngine.selection();
                final result = await ModernTimePicker.show(
                  context,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  title: "Add Reminder",
                );
                if (result != null) {
                  final newEntry = ScheduleEntry(
                    h: result.hour,
                    m: result.minute,
                    label: _getAutoLabel(result.hour),
                    days: [0, 1, 2, 3, 4, 5, 6],
                  );
                  // Optionally show ritual picker after time selection
                  _showRitualPicker(med.id, -1, newEntry, isNew: true);
                }
              },
              icon: Icon(Icons.add_circle_outline_rounded,
                  color: L.text, size: 18),
              label: Text('Add Slot',
                  style: AppTypography.labelLarge
                      .copyWith(color: L.text, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (med.schedule.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: L.border.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Icon(Icons.notifications_off_rounded, color: L.sub, size: 40),
                const SizedBox(height: 16),
                Text('No reminders set for this medicine.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium
                        .copyWith(color: L.sub, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else
          ...med.schedule.asMap().entries.map((e) {
            final idx = e.key;
            final s = e.value;
            final medColor = hexToColor(med.color);

            return Animate(
              effects: [
                FadeEffect(
                    duration: 400.ms,
                    delay: (100 * idx).ms,
                    curve: Curves.easeOut),
                SlideEffect(
                    begin: const Offset(0, 0.05),
                    duration: 400.ms,
                    delay: (100 * idx).ms,
                    curve: Curves.easeOut),
              ],
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: L.border, width: 1.5),
                ),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: medColor.withValues(alpha: 0.8),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24)),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Text(
                                      '${s.h.toString().padLeft(2, '0')}:${s.m.toString().padLeft(2, '0')}',
                                      style: AppTypography.headlineLarge
                                          .copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: s.enabled ? L.text : L.sub,
                                              fontSize: 24,
                                              letterSpacing: -1.0)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: L.fill,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                        s.ritual != Ritual.none
                                            ? s.ritual.name
                                                .replaceAll(
                                                    RegExp(r'(?=[A-Z])'), ' ')
                                                .toUpperCase()
                                            : s.label.toUpperCase(),
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 9,
                                                color: L.sub,
                                                letterSpacing: 0.8)),
                                  ),
                                ]),
                                AppToggle(
                                    value: s.enabled,
                                    onChanged: (v) {
                                      HapticEngine.selection();
                                      context
                                          .read<AppState>()
                                          .toggleSchedule(med.id, idx);
                                    }),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Wrap(
                                  spacing: 8,
                                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                      .asMap()
                                      .entries
                                      .map((e) {
                                    final isScheduled = s.days.contains(e.key);
                                    return Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isScheduled
                                            ? L.text
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: isScheduled
                                                ? L.text
                                                : L.border
                                                    .withValues(alpha: 0.3),
                                            width: 1),
                                      ),
                                      child: Center(
                                          child: Text(e.value,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 10,
                                                      color: isScheduled
                                                          ? L.bg
                                                          : L.sub))),
                                    );
                                  }).toList(),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    HapticEngine.selection();
                                    context
                                        .read<AppState>()
                                        .removeSchedule(med.id, idx);
                                  },
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 20,
                                      color: L.error.withValues(alpha: 0.6)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSpecificationsSection(Medicine med, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Medication Details'),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              _buildSpecRow(
                  'Form', med.form, Icons.medication_liquid_rounded, L),
              const Divider(height: 24, thickness: 0.5),
              _buildSpecRow('Unit', med.unit, Icons.numbers_rounded, L),
              const Divider(height: 24, thickness: 0.5),
              _buildSpecRow(
                  'Category', med.category, Icons.category_rounded, L),
              const Divider(height: 24, thickness: 0.5),
              _buildSpecRow('Exhaustion', RefillHelper.getExhaustionStatus(med),
                  Icons.event_available_rounded, L),
              if (med.price != null) ...[
                const Divider(height: 24, thickness: 0.5),
                _buildSpecRow(
                    'Unit Price',
                    med.currency != null
                        ? '${med.currency} ${med.price}'
                        : med.price.toString(),
                    Icons.payments_rounded,
                    L),
              ],
              if (med.refillInfo?.pharmacyName != null &&
                  med.refillInfo!.pharmacyName!.isNotEmpty) ...[
                const Divider(height: 24, thickness: 0.5),
                _buildSpecRow(
                    AppLocalizations.of(context)!.pharmacyLabel,
                    med.refillInfo!.pharmacyName ?? '',
                    Icons.local_pharmacy_rounded,
                    L),
              ],
              if (med.refillInfo?.pharmacyPhone != null &&
                  med.refillInfo!.pharmacyPhone!.isNotEmpty) ...[
                const Divider(height: 24, thickness: 0.5),
                _buildSpecRow(
                  AppLocalizations.of(context)!.pharmacyPhoneLabel,
                  med.refillInfo!.pharmacyPhone ?? '',
                  Icons.phone_rounded,
                  L,
                  onTap: () async {
                    final uri =
                        Uri.parse('tel:${med.refillInfo!.pharmacyPhone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ],
              if (med.refillInfo?.rxNumber != null &&
                  med.refillInfo!.rxNumber!.isNotEmpty) ...[
                const Divider(height: 24, thickness: 0.5),
                _buildSpecRow(
                    AppLocalizations.of(context)!.rxNumberLabel,
                    med.refillInfo!.rxNumber ?? '',
                    Icons.receipt_long_rounded,
                    L),
              ],
              if (med.notes.isNotEmpty) ...[
                const Divider(height: 24, thickness: 0.5),
                _buildSpecRow('Notes', med.notes, Icons.description_rounded, L),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(
      String label, String value, IconData icon, AppThemeColors L,
      {VoidCallback? onTap}) {
    return BouncingButton(
      onTap: onTap,
      scaleFactor: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color:
                    onTap != null ? L.primary : L.sub.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Text(label,
                style: AppTypography.labelMedium
                    .copyWith(color: L.sub, fontWeight: FontWeight.w600)),
            const Spacer(),
            Expanded(
              child: Text(
                value.isEmpty ? 'N/A' : value,
                textAlign: TextAlign.end,
                style: AppTypography.labelLarge.copyWith(
                    color: onTap != null ? L.primary : L.text,
                    fontWeight: FontWeight.w800,
                    decoration:
                        onTap != null ? TextDecoration.underline : null),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 14, color: L.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
      Medicine med, int adh, int taken, int total, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Performance Summary'),
        Row(
          children: [
            Expanded(
                child: _SummaryBox(
                    label: 'Taken',
                    value: '$taken',
                    icon: Icons.check_circle_rounded,
                    color: L.success,
                    L: L)),
            const SizedBox(width: 12),
            Expanded(
                child: _SummaryBox(
                    label: 'Missed',
                    value: '${total - taken}',
                    icon: Icons.cancel_rounded,
                    color: L.error,
                    L: L)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: L.border.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: L.sub.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Last 14 days',
                    style: AppTypography.labelMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (adh >= 80 ? L.success : L.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Text('$adh%',
                      style: AppTypography.titleMedium.copyWith(
                          color: adh >= 80 ? L.success : L.error,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                ),
              ]),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(14, (i) {
                  final isFilled = i < 11;
                  return Container(
                    width: (MediaQuery.of(context).size.width - 110) / 7,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          isFilled ? L.success.withValues(alpha: 0.15) : L.fill,
                      borderRadius: BorderRadius.circular(AppRadius.s),
                      border: Border.all(
                          color: isFilled
                              ? L.success.withValues(alpha: 0.3)
                              : L.border.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                        child: Icon(
                            isFilled
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                            size: 16,
                            color: isFilled
                                ? L.success
                                : L.sub.withValues(alpha: 0.5))),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildSettingsSection(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Management'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              _buildListTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Refill Stock (+10)',
                color: L.success,
                L: L,
                onTap: () {
                  HapticEngine.success();
                  state.updateMed(med.id, count: med.count + 10);
                },
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: L.border.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 4),
              _buildListTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Medicine',
                color: L.error,
                L: L,
                onTap: () {
                  HapticEngine.alertWarning();
                  state.deleteMed(med.id);
                  widget.onBack();
                },
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildListTile(
      {required IconData icon,
      required String title,
      required Color color,
      required AppThemeColors L,
      required VoidCallback onTap}) {
    return BouncingButton(
      onTap: onTap,
      scaleFactor: 0.95,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700, color: L.text)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.5), size: 24),
          ],
        ),
      ),
    );
  }

  String _getAutoLabel(int h) {
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }

  void _showRitualPicker(int medId, int idx, ScheduleEntry s,
      {bool isNew = false}) {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.L.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: context.L.border),
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
                      HapticEngine.selection();
                      s.ritual = r;
                      if (isNew) {
                        state.addSchedule(medId, s);
                      } else {
                        state.updateSchedule(medId, idx, s);
                      }
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

  String _getRitualLabel(Ritual r) {
    switch (r) {
      case Ritual.none:
        return 'No Meal Ritual';
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
      case Ritual.onWaking:
        return 'On Waking';
      case Ritual.asNeeded:
        return 'As Needed';
    }
  }

  Widget _buildEditForm(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      children: [
        _buildTextField('NAME', 'name', L),
        _buildTextField('BRAND', 'brand', L),
        Row(
          children: [
            Expanded(child: _buildTextField('DOSE', 'dose', L)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('FORM', 'form', L)),
          ],
        ),
        _buildTextField('CATEGORY', 'category', L),
        _buildTextField('NOTES', 'notes', L, maxLines: 3),
        const SizedBox(height: 32),
        const SectionLabel('Inventory & Pharmacy'),
        Row(
          children: [
            Expanded(
                child: _buildTextField('CURRENT COUNT', 'count', L,
                    keyboard: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTextField('REFILL AT', 'refillAt', L,
                    keyboard: TextInputType.number)),
          ],
        ),
        _buildTextField(
            AppLocalizations.of(context)!.pharmacyLabel.toUpperCase(),
            'pharmacyName',
            L),
        _buildTextField(
            AppLocalizations.of(context)!.pharmacyPhoneLabel.toUpperCase(),
            'pharmacyPhone',
            L,
            keyboard: TextInputType.phone),
        _buildTextField(
            AppLocalizations.of(context)!.rxNumberLabel.toUpperCase(),
            'rxNumber',
            L),
        Row(
          children: [
            Expanded(
                child: _buildTextField('PRICE', 'price', L,
                    keyboard: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTextField('CURRENCY', 'currency', L,
                    placeholder: 'e.g. GBP, USD')),
          ],
        ),
        const SizedBox(height: 48),
        BouncingButton(
          onTap: () {
            HapticEngine.success();
            _save(med, state);
          },
          scaleFactor: 0.95,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('SAVE CHANGES',
                  style: AppTypography.labelLarge.copyWith(
                      color: L.bg,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String key, AppThemeColors L,
      {int maxLines = 1,
      TextInputType keyboard = TextInputType.text,
      String? placeholder}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => _editFields[key] = v,
            controller: TextEditingController(text: _editFields[key])
              ..selection =
                  TextSelection.collapsed(offset: _editFields[key].length),
            maxLines: maxLines,
            keyboardType: keyboard,
            style: AppTypography.bodyLarge
                .copyWith(color: L.text, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: L.fill,
              hintText: placeholder ?? 'Enter $label',
              hintStyle: AppTypography.bodyLarge.copyWith(
                  color: L.sub.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _save(Medicine med, AppState state) {
    final newRefill = RefillInfo(
      totalQuantity:
          (int.tryParse(_editFields['totalCount'].toString()) ?? med.totalCount)
              .toDouble(),
      currentInventory:
          (int.tryParse(_editFields['count'].toString()) ?? med.count)
              .toDouble(),
      refillThreshold:
          (int.tryParse(_editFields['refillAt'].toString()) ?? med.refillAt)
              .toDouble(),
      pharmacyName: _editFields['pharmacyName'],
      pharmacyPhone: _editFields['pharmacyPhone'],
      rxNumber: _editFields['rxNumber'],
      lastRefilledAt: med.refillInfo?.lastRefilledAt,
    );

    final updated = med.copyWith(
      name: _editFields['name'],
      brand: _editFields['brand'],
      dose: _editFields['dose'],
      form: _editFields['form'],
      category: _editFields['category'],
      notes: _editFields['notes'],
      count: int.tryParse(_editFields['count']) ?? med.count,
      totalCount: int.tryParse(_editFields['totalCount']) ?? med.totalCount,
      refillAt: int.tryParse(_editFields['refillAt']) ?? med.refillAt,
      intakeInstructions: _editFields['intakeInstructions'],
      refillInfo: newRefill,
      price: double.tryParse(_editFields['price'].toString()),
      currency: _editFields['currency'],
    );
    state.updateMedDirect(updated);
    setState(() => _editMode = false);
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final AppThemeColors L;

  const _SummaryBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.L});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelSmall
                      .copyWith(color: L.sub, fontWeight: FontWeight.w700)),
              Text(value,
                  style: AppTypography.titleMedium
                      .copyWith(color: L.text, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
              color: L.sub, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    );
  }
}
