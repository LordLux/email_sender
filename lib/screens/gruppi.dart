import 'package:email_sender/widgets/card_highlight.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/material.dart' as mat;

import '../manager.dart';
import '../widgets/page.dart';

class MailingLists extends StatefulWidget {
  const MailingLists({super.key});

  @override
  State<MailingLists> createState() => _MailingListsState();
}

class _MailingListsState extends State<MailingLists> with PageMixin {
  bool selected = true;
  String? comboboxValue;

  @override
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Excel')),
      children: [
        CardHighlight(
          child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, children: [
            
          ]),
        ),
      ],
    );
  }
}
