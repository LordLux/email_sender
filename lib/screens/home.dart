import 'dart:math';

import 'package:email_sender/functions.dart';
import 'package:email_sender/random.dart';
import 'package:email_sender/vars.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:url_launcher/link.dart';

import '../src/classes.dart';
import '../src/manager.dart';
import '../src/database.dart' as db;
import '../widgets/dialogs.dart';
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

  TextSpan getRemainingItemsTooltip(List<TextSpan> remainingItems) {
    return TextSpan(children: remainingItems..[remainingItems.length - 1].children?.removeLast());
  }

  void openMailDialog(BuildContext context, db.Email email, BoxConstraints constraints) {
    showNonModalDialog(
      context,
      SingleEmailDialog(email: email),
      constraints,
    );
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
          if (kDebugMode)
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
              child: FutureBuilder<List<db.Email>>(
                  future: _emailsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) //
                      return const Center(child: mat.CircularProgressIndicator());

                    if (snapshot.hasError) //
                      return Center(child: Text('Error: ${snapshot.error}'));

                    if (!snapshot.hasData || snapshot.data!.isEmpty) //
                      return const Center(child: Text('Nessuna email ancora inviata'));

                    final emails = snapshot.data!;
                    return LayoutBuilder(builder: (context, constraints) {
                      const int recipientsFlex = 40;

                      double width = constraints.maxWidth;
                      double subjectWidth = 300;
                      String longestSubject = "";

                      for (final mail in emails) {
                        if (mail.subject.length > longestSubject.length) longestSubject = mail.subject;
                      }
                      //print("maxSubjectLength: $longestSubject");
                      subjectWidth = min(measureTextSize(text: longestSubject, maxWidth: width).width + 20, 400);

                      return Column(
                        children: [
                          // HEADERS
                          SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 8.0),
                              child: SizedBox(
                                width: 1200,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    const SizedBox(width: 15, height: 30),
                                    SizedBox(
                                      width: 65,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Data",
                                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: subjectWidth,
                                      child: const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Oggetto",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: recipientsFlex,
                                      child: Text(
                                        "Destinatari",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 63,
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
                          // EMAILS
                          Expanded(
                            child: ListView.builder(
                              itemCount: emails.length,
                              itemBuilder: (context, index) {
                                const int n = 5;
                                final db.Email mail = emails[index];
                                final List<Ufficio> uffici = db.parseUffici(mail.uffici);
                                final recipients = db.parseRecipients(mail.recipients);
                                final List<String> recipientMails = recipients.$1.take(n).toList();
                                final List<String> recipientNames = recipients.$2.take(n).toList();
                                final String timestamp = mail.timestamp;
                                final List<String> attachments = mail.attachments.isEmpty ? [] : mail.attachments.split(',');

                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: IconButton(
                                    style: const ButtonStyle(
                                      padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                                    ),
                                    onPressed: () => openMailDialog(context, mail, constraints),
                                    icon: Card(
                                      child: SizedBox(
                                        width: 1200,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            // data
                                            SizedBox(
                                              width: 70,
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Tooltip(
                                                  useMousePosition: false,
                                                  style: const TooltipThemeData(
                                                    preferBelow: true,
                                                    waitDuration: Duration.zero,
                                                  ),
                                                  message: db.formatDate(timestamp, true),
                                                  child: Text(
                                                    "[${db.formatDate(timestamp, false)}]",
                                                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            // oggetto
                                            SizedBox(
                                              width: subjectWidth,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  ellipsizeText(mail.subject, 300),
                                                  style: const TextStyle(/*fontWeight: FontWeight.bold*/),
                                                ),
                                              ),
                                            ),
                                            // destinatari
                                            Expanded(
                                              flex: recipientsFlex,
                                              child: LayoutBuilder(
                                                builder: (context, c) {
                                                  double availableWidth = c.maxWidth;
                                                  double usedWidth = 0.0;
                                                  const double chipSpacing = 8.0;
                                                  const double plusChipWidth = 50.0; // Approximate width for "+X" chip
                                                  bool reservePlusChip = false; // Flag to determine if we need the "+X" chip
                                                  List<Widget> chips = [];
                                                  List<TextSpan> remainingItems = []; // Tracks remaining uffici and recipients

                                                  // Function to estimate chip width
                                                  double estimateChipWidth(String content, [TextStyle style = const TextStyle(fontSize: 14.0)]) {
                                                    final textPainter = TextPainter(
                                                      text: TextSpan(
                                                        text: content,
                                                        style: style, // Match your chip text style
                                                      ),
                                                      maxLines: 1,
                                                      textDirection: TextDirection.ltr,
                                                    )..layout();

                                                    const double padding = 50.0; // Add padding for chip content
                                                    return textPainter.width + padding;
                                                  }

                                                  if (uffici.isNotEmpty) {
                                                    // Display uffici chips first
                                                    for (int i = 0; i < uffici.length; i++) {
                                                      final Ufficio ufficio = uffici[i];
                                                      double chipWidth = estimateChipWidth(ufficio.nome, const TextStyle(fontWeight: FontWeight.bold));

                                                      // Add spacing between chips
                                                      if (chips.isNotEmpty) chipWidth += chipSpacing;

                                                      // Check if the chip fits in the remaining space
                                                      if (usedWidth + chipWidth + plusChipWidth <= availableWidth) {
                                                        chips.add(
                                                          GestureDetector(
                                                            behavior: HitTestBehavior.opaque,
                                                            onTap: () => openMailDialog(context, mail, constraints),
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(right: 4.0),
                                                              child: ufficioChip(
                                                                ufficio,
                                                                FluentTheme.of(context).accentColor,
                                                                () => setState(() {}),
                                                                false,
                                                                false,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                        usedWidth += chipWidth;
                                                      } else {
                                                        reservePlusChip = true;
                                                        remainingItems.add(richTooltipUfficio(ufficio, true)); // Add to remaining items
                                                      }
                                                    }
                                                  }

                                                  // Display recipient chips next
                                                  if (recipientMails.isNotEmpty && recipientNames.isNotEmpty) {
                                                    for (int i = 0; i < recipientMails.length; i++) {
                                                      final String name = recipientNames[i];
                                                      final String email = recipientMails[i];
                                                      double chipWidth = estimateChipWidth(name.isNotEmpty ? name : email);

                                                      // Add spacing between chips
                                                      if (chips.isNotEmpty) chipWidth += chipSpacing;
                                                      
                                                      Widget? chipp = recipientChip(
                                                                name,
                                                                email,
                                                                FluentTheme.of(context).accentColor,
                                                                () => setState(() {}),
                                                                false,
                                                                false,
                                                              );
                                                      
                                                      // Check if the chip fits in the remaining space
                                                      if (usedWidth + chipWidth + plusChipWidth <= availableWidth) {
                                                        chips.add(
                                                          GestureDetector(
                                                            behavior: HitTestBehavior.opaque,
                                                            onTap: () => openMailDialog(context, mail, constraints),
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(right: 4.0),
                                                              child: chipp,
                                                            ),
                                                          ),
                                                        );
                                                        usedWidth += chipWidth;
                                                      } else {
                                                        reservePlusChip = true;
                                                        //print('added recipient to remainingItems');
                                                        remainingItems.add(richTooltipRecipient(name, email, true)); // Add to remaining items
                                                      }
                                                    }
                                                  }

                                                  // Add "+X" chip if needed
                                                  if (reservePlusChip) {
                                                    final remainingCount = (uffici.length + recipientMails.length) - chips.length;
                                                    chips.add(
                                                      Tooltip(
                                                        useMousePosition: false,
                                                        style: const TooltipThemeData(
                                                          preferBelow: true,
                                                          waitDuration: Duration.zero,
                                                        ),
                                                        richMessage: getRemainingItemsTooltip(remainingItems),
                                                        child: mat.RawChip(
                                                          side: BorderSide(color: FluentTheme.of(context).accentColor),
                                                          color: WidgetStatePropertyAll(FluentTheme.of(context).accentColor.withOpacity(.25)),
                                                          padding: const EdgeInsets.fromLTRB(0, 5.0, 0, 5.0),
                                                          label: Text(
                                                            "+$remainingCount",
                                                            style: const TextStyle(),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  return Row(children: chips);
                                                },
                                              ),
                                            ),
                                            // allegati
                                            SizedBox(
                                              width: 63,
                                              child: (attachments.isNotEmpty)
                                                  ? Tooltip(
                                                      useMousePosition: false,
                                                      style: const TooltipThemeData(
                                                        //maxWidth: 500,
                                                        preferBelow: true,
                                                        waitDuration: Duration.zero,
                                                      ),
                                                      message: attachments.map((attachment) => getFileNameFromPath(attachment)).join('\n'),
                                                      child: mat.RawChip(
                                                        padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                                                        label: Text(
                                                          attachments.length.toString(),
                                                          style: const TextStyle(),
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    });
                  }),
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
