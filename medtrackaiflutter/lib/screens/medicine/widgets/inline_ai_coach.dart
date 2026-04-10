import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../services/gemini_service.dart';
import '../../../../core/utils/haptic_engine.dart';
import '../../../../widgets/shared/shared_widgets.dart';

class InlineAiCoach extends StatefulWidget {
  final Medicine medicine;
  final BodyImpactSummary? impact; // Can pass impact if available

  const InlineAiCoach({
    super.key,
    required this.medicine,
    this.impact,
  });

  static void show(BuildContext context, Medicine medicine, {BodyImpactSummary? impact}) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InlineAiCoach(medicine: medicine, impact: impact),
    );
  }

  @override
  State<InlineAiCoach> createState() => _InlineAiCoachState();
}

class _InlineAiCoachState extends State<InlineAiCoach> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': "Hi! I'm your MedAI Coach. What would you like to know about ${widget.medicine.name}?",
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticEngine.light();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Fabricate a context payload based on current medicine
    final contextEntries = [
      HealthInsight(
        category: 'Medicine Info',
        title: widget.medicine.name,
        body: 'Dose: ${widget.medicine.dose}, Form: ${widget.medicine.form}, Category: ${widget.medicine.category}. '
            'Instructions: ${widget.medicine.intakeInstructions}',
      ),
      if (widget.impact != null)
        HealthInsight(
          category: 'Pharmacokinetics', 
          title: 'Mechanism & Specs', 
          body: 'Mechanism: ${widget.impact!.mechanismOfAction}. Peaks at ${widget.impact!.peakHours} hours. '
              'Affects ${widget.impact!.bodySystems.join(', ')}.',
        )
    ];

    final result = await GeminiService.askFollowUp(text, contextEntries);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _messages.add({'role': 'ai', 'text': result.data});
          HapticEngine.success();
        } else {
          _messages.add({'role': 'ai', 'text': "Sorry, I couldn't process that right now. Please try again."});
          HapticEngine.heavyImpact();
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    // Suggest prompt chips
    final suggestions = widget.impact?.bodySystems.isNotEmpty == true 
      ? [
          "How does it affect my ${widget.impact!.bodySystems.first}?",
          "Can I take this on an empty stomach?",
          "What if I miss a dose?"
        ]
      : [
          "What are common side effects?",
          "How long until it works?",
          "Can I drink coffee with this?"
        ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Container(
           padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
           decoration: BoxDecoration(
             border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.1))),
           ),
           child: Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: L.secondary.withValues(alpha: 0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.auto_awesome_rounded, color: L.secondary, size: 20),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'MedAI Coach',
                       style: AppTypography.titleMedium.copyWith(
                         color: L.text, 
                         fontWeight: FontWeight.w900,
                         letterSpacing: -0.5,
                       ),
                     ),
                     Text(
                       'Discussing ${widget.medicine.name}',
                       style: AppTypography.labelSmall.copyWith(
                         color: L.sub,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ],
                 ),
               ),
               IconButton(
                 icon: Icon(Icons.close_rounded, color: L.sub),
                 onPressed: () => Navigator.pop(context),
               )
             ],
           ),
          ),

          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(L);
                }
                
                final msg = _messages[index];
                final isAI = msg['role'] == 'ai';
                
                return _buildBubble(msg['text']!, isAI, L);
              },
            ),
          ),

          // Suggestion Chips
          if (_messages.length < 3 && !_isLoading)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: L.meshBg,
                      side: BorderSide(color: L.border.withValues(alpha: 0.1)),
                      label: Text(suggestions[index], style: AppTypography.labelSmall.copyWith(color: L.text, fontWeight: FontWeight.w700)),
                      onPressed: () => _sendMessage(suggestions[index]),
                    ),
                  );
                },
              ),
            ),
            
          // Input Area
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: L.bg,
                border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: L.meshBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: L.border.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: AppTypography.bodyMedium.copyWith(color: L.text),
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: L.sub),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (s) => _sendMessage(s),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncingButton(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: L.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isAI, AppThemeColors L) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: L.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome_rounded, color: L.secondary, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isAI ? L.card : L.text,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: isAI ? Radius.zero : const Radius.circular(24),
                  bottomRight: isAI ? const Radius.circular(24) : Radius.zero,
                ),
                border: isAI ? Border.all(color: L.border.withValues(alpha: 0.1)) : null,
              ),
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isAI ? L.text : L.bg,
                  height: 1.4,
                  fontWeight: isAI ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!isAI) const SizedBox(width: 44), // Spacer for AI avatar width
        ],
      ),
    ).animate()
     .fadeIn(duration: 300.ms)
     .slideY(begin: 0.1, end: 0)
     .scaleXY(
        begin: isAI ? 0.95 : 1.0, 
        end: 1.0, 
        duration: isAI ? 600.ms : 100.ms, 
        curve: isAI ? Curves.elasticOut : Curves.easeOut);
  }

  Widget _buildTypingIndicator(AppThemeColors L) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: L.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome_rounded, color: L.secondary, size: 16),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0, color: L.sub),
                const SizedBox(width: 4),
                _Dot(delay: 200, color: L.sub),
                const SizedBox(width: 4),
                _Dot(delay: 400, color: L.sub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  final Color color;

  const _Dot({required this.delay, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ).animate(onPlay: (c) => c.repeat()).fade(duration: 600.ms, delay: delay.ms).then().fade(duration: 600.ms, begin: 1.0, end: 0.0);
  }
}
