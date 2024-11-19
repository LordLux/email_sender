import 'package:flutter/material.dart';

String removeFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') ? path.substring(0, path.lastIndexOf('\\')) : "/";

String getFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') +1 ?path.substring(path.lastIndexOf('\\') + 1) : "/";

Size measureTextSize({
  required String text,
  required TextStyle textStyle,
  double maxWidth = double.infinity,
  int? maxLines,
}) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: textStyle),
    textDirection: TextDirection.ltr,
    maxLines: maxLines, // Allows for unlimited lines unless constrained
  );

  // Set layout constraints
  textPainter.layout(minWidth: 0, maxWidth: maxWidth);

  // Return the computed size
  return textPainter.size;
}