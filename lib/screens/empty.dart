import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/link.dart';

import '../widgets/page.dart';

class Empty extends StatefulWidget {
  const Empty({super.key});

  @override
  State<Empty> createState() => _EmptyState();
}

class _EmptyState extends State<Empty> with PageMixin {
  bool selected = true;
  String? comboboxValue;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Excel')),
      children: [
        Card(
          child: Wrap(alignment: WrapAlignment.center, spacing: 10.0, children: []),
        ),
      ],
    );
  }
}
