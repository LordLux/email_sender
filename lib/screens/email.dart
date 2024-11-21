import 'package:email_sender/widgets/dragNdrop.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/material.dart' as mat;

import '../manager.dart';
import '../vars.dart';
import '../widgets/card_highlight.dart';
import '../widgets/page.dart';
import 'excel.dart';
import 'gotos.dart';
import 'gruppi.dart';

class Email extends StatefulWidget {
  const Email({super.key});

  @override
  State<Email> createState() => _EmailState();
}

class _EmailState extends State<Email> with PageMixin {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
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
        if (Manager.selectedGroups.isEmpty)
          CardHighlight(
            child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('Nessun gruppo selezionato!'),
              FilledButton(
                onPressed: () async => gotoGruppi(context),
                child: const Text('Seleziona gruppo'),
              ),
            ]),
          ),
        if (Manager.selectedGroups.isNotEmpty && Manager.uffici.isNotEmpty) spacer,
        if (Manager.selectedGroups.isNotEmpty && Manager.uffici.isNotEmpty)
          CardHighlight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mat.Material(
                  color: Colors.transparent,
                  child: Builder(
                    builder: (context) {
                      final String text1 = 'Destinatari${(Manager.selectedGroups.length == 1) ? 'o' : ''}';
                      const String text2 = ' [CCN]';
                      const String text3 = ': ';
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: text1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            TextSpan(text: text2, style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 16)),
                            const TextSpan(text: text3, style: const TextStyle(fontSize: 18)),
                          ])),
                          const SizedBox(width: 4.0),
                          Wrap(
                            spacing: 4.0,
                            children: Manager.selectedGroups.map((group) {
                              return mat.Chip(
                                side: BorderSide(color:FluentTheme.of(context).accentColor.withOpacity(1)),
                                color: WidgetStatePropertyAll(FluentTheme.of(context).accentColor.withOpacity(.25)),
                                label: Text(group.nome),
                                onDeleted: () {
                                  Manager.selectedGroups.remove(group);
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                spacer,
                spacer,
                const Text('Testo dell\'email:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4.0),
                TextFormBox(
                  autofocus: true,
                  controller: controller,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: FluentTheme.of(context).accentColor.withOpacity(.5)),
                  ),
                  maxLines: 10,
                ),
                spacer,
                spacer,
                const Text('Allegati:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4.0),
                Dragndrop(save: (file) {
                  if (!Manager.attachments.contains(file)) {
                    Manager.attachments.add(file);
                    setState(() {});
                  }
                }),
                if (Manager.attachments.isNotEmpty) spacer,
                if (Manager.attachments.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Allegati:'),
                      const SizedBox(height: 4.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: Manager.attachments.map((file) {
                          return mat.Chip(
                            label: Text(file.name),
                            onDeleted: () {
                              Manager.attachments.remove(file);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          )
      ],
    );
  }
}
