import 'package:flutter/material.dart';
import 'dart:async';

class SmoothingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration speed;
  final bool animate;

  const SmoothingText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.speed = const Duration(milliseconds: 20),
    this.animate = true,
  });

  @override
  State<SmoothingText> createState() => _SmoothingTextState();
}

class _SmoothingTextState extends State<SmoothingText> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _startAnimation();
    } else {
      _displayedText = widget.text;
    }
  }

  @override
  void didUpdateWidget(SmoothingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _currentIndex = 0;
      _displayedText = "";
      _timer?.cancel();
      if (widget.animate) {
        _startAnimation();
      } else {
        setState(() => _displayedText = widget.text);
      }
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
