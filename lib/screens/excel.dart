import 'dart:io';

import 'package:email_sender/classes.dart';
import 'package:email_sender/vars.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recase/recase.dart';
import 'package:smooth_highlight/smooth_highlight.dart';

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

final excelKey = GlobalKey<_ExcelScreenState>();

class _ExcelScreenState extends State<ExcelScreen> with PageMixin {
  List<Ufficio>? data;
  bool noFile = true;
  bool openingPickDialog = false;
  FlyoutController renameFlyoutController = FlyoutController();
  TextEditingController renameController = TextEditingController();
  bool isHighlighted = false;

  int currentUfficioIndex = 0;

  void goToPreviousPage() {
    if (currentUfficioIndex > 0) setState(() => currentUfficioIndex--);
  }

  void goToNextPage() {
    if (currentUfficioIndex < Manager.uffici.length - 1) setState(() => currentUfficioIndex++);
  }

  //

  Future<void> pickExcelFile() async {
    if (openingPickDialog) return;
    openingPickDialog = true;
    Manager.excelPath = (await FilePicker.platform.pickFiles(
          allowMultiple: false,
          allowedExtensions: ['xlsx', 'xls', 'csv'],
          lockParentWindow: true,
          type: FileType.custom,
          dialogTitle: "Seleziona il file Excel",
          initialDirectory: (Manager.excelPath != null && Manager.excelPath!.isNotEmpty) ? removeFileNameFromPath(Manager.excelPath!) : (await getApplicationDocumentsDirectory()).path,
        ))
            ?.files[0]
            .path ??
        Manager.excelPath;
    SettingsManager.saveSettings({"excelPath": Manager.excelPath});
    if (kDebugMode) print('Manager.excelPath: ${Manager.excelPath}');

    await loadData();
    openingPickDialog = false;
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
    loadData();
  }

  Future<void> reloadData() async {
    await Manager.loadExcel();
    data = Manager.uffici;
    setState(() {});
  }

  Future<void> loadData() async {
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

      updateInfoBadge("/excel", const InfoBadge(source: Icon(mat.Icons.check), color: mat.Colors.lightGreen), true);
    } else {
      updateInfoBadge("/excel", null, true);
      if (kDebugMode) print('File does not exist');
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (Manager.uffici.isEmpty)
      loadData();
    else {
      noFile = false;
      data = Manager.uffici;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Excel')),
      children: [
        // SELEZIONA FILE
        if (noFile)
          ValueChangeHighlight(
            duration: const Duration(milliseconds: 300),
            value: isHighlighted,
            color: FluentTheme.of(context).accentColor.withOpacity(.5),
            child: CardHighlight(
              child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Nessun file Excel selezionato'),
                FilledButton(
                  onPressed: pickExcelFile,
                  child: const Text('Seleziona file'),
                ),
              ]),
            ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                spacer,
                Center(child: Text('Numero Uffici: ${Manager.uffici.length}', style: FluentTheme.of(context).typography.subtitle)),
                spacer,
                spacer,
                Wrap(alignment: WrapAlignment.center, spacing: 10.0, children: [
                  mat.Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      currentUfficioIndex != 0
                          ? FilledButton(
                              onPressed: () => goToPreviousPage(),
                              child: const Row(
                                children: [
                                  Icon(mat.Icons.keyboard_arrow_left_outlined, size: 15),
                                  SizedBox(width: 6),
                                  Text('Pagina Precedente'),
                                ],
                              ),
                            )
                          : const SizedBox(width: 138),
                      const SizedBox(width: 20),
                      Text('Pagina ${currentUfficioIndex + 1} di ${Manager.uffici.length}'),
                      const SizedBox(width: 20),
                      currentUfficioIndex != Manager.uffici.length - 1
                          ? FilledButton(
                              onPressed: () => goToNextPage(),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Pagina Successiva'),
                                  SizedBox(width: 6),
                                  Icon(mat.Icons.keyboard_arrow_right_outlined, size: 15),
                                ],
                              ),
                            )
                          : const SizedBox(width: 135),
                    ],
                  ),
                ]),
                spacer,
              ],
            ),
          ),
        spacer,
        if (!noFile && data != null)
          Builder(builder: (context) {
            if (Manager.uffici.isEmpty) return const Text('Nessun file selezionato');
            //print('refreshed: currentUfficioIndex: $currentUfficioIndex');
            final Ufficio ufficio = Manager.uffici[currentUfficioIndex];
            return Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, direction: Axis.vertical, spacing: 10.0, children: [
                    spacer,
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Ufficio: ${ufficio.nome} ',
                          style: FluentTheme.of(context).typography.subtitle,
                          children: [
                            TextSpan(
                              text: '(${ufficio.entries.length} destinatari)',
                              style: FluentTheme.of(context).typography.subtitle!.copyWith(
                                    color: FluentTheme.of(context).typography.subtitle!.color!.withOpacity(0.5),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    spacer,
                    if (Manager.uffici.isNotEmpty)
                      mat.DataTable(
                        columnSpacing: 10,
                        columns: List<mat.DataColumn>.generate(
                          ufficio.headers.length,
                          (index) {
                            double? width;
                            switch (ufficio.headers[index].toLowerCase()) {
                              case 'mail':
                                width = 300;
                                break;
                              case 'comune':
                                width = 150;
                                break;
                              case 'nome':
                                width = 250;
                                break;
                            }
                            return mat.DataColumn(
                              label: SizedBox(
                                width: width,
                                child: Text(ufficio.headers[index], style: FluentTheme.of(context).typography.subtitle!),
                              ),
                            );
                          },
                        ),
                        rows: List<mat.DataRow>.generate(
                          ufficio.entries.length,
                          (index) => mat.DataRow(
                            cells: List<mat.DataCell>.generate(ufficio.entries[index].length, (i) {
                              double? width;
                              switch (ufficio.entries[index][i].toLowerCase()) {
                                case 'mail':
                                  width = 300;
                                  break;
                                case 'comune':
                                  width = 150;
                                  break;
                                case 'nome':
                                  width = 250;
                                  break;
                              }
                              return mat.DataCell(
                                SizedBox(
                                  width: width,
                                  child: Text(ufficio.entries[index][i]),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            );
          }),
      ],
    );
  }
}
