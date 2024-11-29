import 'dart:math';
import 'dart:io';

import 'package:email_sender/screens/excel.dart';
import 'package:email_sender/screens/gotos.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';

import 'main.dart';
import 'src/classes.dart';

/// Removes the file name from a path (effectively returning the directory)
String removeFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') ? path.substring(0, path.lastIndexOf('\\')) : "/";

/// Returns the file name from a path (extnsion included)
String getFileNameFromPath(String path) => path.length > path.lastIndexOf('\\') + 1 ? path.substring(path.lastIndexOf('\\') + 1) : "/";

String getFileExtension(String path) => path.length > path.lastIndexOf('.') && path.lastIndexOf('.') != -1 ? path.substring(path.lastIndexOf('.')) : "/";

fluent.Size measureTextSize({
  required String text,
  fluent.TextStyle textStyle = const fluent.TextStyle(),
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
  if (severity == fluent.InfoBarSeverity.error && kDebugMode) print("Error: $message");

  fluent.displayInfoBar(
    duration: severity == fluent.InfoBarSeverity.error ? const Duration(seconds: 10) : const Duration(seconds: 3),
    alignment: severity == fluent.InfoBarSeverity.error ? fluent.Alignment.bottomRight : fluent.Alignment.bottomCenter,
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

double calculateChipWidth(fluent.BuildContext context, String content, {double extraPadding = 65.0}) {
  const double iconPadding = 24.0; // Padding for the chip's icon
  final fluent.TextPainter textPainter = fluent.TextPainter(
    text: fluent.TextSpan(
      text: content,
      style: const fluent.TextStyle(fontSize: 14.0), // Match the chip's text style
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();

  // Add padding for the chip's icon, spacing, and internal padding
  return textPainter.width + extraPadding + iconPadding;
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

// Overlay functions
mat.ValueNotifier<fluent.OverlayEntry?> overlayEntry = fluent.ValueNotifier(null);

void removeOverlay() {
  if (overlayEntry.value != null) overlayEntry.value!.remove();
  fluent.WidgetsBinding.instance.addPostFrameCallback((_) {
    overlayEntry.value = null;
  });
}

void showNonModalDialog(fluent.BuildContext context, fluent.Widget dialogContent, fluent.BoxConstraints constraints) {
  final overlay = fluent.Overlay.of(context);

  overlayEntry.value = fluent.OverlayEntry(
    builder: (context) {
      return fluent.Stack(
        children: [
          // Dark semi-transparent background
          fluent.Positioned.fill(
            child: fluent.GestureDetector(
              behavior: fluent.HitTestBehavior.opaque, // Block taps from passing through the background
              onTap: () {
                print("Tapped background");
                removeOverlay(); // Dismiss the dialog
              }, // Block taps from passing through the background
              child: fluent.Container(
                color: mat.Colors.black54, // Semi-transparent black background
              ),
            ),
          ),
          // Top GestureDetector for dismissing the dialog
          fluent.Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80.0, // Top 80px dismiss area
            child: fluent.GestureDetector(
              behavior: fluent.HitTestBehavior.translucent,
              onTap: () {
                print("Tapped top of dialog");
                removeOverlay(); // Dismiss the dialog
              },
            ),
          ),
          // Centered Dialog
          fluent.Center(
            child: fluent.Builder(builder: (context) {
              double maxWidth = min(constraints.maxWidth - 200, 1200.0);
              double maxHeight = min(mat.MediaQuery.of(context).size.height - 180, 800.0);
              return fluent.ConstrainedBox(
                constraints: fluent.BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
                child: mat.Container(
                  //color: mat.Colors.amber,
                  width: maxWidth,
                  height: maxHeight,
                  child: fluent.GestureDetector(
                    behavior: fluent.HitTestBehavior.translucent, // Allows the child to block tap events
                    onTap: () {
                      print("Tapped inside dialog");
                    }, // Prevents dismissal when clicking inside the dialog
                    child: fluent.FluentTheme(
                      data: fluent.FluentTheme.of(context),
                      child: fluent.Center(
                        child: dialogContent,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    },
  );

  overlay.insert(overlayEntry.value!);
}

bool isEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool validateEmails(List<Ufficio>? data, BuildContext context) {
  if (data == null) return false;
  for (Ufficio ufficio in data) {
    for (List<String> entry in ufficio.entries) {
      //print('entry: $entry');
      if (entry[2].isNotEmpty && !isEmail(entry[2])) {
        snackBar('Errore nell\'Ufficio ${ufficio.nome} a riga ${ufficio.entries.indexOf(entry) + 2}:\nIndirizzo Email non valido: "${entry[2]}"', severity: InfoBarSeverity.error);
        gotoExcel(context, goto: {'ufficio': ufficio.nome, 'entry': ufficio.entries.indexOf(entry) + 2}, highlight: false, pick: false);
        return false;
      }
    }
  }
  return true;
}

void checkEmails(List<Ufficio>? data, BuildContext context, VoidCallback setState) {
  if (validateEmails(data, context)) {
    infoBadge('/excel', true, false);
    excelKey.currentState?.highlightedErrorIndex = -1;
  } else {
    infoBadge('/excel', false, false);
    if (kDebugMode) print('Invalid emails');
  }
  setState();
}

void openFile(String path) async {
  if (path.isEmpty) {
    snackBar('Nessun file selezionato', severity: InfoBarSeverity.warning);
    return;
  }
  if (!File(path).existsSync()) {
    snackBar('Il file selezionato non esiste', severity: InfoBarSeverity.error);
    return;
  }
  await Future.microtask(
    () => OpenFile.open(path),
  );
}
