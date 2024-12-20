import 'dart:io';

import 'package:email_sender/src/classes.dart';
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
import '../src/manager.dart';
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
  ScrollController scrollController = ScrollController();
  int highlightedErrorIndex = -1;

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
    checkEmails(data, context, () => setState(() {}));
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
      checkEmails(data, context, () => setState(() {}));
    } else {
      infoBadge('/excel', null);
      if (kDebugMode) print('File does not exist');
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (Manager.uffici.isEmpty)
      loadData();
    else {
      noFile = false;
      data = Manager.uffici;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkEmails(data, context, () => setState(() {}));
      });
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      scrollController: scrollController,
      header: Column(
        children: [
          const PageHeader(title: Text('Excel')),
          if (!noFile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                child: mat.Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  //
                  // FILE SELEZIONATO
                  Flexible(child: Text('File selezionato: ${Manager.excelPath}')),
                  mat.Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                    //
                    // RICARICA
                    FilledButton(
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mat.Icons.restart_alt, size: 17),
                            SizedBox(width: 4),
                            Text('Ricarica Uffici'),
                          ],
                        ),
                        onPressed: () => reloadData()),
                    const SizedBox(width: 6),
                    //
                    // APRI
                    FilledButton(
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mat.Icons.edit, size: 17),
                            SizedBox(width: 4),
                            Text('Modifica Uffici'),
                          ],
                        ),
                        onPressed: () => openFile(Manager.excelPath!)),
                    const SizedBox(width: 6),
                    //
                    // CAMBIA FILE
                    Button(
                      onPressed: pickExcelFile,
                      child: const Text('Cambia file'),
                    ),
                    /*const SizedBox(width: 6),*/
                    //
                    // RINOMINA
                    /*FlyoutTarget(
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
                        ))*/
                  ]),
                ]),
              ),
            ),
          spacer,
        ],
      ),
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
                      child: LayoutBuilder(builder: (context, constraints) {
                        return Text.rich(
                          TextSpan(
                            text: 'Ufficio: ${ellipsizeText(ufficio.nome, constraints.maxWidth)} ',
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
                        );
                      }),
                    ),
                    spacer,
                    if (Manager.uffici.isNotEmpty)
                      mat.DataTable(
                        columnSpacing: 10,
                        columns: List<mat.DataColumn>.generate(
                          ufficio.headers.length,
                          (index) {
                            double width = 100;
                            switch (index) {
                              case 2:
                                width = 300;
                                break;
                              case 1:
                                width = 200;
                                break;
                              case 0:
                                width = 250;
                                break;
                            }

                            /// The DataColumn widget is used to define the columns of the DataTable.
                            return mat.DataColumn(
                              label: SizedBox(
                                width: width,
                                child: Text(ellipsizeText(ufficio.headers[index], width), style: FluentTheme.of(context).typography.subtitle!, textAlign: TextAlign.center),
                              ),
                            );
                          },
                        ),
                        rows: List<mat.DataRow>.generate(
                          ufficio.entries.length,
                          (index) => mat.DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (highlightedErrorIndex == index) return Colors.red.withOpacity(.2);
                              return null;
                            }),
                            cells: List<mat.DataCell>.generate(ufficio.entries[index].length, (i) {
                              double width = 100;

                              switch (i) {
                                case 2:
                                  width = 300;
                                  break;
                                case 1:
                                  width = 200;
                                  break;
                                case 0:
                                  width = 250;
                                  break;
                              }

                              /// The DataCell widget is used to define the cells of the DataTable.
                              return mat.DataCell(
                                SizedBox(
                                  width: width,
                                  child: Tooltip(
                                    message: ufficio.entries[index][i],
                                    style: const TooltipThemeData(
                                      waitDuration: Duration.zero,
                                    ),
                                    child: GestureDetector(onTap: () => copyToClipboard(ufficio.entries[index][i]), onSecondaryTap: () => copyToClipboard(ufficio.entries[index][i]), child: Text(ufficio.entries[index][i], maxLines: 1, textAlign: TextAlign.center)),
                                  ),
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
