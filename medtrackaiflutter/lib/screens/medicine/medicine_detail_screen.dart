import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/modern_time_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/unified_header.dart';
import '../../core/utils/haptic_engine.dart';

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
    };
  }

  @override
  Widget build(BuildContext context) {
    final med = context.select<AppState, Medicine>(
        (s) => s.meds.firstWhere((m) => m.id == widget.medId, orElse: () => s.meds.first));
    final adh = context.select<AppState, int>((s) => s.getAdherenceForMed(widget.medId));
    final historyCount = context.select<AppState, ({int taken, int total})>(
        (s) => s.getHistoryCountForMed(widget.medId));
    final L = context.L;
    final medColor = hexToColor(med.color);

    return Scaffold(
      backgroundColor: L.bg,
      body: _editMode
          ? SafeArea(
              child: Scrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              style: TextStyle(
                                  color: L.text, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w900, 
                                  fontFamily: 'Inter',
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (med.intakeInstructions.isNotEmpty && med.intakeInstructions != 'None')
                            _buildIntakeChip(med.intakeInstructions, L),
                          if (med.intakeInstructions.isNotEmpty && med.intakeInstructions != 'None')
                            const SizedBox(height: 32),
                          
                          _buildStatsCards(med, adh, L),
                          const SizedBox(height: AppSpacing.sectionGap),
                          _buildScheduleSection(med, context.read<AppState>(), L),
                          const SizedBox(height: AppSpacing.sectionGap),
                          _buildHistorySection(med, adh, historyCount.taken, historyCount.total, L),
                          const SizedBox(height: AppSpacing.sectionGap),
                          _buildSpecificationsSection(med, L),
                          const SizedBox(height: AppSpacing.sectionGap),
                          _buildSettingsSection(med, context.read<AppState>(), L),
                          const SizedBox(height: AppSpacing.bottomBuffer),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverHeader(Medicine med, Color medColor, AppThemeColors L) {
    return SliverUnifiedHeader(
      title: med.name,
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
                    border: Border.all(color: medColor.withValues(alpha: 0.2), width: 1.0),
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
                      child: Text(med.name.isNotEmpty ? med.name[0].toUpperCase() : '💊', 
                          style: const TextStyle(fontSize: 56)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (med.brand.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: medColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: Text(med.brand,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: medColor)),
                ),
              const SizedBox(height: 40),
            ],
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic),
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
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(intake,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: L.text)),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), delay: 200.ms),
    );
  }

  Widget _buildStatsCards(Medicine med, int adh, AppThemeColors L) {
    return Row(
      children: [
        Expanded(
          child: _GlassDataCard(
            label: 'ADHERENCE',
            value: adh == -1 ? 'NEW' : '$adh%',
            color: adh >= 80 ? L.primary : (adh >= 50 ? L.warning : L.error),
            L: L,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlassDataCard(
            label: 'STOCK LEFT',
            value: '${med.count}',
            sub: 'pills',
            color: med.count <= med.refillAt ? L.error : L.primary,
            L: L,
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
                  state.addSchedule(med.id, newEntry);
                }
              },
              icon: Icon(Icons.add_circle_outline_rounded, color: L.text, size: 18),
              label: Text('Add Slot',
                  style: TextStyle(
                      color: L.text, fontWeight: FontWeight.w800, fontSize: 13)),
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
                    style: TextStyle(color: L.sub, fontSize: 14, fontWeight: FontWeight.w500)),
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
                FadeEffect(duration: 400.ms, delay: (100 * idx).ms, curve: Curves.easeOut),
                SlideEffect(begin: const Offset(0, 0.05), duration: 400.ms, delay: (100 * idx).ms, curve: Curves.easeOut),
              ],
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: L.card.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: L.border.withValues(alpha: 0.4)),
                ),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 8, color: medColor.withValues(alpha: 0.8)),
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
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: s.enabled ? L.text : L.sub,
                                              letterSpacing: -1.0)),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: L.fill,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(s.label.toUpperCase(),
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: L.sub,
                                                letterSpacing: 1.0)),
                                      ),
                                    ]),
                                    AppToggle(
                                        value: s.enabled,
                                        onChanged: (v) {
                                          HapticEngine.selection();
                                          context.read<AppState>().toggleSchedule(med.id, idx);
                                        }),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                          .asMap()
                                          .entries
                                          .map((e) {
                                        final isScheduled = s.days.contains(e.key);
                                        return Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: isScheduled
                                                ? L.text
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: isScheduled ? L.text : L.border,
                                                width: 1),
                                          ),
                                          child: Center(
                                              child: Text(e.value,
                                                  style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: isScheduled ? L.bg : L.sub))),
                                        );
                                      }).toList(),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        HapticEngine.selection();
                                        context.read<AppState>().removeSchedule(med.id, idx);
                                      },
                                      icon: Icon(Icons.delete_outline_rounded,
                                          size: 20, color: L.error.withValues(alpha: 0.8)),
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
              _buildSpecRow('Form', med.form, Icons.medication_liquid_rounded, L),
              const Divider(height: 24, thickness: 0.5),
              _buildSpecRow('Unit', med.unit, Icons.numbers_rounded, L),
              const Divider(height: 24, thickness: 0.5),
              _buildSpecRow('Category', med.category, Icons.category_rounded, L),
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

  Widget _buildSpecRow(String label, String value, IconData icon, AppThemeColors L) {
    return Row(
      children: [
        Icon(icon, size: 18, color: L.sub.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: L.sub, fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            textAlign: TextAlign.end,
            style: TextStyle(color: L.text, fontSize: 14, fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(Medicine med, int adh, int taken, int total, AppThemeColors L) {
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
                    color: L.text,
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Last 14 days',
                    style:
                        TextStyle(color: L.text, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (adh >= 80 ? L.primary : L.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Text('$adh%',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: adh >= 80 ? L.primary : L.error,
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
                      color: isFilled ? L.primary.withValues(alpha: 0.15) : L.fill,
                      borderRadius: BorderRadius.circular(AppRadius.s),
                      border: Border.all(
                          color: isFilled
                              ? L.primary.withValues(alpha: 0.3)
                              : L.border.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                        child: Icon(
                            isFilled ? Icons.check_rounded : Icons.remove_rounded,
                            size: 16,
                            color: isFilled ? L.primary : L.sub.withValues(alpha: 0.5))),
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
                color: L.secondary,
                L: L,
                onTap: () {
                  HapticEngine.success();
                  state.updateMed(med.id, count: med.count + 10);
                },
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, thickness: 0.5, color: L.border.withValues(alpha: 0.5)),
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

  Widget _buildListTile({required IconData icon, required String title, required Color color, required AppThemeColors L, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
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
              child: Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: L.text)),
            ),
            Icon(Icons.chevron_right_rounded, color: L.sub.withValues(alpha: 0.5), size: 24),
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

  Widget _buildEditForm(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LightInput(
            label: 'Medication Name',
            value: _editFields['name'],
            onChanged: (v) => _editFields['name'] = v),
        const SizedBox(height: 16),
        LightInput(
            label: 'Brand Name',
            value: _editFields['brand'],
            placeholder: 'Optional',
            onChanged: (v) => _editFields['brand'] = v),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: LightInput(
                  label: 'Dosage',
                  value: _editFields['dose'],
                  placeholder: '500mg',
                  onChanged: (v) => _editFields['dose'] = v)),
          const SizedBox(width: 12),
          Expanded(
              child: LightInput(
                  label: 'Form',
                  value: _editFields['form'],
                  placeholder: 'tablet',
                  onChanged: (v) => _editFields['form'] = v)),
        ]),
        const SizedBox(height: 16),
        LightInput(
            label: 'Category',
            value: _editFields['category'],
            onChanged: (v) => _editFields['category'] = v),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: LightInput(
                  label: 'Stock',
                  value: _editFields['count'],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _editFields['count'] = v)),
          const SizedBox(width: 12),
          Expanded(
              child: LightInput(
                  label: 'Pack',
                  value: _editFields['totalCount'],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _editFields['totalCount'] = v)),
          const SizedBox(width: 12),
          Expanded(
              child: LightInput(
                  label: 'Alert',
                  value: _editFields['refillAt'],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _editFields['refillAt'] = v)),
        ]),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Cancel',
                  onTap: () {
                    HapticEngine.selection();
                    setState(() => _editMode = false);
                  },
                  color: L.sub,
                  isGhost: true)),
          const SizedBox(width: 16),
          Expanded(
              flex: 2,
              child: _ActionBtn(
                  label: 'Save Changes',
                  onTap: () {
                    HapticEngine.success();
                    context.read<AppState>().updateMed(
                      med.id,
                      name: _editFields['name'],
                      brand: _editFields['brand'],
                      dose: _editFields['dose'],
                      form: _editFields['form'],
                      category: _editFields['category'],
                      count: int.tryParse(_editFields['count']) ?? med.count,
                      totalCount: int.tryParse(_editFields['totalCount']) ??
                          med.totalCount,
                      refillAt:
                          int.tryParse(_editFields['refillAt']) ?? med.refillAt,
                      intakeInstructions: _editFields['intakeInstructions'] ?? med.intakeInstructions,
                    );
                    setState(() => _editMode = false);
                  },
                  color: const Color(0xFF111111))),
        ]),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _GlassDataCard extends StatelessWidget {
  final String label, value;
  final String? sub;
  final Color color;
  final AppThemeColors L;

  const _GlassDataCard({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: L.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: L.sub,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -1.0)),
              if (sub != null) ...[
                const SizedBox(width: 4),
                Text(sub!,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: L.sub)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label, value;
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border)),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: L.sub, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(value,
                style: TextStyle(
                    color: L.text, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
          ]),
        ]),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isGhost;
  const _ActionBtn(
      {required this.label,
      required this.onTap,
      required this.color,
      this.isGhost = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isGhost ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(32),
            border: isGhost
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.0)
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: TextStyle(
                    color: isGhost ? color : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ]),
        ),
      );
}

