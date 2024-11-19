import 'package:email_sender/vars.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/link.dart';

import '../manager.dart';
import '../widgets/page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with PageMixin {
  bool needsToRestart = false;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    //daniele.mason@maggioli.it]
    
    //
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Email Sender'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Link(
            uri: Uri.parse('maito:lordlux.dev@gmail.com'),
            builder: (context, open) => Semantics(
              link: true,
              child: Tooltip(
                enableFeedback: true,
                message: 'Email - Lorenzo Lupi',
                child: IconButton(
                  icon: const Icon(FluentIcons.mail, size: 24.0),
                  onPressed: open,
                ),
              ),
            ),
          ),
        ]),
      ),
      children: [
        Card(
          child: Row(children: [
            const Text('Cancella Cache'),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                SettingsManager.clearSettings();
                setState(() {
                  needsToRestart = true;
                });
              },
              child: const Text('Cancella Cache'),
            ),
          ]),
        ),
        if (needsToRestart) biggerSpacer,
        if (needsToRestart) Center(child: Text("Restarta l'App", style: TextStyle(color: Colors.red)),)
      ],
    );
  }
}

class SponsorButton extends StatelessWidget {
  const SponsorButton({
    super.key,
    required this.imageUrl,
    required this.username,
  });

  final String imageUrl;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
          ),
          shape: BoxShape.circle,
        ),
      ),
      Text(username),
    ]);
  }
}
