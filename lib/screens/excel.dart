import 'dart:io';

import 'package:email_sender/vars.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';

import '../functions.dart';
import '../main.dart';
import '../manager.dart';
import '../widgets/card_highlight.dart';
import '../widgets/page.dart';

class ExcelScreen extends StatefulWidget {
  const ExcelScreen({super.key});

  @override
  State<ExcelScreen> createState() => _ExcelScreenState();
}

class _ExcelScreenState extends State<ExcelScreen> with PageMixin {
  bool selected = true;
  String? comboboxValue;
  final Workbook workbook = Workbook();
  List<Map<String, String>>? data;
  bool noFile = true;
  FlyoutController renameFlyoutController = FlyoutController();
  TextEditingController renameController = TextEditingController();

  Future<void> generateExcelFile() async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    sheet.getRangeByName('A1').setText('Name');
    sheet.getRangeByName('B1').setText('Mail');
    sheet.getRangeByName('C1').setText('Extra');

    Manager.excelPath = '${(await getApplicationDocumentsDirectory()).path}\\excel.xlsx';
    SettingsManager.saveSettings({"excelPath": Manager.excelPath});

    final List<int> bytes = workbook.saveAsStream();
    final File file = File(Manager.excelPath!);
    file.writeAsBytes(bytes);
    workbook.dispose();

    _loadData();
  }

  Future<void> pickExcelFile() async {
    Manager.excelPath = (await FilePicker.platform.pickFiles(
          allowMultiple: false,
          allowedExtensions: ['xlsx', 'xls', 'csv'],
          lockParentWindow: true,
          type: FileType.custom,
          dialogTitle: "Seleziona il file Excel",
          initialDirectory: Manager.excelPath != null ? removeFileNameFromPath(Manager.excelPath!) : (await getApplicationDocumentsDirectory()).path,
        ))
            ?.files[0]
            .path ??
        Manager.excelPath;
    SettingsManager.saveSettings({"excelPath": Manager.excelPath});
    print('Manager.excelPath: ${Manager.excelPath}');
    _loadData();
  }

  Future<void> rename(String name) async {
    final String newName;
    if (name.endsWith('.xlsx') || name.endsWith('.xls') || name.endsWith('.csv'))
      newName = name;
    else
      newName = '$name.xlsx';

    final File file = File(Manager.excelPath!);
    final String newPath = '${removeFileNameFromPath(Manager.excelPath!)}\\$newName';
    await file.rename(newPath);
    Manager.excelPath = newPath;
    SettingsManager.saveSettings({"excelPath": Manager.excelPath});
    _loadData();
  }

  Future<void> _loadData() async {
    if (Manager.excelPath == null) {
      //await pickExcelFile();
      if (Manager.excelPath == null) {
        setState(() => noFile = true);
        print('No file selected');
        return;
      }
    }
    setState(() => noFile = false);
    File file = File(Manager.excelPath!);
    if (file.existsSync()) {
      data = await Manager.loadExcelData(file);
      print('File exists loaded');
    } else
      print('File does not exist');

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    print('Manager.excelPath: ${Manager.excelPath}');
    _loadData();
  }

  @override
  void dispose() {
    workbook.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Excel')),
      children: [
        if (noFile)
          CardHighlight(
            child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('Nessun file selezionato'),
              FilledButton(
                onPressed: pickExcelFile,
                child: const Text('Seleziona file'),
              ),
              Button(
                onPressed: generateExcelFile,
                child: const Text('Genera file'),
              ),
            ]),
          ),
        if (!noFile)
          Card(
            child: mat.Row(children: [
              Text('File selezionato: ${Manager.excelPath}'),
              const Spacer(),
              FilledButton(
                onPressed: pickExcelFile,
                child: const Text('Cambia file'),
              ),
              const SizedBox(width: 6),
              FlyoutTarget(
                  controller: renameFlyoutController,
                  child: Button(
                    child: const Text('Rinomina file'),
                    onPressed: () {
                      renameFlyoutController.showFlyout(
                        autoModeConfiguration: FlyoutAutoConfiguration(
                          preferredMode: FlyoutPlacementMode.left,
                        ),
                        barrierDismissible: true,
                        dismissOnPointerMoveAway: false,
                        dismissWithEsc: true,
                        navigatorKey: rootNavigatorKey.currentState,
                        builder: (context) {
                          return FlyoutContent(
                            child: mat.Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rinomina il file', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12.0),
                                SizedBox(
                                  width: 400.0,
                                  child: TextBox(
                                    autofocus: true,
                                    controller: renameController,
                                    placeholder: getFileNameFromPath(Manager.excelPath!),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(50),
                                      FilteringTextInputFormatter.allow(RegExp(r'^[^<>:"/\\|?*\x00-\x1F]*$')),
                                    ],
                                    onSubmitted: (value) {
                                      rename(value);
                                      Flyout.of(context).close();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ))
            ]),
          ),
        spacer,
        if (!noFile && data != null)
          Card(
            child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, children: [
              SingleChildScrollView(
                child: mat.DataTable(
                  columns: const [
                    mat.DataColumn(label: Text('Name')),
                    mat.DataColumn(label: Text('Mail')),
                    mat.DataColumn(label: Text('Extra')),
                  ],
                  rows: data!
                      .map(
                        (item) => mat.DataRow(cells: [
                          mat.DataCell(Text(item['Name'] ?? '')),
                          mat.DataCell(Text(item['Mail'] ?? '')),
                          mat.DataCell(Text(item['Extra'] ?? '')),
                        ]),
                      )
                      .toList(),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
