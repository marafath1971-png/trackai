import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/gemini_service.dart';
import '../../domain/entities/entities.dart';

import '../common/app_loading_indicator.dart';
import '../common/refined_sheet_wrapper.dart';

class AskAiSheet extends StatefulWidget {
  final List<HealthInsight> contextInsights;

  const AskAiSheet({super.key, required this.contextInsights});

  @override
  State<AskAiSheet> createState() => _AskAiSheetState();
}

class _AskAiSheetState extends State<AskAiSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });

    final result = await GeminiService.askFollowUp(text, widget.contextInsights);

    if (mounted) {
      setState(() {
        _isLoading = false;
        result.fold(
          (success) => _messages.add({'role': 'ai', 'content': success}),
          (error) => _messages.add({'role': 'ai', 'content': error.message}),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return RefinedSheetWrapper(
      title: 'AI Health Coach',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.auto_awesome_rounded, color: L.text, size: 20),
      ),
      scrollable: false, // We use ListView internally for messaging
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Using Flexible + ListView for better responsiveness
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                      child: Text(
                        'Ask me anything about your current health insights or medications.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: L.sub, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isAi = msg['role'] == 'ai';
                      return Align(
                        alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isAi ? L.card : L.text,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomLeft: isAi ? const Radius.circular(4) : null,
                              bottomRight: !isAi ? const Radius.circular(4) : null,
                            ),
                            border: isAi ? Border.all(color: L.border.withValues(alpha: 0.1)) : null,
                            boxShadow: isAi ? null : [
                              BoxShadow(
                                color: L.text.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            msg['content']!,
                            style: TextStyle(
                              color: isAi ? L.text : L.bg,
                              fontSize: 14,
                              fontWeight: isAi ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Row(
                children: [
                  const AppLoadingIndicator(size: 14),
                  const SizedBox(width: 8),
                  Text('Coach is thinking...',
                      style: TextStyle(
                          color: L.sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
              boxShadow: L.shadowSoft,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: L.text, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: TextStyle(color: L.sub.withValues(alpha: 0.5), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send_rounded, color: L.text, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
