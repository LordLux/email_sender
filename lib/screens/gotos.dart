import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import 'excel.dart';
import 'gruppi.dart';

void gotoExcel(BuildContext context) async {
  context.go('/excel');
  while (excelKey.currentState == null) await Future.delayed(const Duration(milliseconds: 50));
  excelKey.currentState?.pickExcelFile();
  await Future.delayed(const Duration(milliseconds: 150));
  excelKey.currentState!.setState(() {
    excelKey.currentState!.isHighlighted = true;
  });
}

void gotoGruppi(BuildContext context) async {
  context.go('/gruppi');
  while (gruppiKey.currentState == null) await Future.delayed(const Duration(milliseconds: 50));
  await Future.delayed(const Duration(milliseconds: 150));
  gruppiKey.currentState!.setState(() {
    gruppiKey.currentState!.isHighlighted = true;
  });
}