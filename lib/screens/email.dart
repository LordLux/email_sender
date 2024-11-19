import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/link.dart';

import '../widgets/card_highlight.dart';
import '../widgets/page.dart';

class Email extends StatefulWidget {
  const Email({super.key});

  @override
  State<Email> createState() => _EmailState();
}

class _EmailState extends State<Email> with PageMixin {
  bool selected = true;
  String? comboboxValue;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Email')),
      children: [
        CardHighlight(
          child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
            TextBox(
              maxLength: 100,
            )
          ]),
        ),
      ],
    );
  }
}
