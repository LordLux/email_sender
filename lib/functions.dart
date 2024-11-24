import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';

import 'main.dart';

/// Removes the file name from a path (effectively returning the directory)
String removeFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') ? path.substring(0, path.lastIndexOf('\\')) : "/";

/// Returns the file name from a path (extnsion included)
String getFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') + 1 ? path.substring(path.lastIndexOf('\\') + 1) : "/";

String getFileExtension(String path) => path.length > path.lastIndexOf('.') ? path.substring(path.lastIndexOf('.')) : "/";

fluent.Size measureTextSize({
  required String text,
  required fluent.TextStyle textStyle,
  double maxWidth = double.infinity,
  int? maxLines,
}) {
  final fluent.TextPainter textPainter = fluent.TextPainter(
    text: fluent.TextSpan(text: text, style: textStyle),
    textDirection: fluent.TextDirection.ltr,
    maxLines: maxLines, // Allows for unlimited lines unless constrained
  );

  // Set layout constraints
  textPainter.layout(minWidth: 0, maxWidth: maxWidth);

  // Return the computed size
  return textPainter.size;
}

void snackBar(String message, {fluent.Color color = const mat.Color(0xFF333333), fluent.InfoBarSeverity severity = fluent.InfoBarSeverity.info, bool hasError = false}) {
  fluent.displayInfoBar(
    rootNavigatorKey.currentState!.context,
    builder: (context, close) => mat.Container(
      decoration: fluent.BoxDecoration(
        color: color,
        borderRadius: const mat.BorderRadius.all(mat.Radius.circular(8.0)),
      ),
      child: fluent.InfoBar(
        title: fluent.Text(message),
        severity: severity,
        isLong: hasError,
        style: fluent.InfoBarThemeData(
          icon: (severity) {
            switch (severity) {
              case fluent.InfoBarSeverity.info:
                return mat.Icons.info;
              case fluent.InfoBarSeverity.warning:
                return mat.Icons.warning;
              case fluent.InfoBarSeverity.error:
                return mat.Icons.error;
              case fluent.InfoBarSeverity.success:
                return mat.Icons.check_circle;
            }
          },
        ),
      ),
    ),
  );
}

void updateInfoBadge(String keyValue, fluent.InfoBadge? newBadge, [bool setState = true]) {
  // Find the index of the item with the given key
  int index = myHomePageKey.currentState!.originalItems.indexWhere((item) => (item.key as fluent.ValueKey?)?.value == keyValue);

  // If the item is found in the original items, update the InfoBadge
  if (index != -1 && myHomePageKey.currentState!.originalItems[index] is fluent.PaneItem) {
    final existingItem = myHomePageKey.currentState!.originalItems[index] as fluent.PaneItem;

    // Replace the existing item with a new one, preserving other properties
    myHomePageKey.currentState!.originalItems[index] = fluent.PaneItem(
      key: existingItem.key,
      icon: existingItem.icon,
      title: existingItem.title,
      body: existingItem.body,
      infoBadge: newBadge, // Set the new InfoBadge
      onTap: existingItem.onTap,
    );
  }
  // If the item is not found in the original items, search in the footer items

  if (index == -1) {
    index = myHomePageKey.currentState!.footerItems.indexWhere((item) => (item.key as fluent.ValueKey?)?.value == keyValue);
    if (index != -1 && myHomePageKey.currentState!.footerItems[index] is fluent.PaneItem) {
      final existingItem = myHomePageKey.currentState!.footerItems[index] as fluent.PaneItem;

      // Replace the existing item with a new one, preserving other properties
      myHomePageKey.currentState!.footerItems[index] = fluent.PaneItem(
        key: existingItem.key,
        icon: existingItem.icon,
        title: existingItem.title,
        body: existingItem.body,
        infoBadge: newBadge, // Set the new InfoBadge
        onTap: existingItem.onTap,
      );
    }
  }

  if (setState) myHomePageKey.currentState!.setState(() {});
}

void infoBadge(String keyValue, [bool? badge, bool setState = true]) {
  if (badge == null) {
    updateInfoBadge(keyValue, null, setState);
  } else if (badge == true) {
    updateInfoBadge(
      keyValue,
      const fluent.InfoBadge(
        source: fluent.Icon(mat.Icons.check, size: 12.0),
        color: mat.Colors.lightGreen,
      ),
      setState,
    );
  } else {
    updateInfoBadge(
      keyValue,
      fluent.InfoBadge(
        source: fluent.Transform.translate(offset: const fluent.Offset(-0.5, 0), child: const fluent.Icon(mat.Icons.priority_high, size: 11.0)),
        color: mat.Colors.red,
      ),
      setState,
    );
  }
}

// Ellipsize by trimming the middle of the text
String ellipsizeText(
  String text,
  double length, {
  final fluent.TextStyle style = const fluent.TextStyle(),
  final String ellipsis = '...',
}) {
  final textPainter = fluent.TextPainter(
    text: fluent.TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);

  if (textPainter.width <= length) {
    // Text fits without truncation
    return text;
  }

  // Calculate the truncation point
  final ellipsisPainter = fluent.TextPainter(
    text: fluent.TextSpan(text: ellipsis, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);

  final double ellipsisWidth = ellipsisPainter.width;
  final double availableWidth = length - ellipsisWidth;
  final double charWidth = textPainter.width / text.length;

  // Determine the number of characters that can fit on each side of the ellipsis
  final int charsToShow = (availableWidth / (2 * charWidth)).floor();
  final String startText = text.substring(0, charsToShow);
  final String endText = text.substring(text.length - charsToShow);

  // Create the final truncated text
  final truncatedText = '$startText$ellipsis$endText';

  return truncatedText;
}

void copyToClipboard(String text) {
  Clipboard.setData(ClipboardData(text: text));
  snackBar("'$text' copiato negli appunti");
}
