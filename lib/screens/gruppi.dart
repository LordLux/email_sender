import 'package:email_sender/vars.dart';
import 'package:email_sender/widgets/card_highlight.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/material.dart' as mat;
import 'package:smooth_highlight/smooth_highlight.dart';
import 'package:recase/recase.dart';

import '../classes.dart';
import '../functions.dart';
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
final GlobalKey<FormState> extraRecipientsFormKey = GlobalKey<FormState>();

class _MailingListsState extends State<MailingLists> with PageMixin {
  bool isHighlighted = false;
  bool isHighlighted2 = false;

  Future<void> loadData() async {
    if (Manager.excelPath == null) return;

    if (Manager.uffici.isEmpty) await Manager.loadExcel();
    if (Manager.uffici.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateInfoBadge("/excel", const InfoBadge(source: Icon(mat.Icons.check), color: mat.Colors.lightGreen), true);
        setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Destinatari')),
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
        Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 3,
                    child: mat.Material(
                      color: Colors.transparent,
                      child: ValueChangeHighlight(
                        duration: const Duration(milliseconds: 400),
                        value: isHighlighted,
                        color: FluentTheme.of(context).accentColor.withOpacity(.5),
                        child: Card(
                          child: Text(
                            'Seleziona i gruppi a cui vuoi inviare l\'email:',
                            style: headerStyle,
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
                    child: SizedBox(
                      height: Manager.uffici.length * 44.0,
                      child: ListView.builder(
                        itemCount: Manager.uffici.length,
                        itemBuilder: (context, index) {
                          //
                          final Ufficio ufficio = Manager.uffici[index];
                          return Tooltip(
                            useMousePosition: false,
                            style: const TooltipThemeData(
                              maxWidth: 500,
                              preferBelow: true,
                              waitDuration: Duration.zero,
                            ),
                            richMessage: TextSpan(
                              children: [
                                TextSpan(text: ufficio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' (${ufficio.entries.length} destinatari)\n', style: TextStyle(color: Colors.white.withOpacity(.5))),
                                TextSpan(text: ufficio.entries.map((e) => "${e[1]} - ${e[2]}").join('\n')),
                              ],
                            ),
                            child: ListTile.selectable(
                              title: Text.rich(TextSpan(children: [
                                TextSpan(text: '${ufficio.nome} '),
                                TextSpan(text: '(${ufficio.entries.length} destinatari)', style: TextStyle(color: Colors.white.withOpacity(.5))),
                              ])),
                              selected: Manager.selectedGroups.any((element) => element.hash == ufficio.hash),
                              selectionMode: ListTileSelectionMode.single,
                              onPressed: () {
                                final bool selected = !Manager.selectedGroups.contains(ufficio);
                                if (selected) {
                                  if (!Manager.multiSelection) Manager.selectedGroups.clear();
                                  Manager.selectedGroups.add(ufficio);
                                  updateInfoBadge("/gruppi", const InfoBadge(source: Icon(mat.Icons.check), color: mat.Colors.lightGreen));
                                } else {
                                  Manager.selectedGroups.remove(ufficio);
                                  if (Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty) updateInfoBadge("/gruppi", null);
                                }

                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        spacer,
        Expander(
            initiallyExpanded: true,
            header: mat.Material(
              color: Colors.transparent,
              child: ValueChangeHighlight(
                duration: const Duration(milliseconds: 400),
                value: isHighlighted2,
                color: FluentTheme.of(context).accentColor.withOpacity(.5),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.0,
                      children: <Widget>[
                            Text(
                              'Destinatari Extra:',
                              style: headerStyle,
                            ),
                          ] +
                          ((Manager.extraRecipients.isNotEmpty)
                              ? <Widget>[
                                  for (final recipient in Manager.extraRecipients)
                                    recipientChip(
                                      recipient['name'] ?? '',
                                      recipient['email']!,
                                      FluentTheme.of(context).accentColor,
                                      () {
                                        if (Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty) updateInfoBadge("/gruppi", null);
                                        setState(() {});
                                      },
                                    ),
                                ]
                              : [])),
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Form(
                    key: extraRecipientsFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aggiungi destinatari extra:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormBox(
                          controller: Manager.extraRecNameController,
                          placeholder: 'Nome (opzionale)',
                        ),
                        const SizedBox(height: 8),
                        TextFormBox(
                          controller: Manager.extraRecEmailController,
                          placeholder: 'Email',
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Inserisci un\'email';
                            if (!EmailValidator.validate(value)) return 'Inserisci un\'email valida';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Button(
                                child: const Text('Annulla'),
                                onPressed: () {
                                  Manager.extraRecNameController.clear();
                                  Manager.extraRecEmailController.clear();
                                }),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                if (extraRecipientsFormKey.currentState!.validate()) {
                                  extraRecipientsFormKey.currentState!.save();
                                  final String name = Manager.extraRecNameController.text.trim().split(" ").map((e) => e.titleCase).join(" ");

                                  final Map<String, String> extraRec = {
                                    'name': name,
                                    'email': Manager.extraRecEmailController.text.trim(),
                                  };

                                  // Check if the email is already in the list
                                  final existingRecIndex = Manager.extraRecipients.indexWhere((rec) => rec['email'] == extraRec['email']);
                                  if (existingRecIndex != -1) {
                                    // If the name is different, update it
                                    if (Manager.extraRecipients[existingRecIndex]['name'] != extraRec['name']) //
                                      Manager.extraRecipients[existingRecIndex] = extraRec;
                                  } else // Otherwise, add the new recipient
                                    Manager.extraRecipients.add(extraRec);

                                  /*snackBar(
                                    'Destinatario${name.isNotEmpty ? " $name " : " "}aggiunto con successo',
                                    severity: InfoBarSeverity.success,
                                  );*/
                                  Manager.extraRecNameController.clear();
                                  Manager.extraRecEmailController.clear();

                                  updateInfoBadge("/gruppi", const InfoBadge(source: Icon(mat.Icons.check), color: mat.Colors.lightGreen));
                                  setState(() {});
                                }
                              },
                              child: const Text('Aggiungi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}
