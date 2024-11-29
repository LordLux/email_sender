import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_acrylic/window_effect.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../functions.dart';
import '../screens/email.dart';
import '../src/classes.dart';
import '../src/database.dart' as db;
import '../theme.dart';
import '../vars.dart';

class SingleEmailDialog extends mat.StatefulWidget {
  final db.Email email;

  const SingleEmailDialog({super.key, required this.email});

  @override
  mat.State<SingleEmailDialog> createState() => _SingleEmailDialogState();
}

class _SingleEmailDialogState extends mat.State<SingleEmailDialog> {
  String subject = '';
  String body = '';
  List<Ufficio> uffici = [];
  List<Map<String, String>> extraRecipients = [];
  List<XFile> attachments = [];

  String get fullEmail => '${convertToHtml(body)}$firma\n$privacy';

  void _parseMailData() {
    subject = widget.email.subject;
    body = widget.email.body;
    uffici = db.parseUffici(widget.email.uffici);
    final res = db.parseRecipients(widget.email.recipients);
    final List<String> extraRecipientsEmails = res.$1;
    final List<String> extraRecipientsNames = res.$2;
    for (int i = 0; i < extraRecipientsEmails.length; i++) extraRecipients.add({'name': extraRecipientsNames[i], 'email': extraRecipientsEmails[i]});
    attachments = widget.email.attachments.isEmpty ? [] : widget.email.attachments.split(',').map((path) => XFile(path)).toList();
  }

  @override
  void initState() {
    _parseMailData();
    super.initState();
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final appTheme = context.watch<AppTheme>();
    bool hasAcrylic = appTheme.windowEffect == WindowEffect.acrylic;

    Widget dialog = LayoutBuilder(builder: (context, constraints) {
      return mat.Padding(
        padding: const mat.EdgeInsets.all(8.0),
        child: Column(
          children: [
            mat.SizedBox(
              height: constraints.maxWidth < measureTextSize(text: subject, textStyle: FluentTheme.of(context).typography.subtitle!).width ? 120 : 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(widget.email.subject, style: FluentTheme.of(context).typography.subtitle),
                      subtitle: Text(db.formatDate(widget.email.timestamp, true, true), style: TextStyle(color: Colors.white.withOpacity(.5))),
                    ),
                  ),
                  SizedBox(
                    width: 35,
                    height: 35,
                    child: Transform.translate(
                      offset: const Offset(-3, -11),
                      child: IconButton(
                        icon: const Icon(mat.Icons.close, size: 17),
                        onPressed: () => removeOverlay(),
                        style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                          topRight: Radius.circular(13),
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        )))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            mat.Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Card(
                  child: mat.SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mat.Material(
                          color: Colors.transparent,
                          child: Builder(
                            builder: (context) {
                              final String text1 = 'Destinatari${(uffici.length + extraRecipients.length == 1) ? 'o' : ''}';
                              const String text2 = ' [CCN]';
                              const String text3 = ': ';
                              return Wrap(
                                  direction: Axis.horizontal,
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: 4.0,
                                  spacing: 4.0,
                                  children: <Widget>[
                                        Text.rich(TextSpan(children: [
                                          TextSpan(text: text1, style: headerStyle),
                                          TextSpan(text: text2, style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 16)),
                                          const TextSpan(text: text3, style: TextStyle(fontSize: 18)),
                                        ])),
                                      ] +
                                      uffici
                                          .map((group) => ufficioChip(
                                                group,
                                                FluentTheme.of(context).accentColor,
                                                () {},
                                                false,
                                                true,
                                              ))
                                          .toList() +
                                      [
                                        for (final recipient in extraRecipients)
                                          recipientChip(
                                                recipient['name']!,
                                                recipient['email']!,
                                                FluentTheme.of(context).accentColor,
                                                () {},
                                                false,
                                                true,
                                              ) ??
                                              Container(),
                                      ]);
                            },
                          ),
                        ),
                        spacer,
                        Text('Oggetto:', style: headerStyle),
                        const SizedBox(height: 4.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(subject, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        spacer,
                        spacer,
                        Text('Testo dell\'email:', style: headerStyle),
                        const SizedBox(height: 4.0),
                        Padding(
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
                        spacer,
                        spacer,
                        if (attachments.isNotEmpty) Text('Allegati:', style: headerStyle),
                        if (attachments.isNotEmpty) const SizedBox(height: 4.0),
                        if (attachments.isNotEmpty) spacer,
                        if (attachments.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              mat.Material(
                                color: Colors.transparent,
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: attachments.map((file) {
                                    return MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: mat.InkWell(
                                        mouseCursor: SystemMouseCursors.click,
                                        onTap: () async {
                                          final String path = file.path;
                                          final File file_ = File(path);
                                          if (file_.existsSync()) {
                                            openFile(path);
                                          } else {
                                            if (kDebugMode) print('Could not launch $path');
                                            snackBar('Impossibile aprire il file, potrebbe essere stato rimosso.', severity: InfoBarSeverity.error);
                                          }
                                        },
                                        child: mat.RawChip(
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
                                              Text(getFileNameFromPath(file.path)),
                                            ],
                                          ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    if (hasAcrylic)
      return Acrylic(
        blurAmount: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        elevation: 20,
        tint: mat.Colors.black,
        shadowColor: mat.Colors.black,
        luminosityAlpha: .8,
        child: dialog,
      );
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          color: FluentTheme.of(context).acrylicBackgroundColor,
        ),
        child: dialog);
  }
}
