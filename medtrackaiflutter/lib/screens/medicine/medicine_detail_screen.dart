import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/modern_time_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class _MedicineDetailScreenState extends State<MedicineDetailScreen>
    with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Overview, 1: History, 2: Reminders
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
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final med = state.meds.firstWhere((m) => m.id == widget.medId,
        orElse: () => state.meds.first);
    final L = context.L;
    final medColor = hexToColor(med.color);

    // Calculate Adherence
    final medHistory = state.history.values
        .expand((e) => e)
        .where((e) => e.medId == med.id)
        .toList();
    final takenCount = medHistory.where((e) => e.taken).length;
    final totalDoses = medHistory.length;
    final adh = totalDoses == 0 ? 0 : (takenCount * 100 / totalDoses).round();

    return Material(
      color: L.bg,
      child: Column(
        children: [
          // 1. HERO SECTION (Dark / Med Color Background)
          _buildHero(med, medColor, L),

          if (_editMode)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildEditForm(med, state, L),
              ),
            )
          else ...[
            // 2. STATS ROW (3 Columns)
            _buildStatsRow(med, adh, L),

            // 3. TABS HEADER
            _buildTabsHeader(L),

            // 4. TAB CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                physics: const BouncingScrollPhysics(),
                child: _buildActiveTabContent(med, state, medColor, medHistory,
                    adh, takenCount, totalDoses, L),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(Medicine med, Color medColor, AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 32,
          left: 24,
          right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack,
              ),
              Row(
                children: [
                  _CircleIconBtn(
                      icon: _editMode
                          ? Icons.close_rounded
                          : Icons.edit_note_rounded,
                      onTap: () => setState(() {
                            if (_editMode) _resetEdit();
                            _editMode = !_editMode;
                          })),
                  const SizedBox(width: 12),
                  _CircleIconBtn(icon: Icons.share_rounded, onTap: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Hero(
            tag: 'med_${med.id}',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: medColor.withValues(alpha: 0.3), width: 3),
              ),
              child: MedImage(
                imageUrl: med.imageUrl,
                width: 100,
                height: 100,
                borderRadius: 99,
                placeholder: const Center(
                  child: Text('💊', style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(med.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5)),
          if (med.brand.isNotEmpty)
            Text(med.brand,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Medicine med, int adh, AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
              label: 'ADHERENCE',
              value: '$adh%',
              color: adh >= 80 ? L.green : L.amber,
              L: L),
          _StatItem(
              label: 'STOCK',
              value: '${med.count}',
              sub: 'pills',
              color: med.count <= med.refillAt ? L.red : L.text,
              L: L),
          _StatItem(
              label: 'COURSE',
              value: 'N/A',
              sub: 'Progress',
              color: L.green,
              L: L),
        ],
      ),
    );
  }

  Widget _buildTabsHeader(AppThemeColors L) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: L.fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TabBtn(
              label: 'Overview',
              active: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
              L: L),
          _TabBtn(
              label: 'History',
              active: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
              L: L),
          _TabBtn(
              label: 'Reminders',
              active: _activeTab == 2,
              onTap: () => setState(() => _activeTab = 2),
              L: L),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(
      Medicine med,
      AppState state,
      Color medColor,
      List<DoseEntry> medHistory,
      int adh,
      int taken,
      int total,
      AppThemeColors L) {
    switch (_activeTab) {
      case 1:
        return _buildHistoryTab(med, medHistory, adh, taken, total, L);
      case 2:
        return _buildRemindersTab(med, L);
      default:
        return _buildOverviewTab(med, state, medColor, L);
    }
  }

  Widget _buildOverviewTab(
      Medicine med, AppState state, Color medColor, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('📌 Instructions'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: medColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: medColor.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: medColor.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: medColor, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text('How & When to Take',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: L.text,
                        fontSize: 17,
                        letterSpacing: -0.3)),
              ]),
              const SizedBox(height: 20),
              _buildInstructionRow("📖 Instruction", med.notes.isNotEmpty ? med.notes : "Take as prescribed by your doctor.", L),
              const Divider(height: 32, thickness: 0.5),
              _buildInstructionRow("🥛 How to take", "Take with water, ideally after meals for better absorption.", L),
              const Divider(height: 32, thickness: 0.5),
              _buildInstructionRow("⏰ Best time", "Consistent timing is key for effective results.", L),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Stock Status'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Available Balance',
                  style: TextStyle(color: L.text, fontWeight: FontWeight.w600)),
              Text('${med.count} pills',
                  style: TextStyle(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _ActionBtn(
                      label: 'Refill +10',
                      onTap: () =>
                          state.updateMed(med.id, count: med.count + 10),
                      color: L.green,
                      isGhost: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: _ActionBtn(
                      label: 'Adjust',
                      onTap: () {},
                      color: L.text,
                      isGhost: true)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: () {
              state.deleteMed(med.id);
              widget.onBack();
            },
            icon: Icon(Icons.delete_outline_rounded, color: L.red, size: 18),
            label: Text('Remove Medicine',
                style: TextStyle(
                    color: L.red, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInstructionRow(String label, String content, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                color: L.sub,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(content,
            style: TextStyle(
                color: L.text.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5)),
      ],
    );
  }

  Widget _buildHistoryTab(Medicine med, List<DoseEntry> medHistory, int adh,
      int taken, int total, AppThemeColors L) {
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
                    color: L.green,
                    L: L)),
            const SizedBox(width: 12),
            Expanded(
                child: _SummaryBox(
                    label: 'Missed',
                    value: '${total - taken}',
                    icon: Icons.cancel_rounded,
                    color: L.red,
                    L: L)),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('14-Day Timeline'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border)),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Last 14 days',
                    style:
                        TextStyle(color: L.text, fontWeight: FontWeight.w700)),
                Text('$adh%',
                    style: TextStyle(
                        color: adh >= 80 ? L.green : L.amber,
                        fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 20),
              // Adherence Grid (Simplified version of JSX 14-day log)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(14, (i) {
                  return Container(
                    width: (MediaQuery.of(context).size.width - 100) / 7,
                    height: 32,
                    decoration: BoxDecoration(
                      color: i < 11 ? L.green.withValues(alpha: 0.15) : L.fill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: i < 11
                              ? L.green.withValues(alpha: 0.3)
                              : L.border),
                    ),
                    child: Center(
                        child: Icon(
                            i < 11 ? Icons.check_rounded : Icons.remove_rounded,
                            size: 14,
                            color: i < 11 ? L.green : L.sub)),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersTab(Medicine med, AppThemeColors L) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('Current Schedule'),
            TextButton.icon(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final result = await ModernTimePicker.show(
                  context,
                  initialTime: const TimeOfDay(hour: 12, minute: 0),
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
              icon: Icon(Icons.add_circle_outline_rounded, color: L.green, size: 18),
              label: Text('Add New',
                  style: TextStyle(
                      color: L.green, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (med.schedule.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.5)),
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
                FadeEffect(duration: 400.ms, curve: Curves.easeOut),
                SlideEffect(begin: const Offset(0, 0.05), duration: 400.ms, curve: Curves.easeOut),
              ],
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: L.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 6, color: medColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: s.enabled ? L.text : L.sub,
                                          letterSpacing: -1.0)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: L.fill,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(s.label.toUpperCase(),
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: L.sub,
                                            letterSpacing: 0.5)),
                                  ),
                                ]),
                                AppToggle(
                                    value: s.enabled,
                                    onChanged: (v) {
                                      HapticFeedback.lightImpact();
                                      state.toggleSchedule(med.id, idx);
                                    }),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Days Indicator
                                Wrap(
                                  spacing: 4,
                                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                      .asMap()
                                      .entries
                                      .map((e) {
                                    final isScheduled = s.days.contains(e.key);
                                    return Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isScheduled
                                            ? const Color(0xFF111111)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: isScheduled ? const Color(0xFF111111) : L.border,
                                            width: 1),
                                      ),
                                      child: Center(
                                          child: Text(e.value,
                                              style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: isScheduled ? Colors.white : L.sub))),
                                    );
                                  }).toList(),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    state.removeSchedule(med.id, idx);
                                  },
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 18, color: L.red.withValues(alpha: 0.7)),
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
        const SizedBox(height: 40),
      ],
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
            label: 'Medicine Name',
            value: _editFields['name'],
            onChanged: (v) => _editFields['name'] = v),
        const SizedBox(height: 14),
        LightInput(
            label: 'Brand Name',
            value: _editFields['brand'],
            placeholder: 'Optional',
            onChanged: (v) => _editFields['brand'] = v),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: LightInput(
                  label: 'Dosage',
                  value: _editFields['dose'],
                  placeholder: '500mg',
                  onChanged: (v) => _editFields['dose'] = v)),
          const SizedBox(width: 10),
          Expanded(
              child: LightInput(
                  label: 'Form',
                  value: _editFields['form'],
                  placeholder: 'tablet',
                  onChanged: (v) => _editFields['form'] = v)),
        ]),
        const SizedBox(height: 14),
        LightInput(
            label: 'Category',
            value: _editFields['category'],
            onChanged: (v) => _editFields['category'] = v),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: LightInput(
                  label: 'Count left',
                  value: _editFields['count'],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _editFields['count'] = v)),
          const SizedBox(width: 10),
          Expanded(
              child: LightInput(
                  label: 'Pack size',
                  value: _editFields['totalCount'],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _editFields['totalCount'] = v)),
          const SizedBox(width: 10),
          Expanded(
              child: LightInput(
                  label: 'Alert at',
                  value: _editFields['refillAt'],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _editFields['refillAt'] = v)),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Cancel',
                  onTap: () => setState(() => _editMode = false),
                  color: L.sub,
                  isGhost: true)),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: _ActionBtn(
                  label: 'Save Changes',
                  onTap: () {
                    state.updateMed(
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
                    );
                    setState(() => _editMode = false);
                  },
                  color: const Color(0xFF111111))),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final String? sub;
  final Color color;
  final AppThemeColors L;
  const _StatItem(
      {required this.label,
      required this.value,
      this.sub,
      required this.color,
      required this.L});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: L.sub,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1)),
        if (sub != null)
          Text(sub!,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: L.sub)),
      ]);
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _TabBtn(
      {required this.label,
      required this.active,
      required this.onTap,
      required this.L});
  @override
  Widget build(BuildContext context) => Expanded(
          child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? L.card : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? L.text : L.sub)),
        ),
      ));
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
            borderRadius: BorderRadius.circular(18),
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
                    color: L.text, fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
        ]),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final bool isGhost;
  const _ActionBtn(
      {required this.label,
      required this.onTap,
      required this.color,
      this.icon,
      this.isGhost = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isGhost ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(14),
            border: isGhost
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8)
            ],
            Text(label,
                style: TextStyle(
                    color: isGhost ? color : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ]),
        ),
      );
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}
