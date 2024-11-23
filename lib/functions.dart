import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mat;

import 'main.dart';

/// Removes the file name from a path (effectively returning the directory)
String removeFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') ? path.substring(0, path.lastIndexOf('\\')) : "/";

/// Returns the file name from a path (extnsion included)
String getFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') + 1 ? path.substring(path.lastIndexOf('\\') + 1) : "/";

String getFileExtension(String path) => path.length > path.lastIndexOf('.') ? path.substring(path.lastIndexOf('.')) : "/";

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

void snackBar(String message, {Color color = mat.Colors.white, InfoBarSeverity severity = InfoBarSeverity.info}) {
  /*final messenger = mat.ScaffoldMessenger.of(rootNavigatorKey.currentState!.context);
  messenger.showSnackBar(
    mat.SnackBar(
      content: Acrylic(child: Text(message, style: const TextStyle(color: mat.Colors.white))),
      duration: const Duration(seconds: 2),
    ),
  );*/
  displayInfoBar(
    rootNavigatorKey.currentState!.context,
    builder: (context, close) => InfoBar(
      title: Text(message),
      severity: severity,
      style: InfoBarThemeData(
        icon: (severity) {
          switch (severity) {
            case InfoBarSeverity.info:
              return mat.Icons.info;
            case InfoBarSeverity.warning:
              return mat.Icons.warning;
            case InfoBarSeverity.error:
              return mat.Icons.error;
            case InfoBarSeverity.success:
              return mat.Icons.check_circle;
          }
        },
      ),
    ),
  );
}

void updateInfoBadge(String keyValue, InfoBadge? newBadge, [bool setState = true]) {
  // Find the index of the item with the given key
  final index = homePageKey.currentState!.originalItems.indexWhere((item) => (item.key as ValueKey?)?.value == keyValue);

  if (index != -1 && homePageKey.currentState!.originalItems[index] is PaneItem) {
    final existingItem = homePageKey.currentState!.originalItems[index] as PaneItem;

    // Replace the existing item with a new one, preserving other properties
    homePageKey.currentState!.originalItems[index] = PaneItem(
      key: existingItem.key,
      icon: existingItem.icon,
      title: existingItem.title,
      body: existingItem.body,
      infoBadge: newBadge, // Set the new InfoBadge
      onTap: existingItem.onTap,
    );
  }
  if (setState) homePageKey.currentState!.setState(() {});
}
