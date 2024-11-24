import 'dart:math';

import 'package:email_sender/functions.dart';
import 'package:email_sender/random.dart';
import 'package:email_sender/vars.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mat;
import 'package:url_launcher/link.dart';

import '../src/manager.dart';
import '../src/database.dart' as db;
import '../widgets/page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final GlobalKey<_HomePageState> homePageKey = GlobalKey<_HomePageState>();

class _HomePageState extends State<HomePage> with PageMixin {
  late Future<List<db.Email>> _emailsFuture;
  bool isHighlighted = false;

  List<String> listRecipients(String recipients) {
    List<String> recipientList = recipients.split(',');
    List<String> namedRecipients = [];
    List<String> namelessRecipients = [];

    for (String recipient in recipientList) {
      if (recipient.contains('<') && recipient.contains('>')) {
        // Extract name and email from "Name <email@example.com>"
        final name = recipient.split('<')[0].trim();
        namedRecipients.add(name);
      } else
        namelessRecipients.add(recipient.trim());
    }
    return namedRecipients + namelessRecipients;
  }

  (List<String>, List<String>) parseRecipients(String recipients) {
    List<String> recipientList = recipients.split(',');
    List<String> names = [];
    List<String> emails = [];

    for (String recipient in recipientList) {
      if (recipient.contains('<') && recipient.contains('>')) {
        // Extract name and email from "Name <email@example.com>"
        final name = recipient.split('<')[0].trim();
        names.add(name);
        final email = recipient.split('<')[1].trim();
        emails.add(email.substring(0, email.length - 1));
      } else {
        names.add('');
        emails.add(recipient.trim());
      }
    }
    return (emails, names);
  }

  void reloadTable() {
    setState(() {
      _emailsFuture = db.EmailDatabase().getEmails();
    });
  }

  @override
  void initState() {
    super.initState();
    reloadTable();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    //daniele.mason@maggioli.it]

    //
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Registro Email'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(
            icon: const Icon(mat.Icons.casino_outlined, color: mat.Colors.amber, size: 24),
            onPressed: () async {
              await addRandomEmails(1);
              reloadTable();
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
          Link(
            uri: Uri.parse('https://mail.google.com/'),
            builder: (context, open) => Semantics(
              link: true,
              child: Tooltip(
                enableFeedback: true,
                style: const TooltipThemeData(
                  waitDuration: Duration.zero,
                  preferBelow: true,
                ),
                message: 'Portami alla mia casella di posta su Gmail',
                child: IconButton(
                  icon: Image.network(
                    "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Gmail_icon_%282020%29.svg/320px-Gmail_icon_%282020%29.svg.png",
                    width: 24,
                    height: 24,
                  ),
                  onPressed: open,
                ),
              ),
            ),
          ),
        ]),
      ),
      children: [
        Card(
          child: mat.Material(
            color: Colors.transparent,
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 180, // 180 is the height of the header + padding
              child: Column(
                children: [
                  SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: SizedBox(
                        width: 1200,
                        child: Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 60,
                              child: Text(
                                "Data",
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                            const SizedBox(
                              width: 300,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Oggetto",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 300,
                              child: Text(
                                "Allegati",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<db.Email>>(
                      future: _emailsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: mat.CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Nessuna email ancora inviata'));
                        } else {
                          final emails = snapshot.data!;
                          return ListView.builder(
                            itemCount: emails.length,
                            itemBuilder: (context, index) {
                              const int n = 5;
                              final db.Email email = emails[index];
                              final recipients = parseRecipients(email.recipients);
                              final List<String> recipientMails = recipients.$1.take(n).toList();
                              final List<String> recipientNames = recipients.$2.take(n).toList();
                              final String timestamp = email.timestamp;
                              final String formattedTimestamp = db.fromIso8601String(timestamp);
                              final List<String> attachments = email.attachments.split(',');

                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: IconButton(
                                  style: const ButtonStyle(
                                    padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                                  ),
                                  onPressed: () {},
                                  icon: Card(
                                    child: SizedBox(
                                      width: 1200,
                                      child: Wrap(
                                        spacing: 8,
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: <Widget>[
                                              Text(
                                                "[$formattedTimestamp]", //TODO add tooltip with full date
                                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                              ),
                                              SizedBox(
                                                width: 300,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    ellipsizeText(email.subject, 300),
                                                    style: const TextStyle(/*fontWeight: FontWeight.bold*/),
                                                  ),
                                                ),
                                              ),
                                            ] +
                                            [
                                              for (int i = 0; i < recipientMails.length; i++) //
                                                recipientChip(recipientNames[i], recipientMails[i], FluentTheme.of(context).accentColor, () => setState(() {}), false),
                                            ] +
                                            [
                                              Tooltip(
                                                useMousePosition: false,
                                                style: const TooltipThemeData(
                                                  //maxWidth: 500,
                                                  preferBelow: true,
                                                  waitDuration: Duration.zero,
                                                ),
                                                richMessage: TextSpan(text: "a"), //TODO list all remaining recipients
                                                child: mat.RawChip(
                                                  side: BorderSide(color: FluentTheme.of(context).accentColor),
                                                  color: WidgetStatePropertyAll(FluentTheme.of(context).accentColor.withOpacity(.25)),
                                                  padding: const EdgeInsets.fromLTRB(0, 5.0, 0, 5.0),
                                                  label: Text(
                                                    "+${recipients.$1.length - n}",
                                                    style: const TextStyle(/*fontWeight: FontWeight.bold*/),
                                                  ),
                                                ),
                                              ),
                                              Tooltip(
                                                useMousePosition: false,
                                                style: const TooltipThemeData(
                                                  //maxWidth: 500,
                                                  preferBelow: true,
                                                  waitDuration: Duration.zero,
                                                ),
                                                richMessage: TextSpan(text: "b"), //TODO list attachment names
                                                child: mat.RawChip(
                                                  padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                                                  label: Text(
                                                    attachments.length.toString(),
                                                    style: const TextStyle(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
