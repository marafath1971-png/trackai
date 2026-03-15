import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  } else if (h.length == 8) {
    return Color(int.parse(h, radix: 16));
  }
  return Colors.transparent;
}

String colorToHex(Color color) {
  return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2);
}
