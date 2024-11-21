import 'package:email_sender/vars.dart';
import 'package:email_sender/widgets/card_highlight.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/material.dart' as mat;
import 'package:smooth_highlight/smooth_highlight.dart';
import 'package:recase/recase.dart';

import '../classes.dart';
import '../manager.dart';
import '../widgets/page.dart';
import 'excel.dart';
import 'gotos.dart';

class MailingLists extends StatefulWidget {
  const MailingLists({super.key});

  @override
  State<MailingLists> createState() => _MailingListsState();
}

final GlobalKey<_MailingListsState> gruppiKey = GlobalKey<_MailingListsState>();

class _MailingListsState extends State<MailingLists> with PageMixin {
  bool isHighlighted = false;

  @override
  void initState() {
    super.initState();
    removeHighlight();
  }

  void removeHighlight() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted)
      setState(() {
        isHighlighted = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Gruppi')),
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
        if (Manager.uffici.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 3,
                child: mat.Material(
                  color: Colors.transparent,
                  child: ValueChangeHighlight(
                    duration: const Duration(milliseconds: 300),
                    value: isHighlighted,
                    color: FluentTheme.of(context).accentColor.withOpacity(.5),
                    child: const Card(
                      child: Text(
                        'Seleziona i gruppi a cui vuoi inviare l\'email:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: Tooltip(
                  message: 'Se abilitato, permette di selezionare più gruppi da inviare nella stessa email',
                  child: Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Selezione Multipla'),
                        const SizedBox(width: 8),
                        ToggleSwitch(
                          checked: Manager.multiSelection,
                          onChanged: (value) {
                            setState(() {
                              Manager.multiSelection = value;
                              if (!Manager.multiSelection && Manager.selectedGroups.isNotEmpty) // Keep only the first element of the list if multiSelection has just been disabled
                                Manager.selectedGroups = [Manager.uffici.firstWhere((ufficio) => Manager.selectedGroups.contains(ufficio))];
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (Manager.uffici.isNotEmpty) const SizedBox(height: 16),
        if (Manager.uffici.isNotEmpty)
          ValueChangeHighlight(
            duration: const Duration(milliseconds: 300),
            value: isHighlighted,
            color: FluentTheme.of(context).accentColor.withOpacity(.5),
            child: Card(
              //padding: const EdgeInsets.symmetric(horizontal: 360, vertical: 8),
              child: SizedBox(
                height: Manager.uffici.length * 44.0,
                child: ListView.builder(
                    itemCount: Manager.uffici.length,
                    itemBuilder: (context, index) {
                      final Ufficio ufficio = Manager.uffici[index];
                      return ListTile.selectable(
                        title: Text.rich(TextSpan(children: [
                          TextSpan(text: '${ufficio.nome} '),
                          TextSpan(text: '(${ufficio.entries.length} destinatari)', style: TextStyle(color: Colors.white.withOpacity(.5))),
                        ])),
                        selected: Manager.selectedGroups.contains(ufficio),
                        selectionMode: ListTileSelectionMode.single,
                        onPressed: () {
                          setState(() {
                            final bool selected = !Manager.selectedGroups.contains(ufficio);
                            if (selected) {
                              if (!Manager.multiSelection) Manager.selectedGroups.clear();
                              Manager.selectedGroups.add(ufficio);
                            } else {
                              Manager.selectedGroups.remove(ufficio);
                            }
                          });
                        },
                      );
                    }),
              ),
            ),
          ),
      ],
    );
  }
}
