import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../functions.dart';
import '../src/manager.dart';
import '../vars.dart';
import '../widgets/page.dart';

class Credentials extends StatefulWidget {
  const Credentials({super.key});

  @override
  State<Credentials> createState() => _CredentialsState();
}

class _CredentialsState extends State<Credentials> with PageMixin {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.text = Manager.sourcePassword ?? '';
    _emailController.text = Manager.sourceMail;
    _nomeController.text = Manager.sourceName;
  }

  bool untouched = true;
  bool get _untouched => _emailController.text == Manager.sourceMail && _passwordController.text == Manager.sourcePassword && _nomeController.text == Manager.sourceName;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Excel')),
      children: [
        Text('Credenziali', style: FluentTheme.of(context).typography.subtitle?.copyWith(fontSize: 24.0)),
        spacer,
        Row(
          children: [
            SizedBox(
              width: 450.0,
              child: Card(
                borderRadius: BorderRadius.circular(8.0),
                child: mat.Material(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: SizedBox(
                          child: IconButton(
                            onPressed: () => launchUrl(Uri.parse('https://myaccount.google.com/apppasswords')),
                            icon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 9.0),
                                  Image.network(
                                    "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/240px-Google_%22G%22_logo.svg.png",
                                    width: 45,
                                    height: 45,
                                  ),
                                  const SizedBox(height: 22.0),
                                  SvgPicture.string(
                                    maggioliSvg,
                                    width: 75,
                                    height: 75,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      mat.Container(
                        width: 1.0,
                        height: 200,
                        color: mat.Colors.white.withOpacity(.3),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nome', style: FluentTheme.of(context).typography.subtitle),
                              const SizedBox(height: 5.0),
                              PasswordBox(
                                controller: _nomeController,
                                revealMode: PasswordRevealMode.visible,
                                placeholder: Manager.sourceName,
                                placeholderStyle: TextStyle(color: Colors.white.withOpacity(.3), fontStyle: FontStyle.italic),
                                leadingIcon: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(mat.Icons.person_outline),
                                ),
                                onChanged: (value) {
                                  setState(() => untouched = _untouched);
                                },
                              ),
                              spacer,
                              //
                              Text('Email', style: FluentTheme.of(context).typography.subtitle),
                              const SizedBox(height: 5.0),
                              PasswordBox(
                                controller: _emailController,
                                revealMode: PasswordRevealMode.visible,
                                placeholder: Manager.sourceMail,
                                placeholderStyle: TextStyle(color: Colors.white.withOpacity(.3), fontStyle: FontStyle.italic),
                                leadingIcon: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(mat.Icons.email_outlined),
                                ),
                                onChanged: (value) {
                                  setState(() => untouched = _untouched);
                                },
                              ),
                              spacer,
                              //
                              Text('Password', style: FluentTheme.of(context).typography.subtitle),
                              const SizedBox(height: 5.0),
                              PasswordBox(
                                controller: _passwordController,
                                revealMode: PasswordRevealMode.peekAlways,
                                placeholder: '•' * (Manager.sourcePassword?.length ?? 0),
                                placeholderStyle: TextStyle(color: Colors.white.withOpacity(.3), fontStyle: FontStyle.italic),
                                leadingIcon: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(mat.Icons.lock_outlined),
                                ),
                                onChanged: (value) {
                                  setState(() => untouched = _untouched);
                                },
                              ),
                              const SizedBox(height: 15.0),
                              if (!untouched)
                                Row(
                                  children: [
                                    Button(
                                      child: const Text('Cancella'),
                                      onPressed: () {
                                        setState(() {
                                          _emailController.text = Manager.sourceMail;
                                          _passwordController.text = Manager.sourcePassword ?? '';
                                          _nomeController.text = Manager.sourceName;
                                          untouched = true;
                                        });
                                      },
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      child: const Text('Conferma Credenziali'),
                                      onPressed: () {
                                        if (_nomeController.text.trim().isEmpty) {
                                          snackBar(
                                            'Inserisci il nome',
                                            severity: InfoBarSeverity.warning,
                                          );
                                          return;
                                        }
                                        if (_emailController.text.trim().isEmpty) {
                                          snackBar(
                                            'Inserisci l\'email',
                                            severity: InfoBarSeverity.warning,
                                          );
                                          return;
                                        }
                                        if (_passwordController.text.trim().isEmpty) {
                                          snackBar(
                                            'Inserisci la password',
                                            severity: InfoBarSeverity.warning,
                                          );
                                          return;
                                        }

                                        setState(() {
                                          Manager.sourcePassword = _passwordController.text.trim();
                                          Manager.sourceMail = _emailController.text.trim();
                                          Manager.sourceName = _nomeController.text.trim();
                                        });
                                        SettingsManager.saveSettings({
                                          'password': Manager.sourcePassword,
                                          'sourceMail': Manager.sourceMail,
                                          'sourceName': Manager.sourceName,
                                        });
                                        snackBar(
                                          'Credenziali impostate correttamente',
                                          severity: InfoBarSeverity.success,
                                        );

                                        infoBadge('/credentials', null);
                                        untouched = true;
                                      },
                                    )
                                  ],
                                )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink())
          ],
        ),
      ],
    );
  }
}
