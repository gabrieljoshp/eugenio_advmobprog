import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.fontFamily = 'Poppins',
    this.fontWeight = FontWeight.normal,
    this.color,
    this.textAlign = TextAlign.left,
    this.letterSpacing = 0,
    this.fontStyle = FontStyle.normal,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double fontSize, letterSpacing;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final String fontFamily;
  final FontStyle fontStyle;

  // Nullable so we can automatically determine the color
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        color: color ?? (themeProvider.isDark ? Colors.white : Colors.black),
      ),
    );
  }
}
