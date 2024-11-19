import 'package:email_sender/vars.dart';
import 'package:email_sender/widgets/card_highlight.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/material.dart' as mat;

import '../manager.dart';
import '../widgets/page.dart';
import 'excel.dart';

class MailingLists extends StatefulWidget {
  const MailingLists({super.key});

  @override
  State<MailingLists> createState() => _MailingListsState();
}

class _MailingListsState extends State<MailingLists> with PageMixin {
  bool multiSelection = false;
  List<String> selectedGroups = [];

  @override
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Gruppi')),
      children: [
        if (Manager.ufficiNames.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Expanded(
                child: CardHighlight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleziona i gruppi a cui vuoi inviare l\'email:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CardHighlight(
                  child: Row(
                    children: [
                      const Text(
                        'Selezione Multipla.',
                      ),
                      spacer,
                      ToggleSwitch(
                        checked: multiSelection,
                        onChanged: (value) {
                          setState(() {
                            multiSelection = value;
                            selectedGroups.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (Manager.ufficiNames.isNotEmpty) const SizedBox(height: 16),
        if (Manager.ufficiNames.isEmpty)
          CardHighlight(
            child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('Nessun file Excel selezionato'),
              FilledButton(
                onPressed: () async {
                  context.go('/excel');
                  await Future.delayed(const Duration(milliseconds: 200));
                  excelKey.currentState?.pickExcelFile();
                },
                child: const Text('Seleziona file'),
              ),
            ]),
          ),
      ],
    );
  }
}
