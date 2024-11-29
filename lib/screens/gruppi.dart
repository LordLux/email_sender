import 'package:email_sender/vars.dart';
import 'package:email_sender/widgets/card_highlight.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/material.dart' as mat;
import 'package:smooth_highlight/smooth_highlight.dart';
import 'package:recase/recase.dart';

import '../src/classes.dart';
import '../functions.dart';
import '../src/manager.dart';
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

  void changeMultiSelection(bool value) {
    setState(() {
      Manager.multiSelection = value;
      if (!Manager.multiSelection && Manager.selectedGroups.isNotEmpty) // Keep only the first element of the list if multiSelection has just been disabled
        Manager.selectedGroups = [Manager.uffici.firstWhere((ufficio) => Manager.selectedGroups.contains(ufficio))];
    });
  }

  Future<void> loadData() async {
    if (Manager.excelPath == null) return;

    if (Manager.uffici.isEmpty) await Manager.loadExcel();
    if (Manager.uffici.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkEmails(Manager.uffici, context, () => setState(() {}));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }
  
  @override
  void dispose() {
    super.dispose();
    Manager.extraRecNameController.dispose();
    Manager.extraRecEmailController.dispose();
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
        if (Manager.uffici.isNotEmpty)
          Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: const TooltipThemeData(
                          maxWidth: 500,
                          waitDuration: Duration.zero,
                        ),
                        child: Card(
                          padding: EdgeInsets.zero,
                          child: IconButton(
                            onPressed: () => changeMultiSelection(!Manager.multiSelection),
                            icon: SizedBox(
                              height: 30,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Selezione Multipla'),
                                  const SizedBox(width: 8),
                                  MouseRegion(
                                    hitTestBehavior: HitTestBehavior.opaque,
                                    child: ToggleSwitch(
                                      checked: Manager.multiSelection,
                                      onChanged: (value) => changeMultiSelection(value),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (Manager.uffici.isNotEmpty)
                  mat.Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        direction: Axis.horizontal,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4.0,
                        children: <Widget>[
                              Text('Gruppi:', style: headerStyle),
                            ] +
                            ((Manager.selectedGroups.isNotEmpty)
                                ? <Widget>[
                                    for (final ufficio in Manager.selectedGroups)
                                      ufficioChip(
                                        ufficio,
                                        FluentTheme.of(context).accentColor,
                                        () {
                                          if (Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty) infoBadge("/gruppi", null);
                                          setState(() {});
                                        },
                                      ),
                                  ]
                                : <Widget>[] //
                            ),
                      ),
                    ),
                  ),
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
                                    infoBadge('/gruppi', true);
                                  } else {
                                    Manager.selectedGroups.remove(ufficio);
                                    if (Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty) infoBadge("/gruppi", null);
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
        if (Manager.uffici.isNotEmpty) spacer,
        if (Manager.uffici.isNotEmpty)
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
                                          if (Manager.selectedGroups.isEmpty && Manager.extraRecipients.isEmpty) infoBadge("/gruppi", null);
                                          setState(() {});
                                        },
                                      ) ?? const SizedBox(),
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
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Inserisci il nome del destinatario';
                              print('value: "${value.trim()}", ${value.trim().length}');
                              return null;
                            },
                            placeholder: 'Nome',
                          ),
                          const SizedBox(height: 8),
                          TextFormBox(
                            controller: Manager.extraRecEmailController,
                            placeholder: 'Email',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Inserisci un\'email';
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
                                    if (Manager.extraRecEmailController.text.trim().isEmpty) return;
                                    try {
                                      final String name;
                                      if (Manager.extraRecNameController.text.length > 2)
                                        name = Manager.extraRecNameController.text.split(" ").map((e) => '${e[0].toUpperCase()}${e.substring(1)}').join(" ");
                                      else
                                        name = Manager.extraRecNameController.text.titleCase;

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
                                    } catch (e) {
                                      print(e);
                                      snackBar('Errore durante l\'aggiunta del destinatario:\n${e.toString()}', severity: InfoBarSeverity.error, hasError: true);
                                    }
                                    /*snackBar(
                                    'Destinatario${name.isNotEmpty ? " $name " : " "}aggiunto con successo',
                                    severity: InfoBarSeverity.success,
                                  );*/
                                    Manager.extraRecNameController.clear();
                                    Manager.extraRecEmailController.clear();

                                    infoBadge("/gruppi", true);
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
