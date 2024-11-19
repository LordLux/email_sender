import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';

import '../manager.dart';
import '../vars.dart';
import '../widgets/card_highlight.dart';
import '../widgets/page.dart';
import 'excel.dart';

class Email extends StatefulWidget {
  const Email({super.key});

  @override
  State<Email> createState() => _EmailState();
}

class _EmailState extends State<Email> with PageMixin {

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Email')),
      children: [
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
