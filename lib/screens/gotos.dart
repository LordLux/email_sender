import 'dart:math';

import 'package:email_sender/src/classes.dart';
import 'package:excel/excel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../src/manager.dart';
import 'excel.dart';
import 'gruppi.dart';

void gotoExcel(BuildContext context, {bool pick = true, bool highlight = true, Map<String, dynamic>? goto}) async {
  context.go('/excel');
  while (excelKey.currentState == null) await Future.delayed(const Duration(milliseconds: 50));
  //
  if (pick) excelKey.currentState?.pickExcelFile();
  if (highlight) {
    await Future.delayed(const Duration(milliseconds: 150));
    excelKey.currentState!.setState(() {
      excelKey.currentState!.isHighlighted = true;
    });
  }
  //
  if (goto != null) {
    List<Ufficio> uffici = Manager.uffici;
    for (int index = 0; index < uffici.length; index++) {
      final ufficio = uffici[index];
      final int entry = goto['entry'] - 2;
      //
      if (ufficio.nome == goto['ufficio']) //
        excelKey.currentState!.setState(() {
          excelKey.currentState?.currentUfficioIndex = index;
          excelKey.currentState?.highlightedErrorIndex = entry;
          print('Highlighting error at ${excelKey.currentState?.highlightedErrorIndex}');
        });
      //
      await Future.delayed(const Duration(milliseconds: 150));
      double offset = entry * 48.0;
      excelKey.currentState?.scrollController.animateTo(150 + offset, duration: Duration(milliseconds: (offset ~/ 500 * 400).clamp(100, 1000)), curve: Curves.easeInOut);
    }
  }
}

void gotoGruppi(BuildContext context, [bool? extra]) async {
  context.go('/gruppi');
  while (gruppiKey.currentState == null) await Future.delayed(const Duration(milliseconds: 50));
  await Future.delayed(const Duration(milliseconds: 150));

  if (extra == null) return;
  gruppiKey.currentState!.setState(() {
    if (!extra)
      gruppiKey.currentState!.isHighlighted = true;
    else
      gruppiKey.currentState!.isHighlighted2 = true;
  });
}
