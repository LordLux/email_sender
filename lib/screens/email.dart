import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_svg/svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/database.dart' as db;
import '../src/emailManager.dart';
import '../functions.dart';
import '../main.dart';
import '../src/manager.dart';
import '../vars.dart';
import '../widgets/card_highlight.dart';
import '../widgets/page.dart';
import 'gotos.dart';
import 'home.dart';

class Email extends StatefulWidget {
  const Email({super.key});

  @override
  State<Email> createState() => _EmailState();
}

class _EmailState extends State<Email> with PageMixin {
  List<XFile> selectedFiles = [];
  bool _dragging = false;
  String? lastDir;
  bool isSending = false;

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  Color textBoxBg = Colors.white.withOpacity(.0001);
  Color textBoxBg2 = Colors.white.withOpacity(.1);
  bool previewOn = false;

  final FlyoutController flyoutController = FlyoutController();

  String get fullEmail => '${convertToHtml(Manager.emailController.text)}$firma\n$privacy';

  void saveFile(XFile file) {
    if (file.path.isEmpty) return;
    if (FileSystemEntity.isDirectorySync(file.path)) {
      snackBar(
        'Non è possibile allegare una cartella',
        severity: InfoBarSeverity.warning,
      );
      return;
    }
    if (!Manager.attachments.any((existingFile) => existingFile.path == file.path)) {
      Manager.attachments.add(file);
      setState(() {});
    }
  }

  void saveFiles(List<XFile> files) {
    for (final file in files) saveFile(file);
  }

  Future<void> loadLastDir() async => lastDir = await Manager.lastDirectory;

  @override
  void initState() {
    super.initState();
    loadLastDir();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus)
        textBoxBg = Colors.white.withOpacity(.03);
      else
        textBoxBg = Colors.white.withOpacity(.0001);

      setState(() {});
    });
    _focusNode2.addListener(() {
      if (_focusNode2.hasFocus)
        textBoxBg2 = Colors.white.withOpacity(.1);
      else
        textBoxBg2 = Colors.white.withOpacity(.0001);

      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  bool get emptyRecipients => Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return mat.ScaffoldMessenger(
      child: ScaffoldPage.scrollable(
        header: const PageHeader(title: Text('Email')),
        children: [
          if (Manager.uffici.isEmpty)
            CardHighlight(
              child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Nessun file Excel selezionato'),
                FilledButton(
                  onPressed: () async => gotoExcel(context),
                  child: const Text('Seleziona file'),
                ),
              ]),
            ),
          if (Manager.uffici.isEmpty) spacer,
          if (Manager.uffici.isNotEmpty)
            if (emptyRecipients)
              CardHighlight(
                child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Text('Nessun Destinatario selezionato!'),
                  FilledButton(
                    onPressed: () async => gotoGruppi(context, null),
                    child: const Text('Seleziona Destinatari'),
                  ),
                ]),
              ),
          if (Manager.uffici.isNotEmpty && !emptyRecipients) spacer,
          if (Manager.uffici.isNotEmpty && !emptyRecipients)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mat.Material(
                    color: Colors.transparent,
                    child: Builder(
                      builder: (context) {
                        final String text1 = 'Destinatari${(Manager.selectedGroups.length + Manager.extraRecipients.length == 1) ? 'o' : ''}';
                        const String text2 = ' [CCN]';
                        const String text3 = ': ';
                        return Wrap(
                          direction: Axis.horizontal,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4.0,
                          children: <Widget>[
                                Text.rich(TextSpan(children: [
                                  TextSpan(text: text1, style: headerStyle),
                                  TextSpan(text: text2, style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 16)),
                                  const TextSpan(text: text3, style: TextStyle(fontSize: 18)),
                                ])),
                              ] +
                              Manager.selectedGroups
                                  .map((group) => ufficioChip(
                                        group,
                                        FluentTheme.of(context).accentColor,
                                        () {
                                          if (Manager.selectedGroups.isEmpty) infoBadge('/gruppi', null);
                                          setState(() {});
                                        },
                                      ))
                                  .toList() +
                              [
                                for (final recipient in Manager.extraRecipients)
                                  recipientChip(
                                        recipient['name']!,
                                        recipient['email']!,
                                        FluentTheme.of(context).accentColor,
                                        () => setState(() {}),
                                      ) ??
                                      const SizedBox(),
                              ] +
                              [
                                if (!previewOn)
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Button(child: const Icon(mat.Icons.add), onPressed: () => gotoGruppi(context, null)),
                                  ),
                              ],
                        );
                      },
                    ),
                  ),
                  spacer,
                  Text('Oggetto:', style: headerStyle),
                  const SizedBox(height: 4.0),
                  !previewOn
                      ? TextFormBox(
                          autofocus: true,
                          controller: Manager.oggettoController,
                          focusNode: _focusNode2,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), border: Border.all(color: FluentTheme.of(context).accentColor.withOpacity(.5)), color: textBoxBg2),
                          maxLines: 1,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(Manager.oggettoController.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                  spacer,
                  spacer,
                  Text('Testo dell\'email:', style: headerStyle),
                  const SizedBox(height: 4.0),
                  !previewOn
                      ? TextFormBox(
                          autofocus: false,
                          controller: Manager.emailController,
                          focusNode: _focusNode,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), border: Border.all(color: FluentTheme.of(context).accentColor.withOpacity(.5)), color: textBoxBg),
                          maxLines: 10,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Html(
                            data: processHtml(fullEmail, true),
                            onLinkTap: (url, attributes, element) => launchUrl(Uri.parse(url!)),
                            style: {
                              "p": Style(
                                color: Colors.white,
                                fontSize: FontSize(15),
                              ),
                            },
                          ),
                        ),
                  if (!previewOn) const SizedBox(height: 4.0),
                  if (!previewOn) Text('<Firma> e <Privacy> verranno aggiunte automaticamente', style: TextStyle(color: Colors.white.withOpacity(.5))),
                  spacer,
                  spacer,
                  if (Manager.attachments.isNotEmpty) Text('Allegati:', style: headerStyle),
                  if (Manager.attachments.isNotEmpty) const SizedBox(height: 4.0),
                  if (!previewOn)
                    DottedBorder(
                      color: Colors.white,
                      strokeWidth: 1,
                      radius: const Radius.circular(10),
                      borderType: BorderType.RRect,
                      child: SizedBox(
                        height: Manager.attachments.isEmpty ? 200 : 120,
                        child: mat.Material(
                          color: _dragging ? Colors.white.withOpacity(0.1) : Colors.transparent,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: mat.InkWell(
                              onTap: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  allowMultiple: true,
                                  dialogTitle: "Scegliere gli Allegati da Aggiungere alla Email",
                                  initialDirectory: lastDir,
                                  //allowedExtensions: ['txt', 'pdf', 'docx', 'xlsx', 'png', 'jpeg', 'jpg', 'svg', 'gif', 'mp4', 'mp3', 'wav', 'flac', 'zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2', 'xz', 'iso', 'dmg', 'apk', 'exe', 'msi', 'deb', 'rpm', 'sh', 'bat', 'cmd', 'ps1', 'vbs', 'js', 'html', 'css', 'scss', 'json', 'xml', 'yaml', 'yml', 'toml', 'ini', 'conf', 'cfg', 'log', 'md', 'csv', 'tsv', 'sql', 'db', 'sqlite', 'dbf', 'xls', 'ppt', 'pptx', 'odt', 'ods', 'odp', 'odg', 'odf', 'ott', 'ots', 'otp', 'otg', 'otf', 'ott', 'otm', 'oth', 'otc', 'odc', 'odm', 'odi', 'odp', 'odb', 'odf', 'odi', 'odk', 'odm', 'odp', 'ods', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp', 'odt', 'odx', 'odg', 'odf', 'odp', 'odt', 'odc', 'odm', 'odp'],
                                );
                                if (result != null) {
                                  List<XFile> pickedFiles = result.files.map((file) => XFile(file.path!)).toList();
                                  saveFiles(pickedFiles);
                                }
                              },
                              child: DropTarget(
                                onDragDone: (details) {
                                  List<XFile> droppedFiles = details.files.map((file) => XFile(file.path)).toList();
                                  saveFiles(droppedFiles);
                                },
                                onDragEntered: (details) {
                                  _dragging = true;
                                  setState(() {});
                                },
                                onDragExited: (details) {
                                  _dragging = false;
                                  setState(() {});
                                },
                                child: Center(
                                  child: _dragging
                                      ? const Text("Rilascia i file qui", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(mat.Icons.file_upload, size: 50, color: Colors.white.withOpacity(0.7)),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Trascina qui gli allegati o clicca qui per selezionarli",
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.7)),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (Manager.attachments.isNotEmpty) spacer,
                  if (Manager.attachments.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mat.Material(
                          color: Colors.transparent,
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: Manager.attachments.map((file) {
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: mat.InkWell(
                                  mouseCursor: SystemMouseCursors.click,
                                  onTap: () async {
                                    final String path = file.path;
                                    final File file_ = File(path);
                                    if (file_.existsSync()) {
                                      openFile(path);
                                    } else if (kDebugMode) print('Could not launch $path');
                                  },
                                  child: mat.Chip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Builder(builder: (context) {
                                          switch (getFileExtension(file.path)) {
                                            case '.docx' || '.doc' || '.odt' || '.rtf' || '.txt':
                                              return const Icon(FluentIcons.text_document, size: 16.0, color: Colors.white);
                                            case '.xlsx' || '.xls' || '.csv' || '.tsv':
                                              return const Icon(FluentIcons.excel_document, size: 16.0, color: Colors.white);
                                            case '.pdf':
                                              return const Icon(FluentIcons.pdf, size: 16.0, color: Colors.white);
                                            case '.pptx' || '.ppt' || '.odp' || '.pps' || '.ppsx':
                                              return const Icon(FluentIcons.power_point_document, size: 16.0, color: Colors.white);
                                            case '.zip' || '.rar' || '.7z' || '.tar' || '.gz' || '.tgz' || '.bz2' || '.xz':
                                              // ignore: deprecated_member_use
                                              return SvgPicture.string(zipSvg, color: Colors.white, height: 16.0);
                                            case '.mp4' || '.avi' || '.mkv' || '.mov' || '.wmv' || '.flv' || '.webm' || '.m4v' || '.3gp' || '.3g2' || '.ogv' || '.mpg' || '.mpeg':
                                              return const Icon(FluentIcons.video, size: 16.0, color: Colors.white);
                                            case '.wav' || '.flac' || '.mid' || '.ogg':
                                              return const Icon(FluentIcons.music_in_collection, size: 16.0, color: Colors.white);
                                            case '.png' || '.jpeg' || '.jpg' || '.svg' || '.gif' || '.webp' || '.bmp' || '.ico' || '.tiff' || '.jfif' || '.tif' || '.heic' || '.heif' || '.avif' || '.apng' || '.flif':
                                              return const Icon(FluentIcons.picture_fill, size: 16.0, color: Colors.white);
                                            case '.exe' || '.msi' || '.deb' || '.rpm' || '.sh' || '.bat' || '.cmd' || '.ps1' || '.vbs' || '.js' || '.html' || '.css' || '.scss' || '.json' || '.xml' || '.yaml' || '.yml' || '.toml' || '.ini' || '.conf' || '.cfg' || '.log' || '.md' || '.tsv' || '.sql' || '.db' || '.sqlite' || '.dbf' || '.dart':
                                              return const Icon(FluentIcons.code, size: 16.0, color: Colors.white);
                                            case '':
                                              return const Icon(FluentIcons.document, size: 16.0, color: Colors.white);
                                            default:
                                              return const Icon(Symbols.file_present, size: 16.0, color: Colors.white);
                                          }
                                        }),
                                        const SizedBox(width: 6.0),
                                        Text(file.name),
                                      ],
                                    ),
                                    onDeleted: () {
                                      Manager.attachments.remove(file);
                                      setState(() {});
                                    },
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                                    padding: const EdgeInsets.all(8.0),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  if (!previewOn) biggerSpacer,
                  if (previewOn && Manager.attachments.isNotEmpty) biggerSpacer,
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton(
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: BorderSide(color: FluentTheme.of(context).accentColor.withOpacity(.5)),
                        )),
                      ),
                      onPressed: () {
                        previewOn = !previewOn;
                        setState(() {});
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(previewOn ? FluentIcons.edit : mat.Icons.visibility, size: 16.0),
                          const SizedBox(width: 4.0),
                          Text(previewOn ? 'Modifica Email' : 'Mostra Anteprima Email'),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          if (Manager.uffici.isNotEmpty && !emptyRecipients) spacer,
          if (Manager.uffici.isNotEmpty && !emptyRecipients)
            Card(
                child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10.0,
              children: [
                Button(
                  onPressed: () => Manager.clearEmail(() => setState(() {})),
                  child: const Text('Cancella'),
                ),
                FlyoutTarget(
                  controller: flyoutController,
                  child: FilledButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            isSending = true;
                            List<Map<String, Color>> extra = [];

                            if (Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty) {
                              snackBar('Nessun Destinatario selezionato', severity: InfoBarSeverity.error);
                              return;
                            }

                            if (Manager.oggettoController.text.isEmpty || Manager.emailController.text.isEmpty) {
                              Future.delayed(const Duration(milliseconds: 200), () => snackBar('Alcuni campi dell\'Email sono vuoti', severity: InfoBarSeverity.warning));

                              if (Manager.oggettoController.text.isEmpty) extra.add({'L\'oggetto dell\'Email è vuoto.\n\n': mat.Colors.amber});
                              if (Manager.emailController.text.isEmpty) extra.add({'Il testo dell\'Email è vuoto.\n\n': mat.Colors.amber});
                            }

                            if (Manager.attachments.isEmpty) extra.add({'Nessun allegato selezionato.': mat.Colors.white});

                            //
                            if (extra.isNotEmpty) {
                              bool confirm = await flyoutController.showFlyout<bool>(
                                    autoModeConfiguration: FlyoutAutoConfiguration(
                                      preferredMode: FlyoutPlacementMode.right,
                                    ),
                                    barrierDismissible: true,
                                    dismissOnPointerMoveAway: false,
                                    dismissWithEsc: true,
                                    navigatorKey: rootNavigatorKey.currentState,
                                    barrierColor: Colors.black.withOpacity(0.5),
                                    builder: (context) => FlyoutContent(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text.rich(TextSpan(children: [
                                            const TextSpan(text: 'Sei sicuro di voler inviare l\'email?\n'),
                                            if (extra.isNotEmpty) const TextSpan(text: "\n"),
                                            for (final e in extra)
                                              TextSpan(
                                                children: [
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.middle,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 4.0),
                                                      child: Icon(e.values.first == mat.Colors.amber ? mat.Icons.warning_amber : mat.Icons.info_outline, color: e.values.first),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: e.keys.first,
                                                    style: TextStyle(color: e.values.first),
                                                  )
                                                ],
                                              ),
                                            if (extra.isNotEmpty) const TextSpan(text: "\n"),
                                          ])),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Button(
                                                child: const Text('Annulla'),
                                                onPressed: () {
                                                  Navigator.of(context).pop(false);
                                                  //Flyout.of(context).close();
                                                },
                                              ),
                                              const SizedBox(width: 8.0),
                                              FilledButton(
                                                child: const Text('Invia Comunque'),
                                                onPressed: () {
                                                  Navigator.of(context).pop(true);
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ) ??
                                  false;

                              if (confirm != true) return;
                            }

                            List<String> ufficiNames = [];
                            List<String> ufficiMails = [];
                            List<String> recipientNames = [];
                            List<String> recipientMails = [];

                            for (final ufficio in Manager.selectedGroups) {
                              for (final row in ufficio.entries) {
                                ufficiNames.add(row[0]); // Name
                                ufficiMails.add(row[2]); // Email
                              }
                            }

                            recipientMails.addAll(Manager.extraRecipients.map((e) => e['email']!));
                            recipientNames.addAll(Manager.extraRecipients.map((e) => e['name']!));

                            bool emailSent = await EmailSender().sendEmail(
                              bcc: ufficiMails + recipientMails,
                              subject: Manager.oggettoController.text,
                              body: fullEmail,
                              attachments: Manager.attachments,
                            );

                            if (emailSent) {
                              // Save the email to the database
                              final newEmail = db.Email(
                                uffici: db.joinUffici(Manager.selectedGroups),
                                recipients: db.joinRecipients(recipientMails, recipientNames),
                                subject: Manager.oggettoController.text,
                                body: Manager.emailController.text,
                                attachments: Manager.attachments.map((file) => file.path).join(', '),
                                timestamp: DateTime.now().toUtc().toIso8601String(),
                              );
                              await db.emailDb.addEmail(newEmail);

                              // Clear the email fields
                              previewOn = false;
                              isSending = false;
                              Manager.clearEmail(() => setState(() {}));
                              infoBadge('/email', true);
                              snackBar('Email inviata con successo', severity: InfoBarSeverity.success);

                              // Reset the badges after 2 seconds
                              await Future.delayed(const Duration(seconds: 2), () {
                                infoBadge('/email', null);
                                infoBadge('/gruppi', null);
                                infoBadge('/excel', null);
                              });

                              router.go('/');
                              homePageKey.currentState?.isHighlighted = true;
                            } else {
                              isSending = false;
                              setState(() {});
                            }
                          },
                    child: const Text('Invia Email'),
                  ),
                ),
              ],
            ))
        ],
      ),
    );
  }
}

String processHtml(String text, [bool whiten = false]) {
  if (text.isEmpty) return '<p>Il file è vuoto</p>';

  /*String result = text.replaceAllMapped(
    RegExp(r'\$(\w+)'), // Match $variableName only
    (match) {
      String variableName = match.group(0) ?? '';
      if (whitenList.contains(variableName)) return '‎${variableName.substring(1, variableName.length)}';
      if (keywordList.any((keyword) => variableName.startsWith(keyword))) return '<span style="${whiten ? "" : "color: ${htmlHighlightColor.toHex(leadingHashSign: true)}; "}font-style: italic;">‎${variableName.substring(1, variableName.length)}</span>';
      return variableName;
    },
  );
  
  result = result.replaceAll('‎valoreUnicaSoluzione', 'Euro');
  result = result.replaceAll('‎cognomeNome', "Nome e Cognome Allievo/a".toUpperCase());
  result = result.replaceAll('‎valoreRata', 'Euro Rata');
  result = result.replaceAll('‎iban', iban);
  result = result.replaceAll('‎filiale', filiale);
  result = result.replaceAll('‎contoCorrente', contoCorrente);
  result = result.replaceAll('‎ref', "Genitore | Allievo/a");
  return result;*/
  return text;
}

String convertToHtml(String text) {
  final linkRegex = RegExp(r'((http|https)://[^\s]+)');

  // Convert text to HTML paragraphs and replace URLs with clickable links
  return text
      .split('\n\n')
      .map((paragraph) => paragraph
          .split('\n')
          .map((line) => line.replaceAllMapped(linkRegex, (match) {
                final url = match.group(0)!;
                return '<a href="$url" target="_blank">$url</a>';
              }))
          .join('<br>'))
      .map((paragraph) => '<p>$paragraph</p>')
      .join();
}
