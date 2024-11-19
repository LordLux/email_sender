import 'dart:io';

import 'package:email_sender/classes.dart';
import 'package:email_sender/vars.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:email_validator/email_validator.dart';
import 'package:recase/recase.dart';

import '../functions.dart';
import '../main.dart';
import '../manager.dart';
import '../theme.dart';
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
  List<Ufficio>? data;
  bool noFile = true;
  FlyoutController renameFlyoutController = FlyoutController();
  TextEditingController renameController = TextEditingController();

  int currentUfficioIndex = 0;

  void goToPreviousPage() {
    if (currentUfficioIndex > 0) setState(() => currentUfficioIndex--);
  }

  void goToNextPage() {
    if (currentUfficioIndex < Manager.uffici.length - 1) setState(() => currentUfficioIndex++);
  }

  void copyMailToClipBoard(String text) {
    print("Copying mail to clipboard: '$text'");
    Clipboard.setData(ClipboardData(text: text));
    mat.ScaffoldMessenger.of(context).showSnackBar(const mat.SnackBar(content: Text('Mail copiata negli appunti')));
  }

  //

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
    if (kDebugMode) print('Manager.excelPath: ${Manager.excelPath}');

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

  Future<void> reloadData() async {
    await Manager.loadExcel();
    data = Manager.uffici;
    setState(() {});
  }

  Future<void> _loadData() async {
    data = null;
    if (Manager.excelPath == null) {
      setState(() => noFile = true);
      if (kDebugMode) print('No file selected');
      return;
    }

    setState(() => noFile = false);
    File file = File(Manager.excelPath!);

    if (file.existsSync()) {
      await Manager.loadExcel(); // Reload data from the Excel file
      data = Manager.uffici; // Update the local data
      if (kDebugMode) print('File exists, loaded: \'${Manager.excelPath}\'');
    } else if (kDebugMode) {
      print('File does not exist');
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final appTheme = context.watch<AppTheme>();

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Excel')),
      children: [
        // SELEZIONA FILE
        if (noFile)
          CardHighlight(
            child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('Nessun file selezionato'),
              FilledButton(
                onPressed: pickExcelFile,
                child: const Text('Seleziona file'),
              ),
            ]),
          ),
        if (!noFile)
          Card(
            child: mat.Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              //
              // FILE SELEZIONATO
              Flexible(child: Text('File selezionato: ${Manager.excelPath}')),
              mat.Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                //
                // RICARICA
                IconButton(icon: const Icon(mat.Icons.restart_alt, size: 17), onPressed: () => reloadData()),
                const SizedBox(width: 6),
                //
                // CAMBIA FILE
                FilledButton(
                  onPressed: pickExcelFile,
                  child: const Text('Cambia file'),
                ),
                const SizedBox(width: 6),
                //
                // RINOMINA
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
            ]),
          ),
        biggerSpacer,
        // TABELLA
        if (!noFile && data != null && data!.isNotEmpty && (currentUfficioIndex != 0 || currentUfficioIndex != Manager.uffici.length - 1))
          Card(
            child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, children: [
              mat.Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  currentUfficioIndex != 0
                      ? FilledButton(
                          onPressed: () => goToPreviousPage(),
                          child: const Text('Pagina Precedente'),
                        )
                      : const SizedBox(width: 138),
                  const SizedBox(width: 20),
                  Text('Pagina ${currentUfficioIndex + 1} di ${Manager.uffici.length}'),
                  const SizedBox(width: 20),
                  currentUfficioIndex != Manager.uffici.length - 1
                      ? FilledButton(
                          onPressed: () => goToNextPage(),
                          child: const Text('Pagina Successiva'),
                        )
                      : const SizedBox(width: 135),
                ],
              ),
            ]),
          ),
        spacer,
        if (!noFile && data != null)
          Builder(builder: (context) {
            if (Manager.uffici.isEmpty) return const Text('Nessun file selezionato');
            //print('refreshed: currentUfficioIndex: $currentUfficioIndex');
            final Ufficio ufficio = Manager.uffici[currentUfficioIndex];
            return Card(
              child: Center(
                child: Wrap(alignment: WrapAlignment.center, 
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                spacing: 10.0, children: [
                  Center(child: Text('Ufficio: ${ufficio.nome.titleCase}', style: FluentTheme.of(context).typography.subtitle!)),
                  if (Manager.uffici.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: mat.DataTable(
                        columnSpacing: 140,
                        columns: List<mat.DataColumn>.generate(
                          ufficio.headers.length,
                          (index) {
                            final isMailColumn = ufficio.headers[index].toLowerCase() == "mail";
                            return mat.DataColumn(
                              label: Listener(
                                onPointerDown: (PointerDownEvent event) {
                                  if (event.kind == PointerDeviceKind.mouse && event.buttons == kSecondaryMouseButton) {
                                    copyMailToClipBoard(ufficio.headers[index]);
                                  }
                                },
                                child: SizedBox(
                                  width: isMailColumn ? 300 : null,
                                  child: Text(ufficio.headers[index], style: FluentTheme.of(context).typography.subtitle!),
                                ),
                              ),
                            );
                          },
                        ),
                        rows: List<mat.DataRow>.generate(
                          ufficio.entries.length,
                          (index) => mat.DataRow(
                            cells: List<mat.DataCell>.generate(
                              ufficio.entries[index].length,
                              (i) => mat.DataCell(
                                SizedBox(
                                  width: ufficio.headers[i].toLowerCase() == "mail" ? 300 : null,
                                  child: Text(ufficio.entries[index][i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            );
          }),
      ],
    );
  }
}
