import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';

import 'functions.dart';
import 'manager.dart';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cross_file/cross_file.dart';

import 'screens/email.dart';

class EmailSender {
  /// Sends an email with optional subject, body, and attachments.
  Future<bool> sendEmail({
    required List<String> bcc, // BCC recipients
    String? subject,
    String? body,
    List<XFile>? attachments, // Attachments as XFile objects
  }) async {
    final String? password = Manager.password;

    if (password == null || password.isEmpty) {
      snackBar('Password non impostata. Configura la password nelle Impostazioni.', severity: InfoBarSeverity.error);
      return false;
    }

    // Configura il server SMTP (aggiorna con i dettagli corretti, se necessari)
    final smtpServer = gmail(Manager.sourceMail, Manager.password!); // Gmail SMTP
    
    String formattedSubject = convertToHtml(subject ?? '');

    // Crea l'email
    final message = Message()
      ..from = Address(Manager.sourceMail, 'Daniele Mason') // Mittente con nome opzionale
      ..bccRecipients.addAll(bcc) // Aggiungi destinatari BCC
      ..subject = formattedSubject // Oggetto
      ..text = body ?? '' // Testo della mail
      ..attachments = attachments != null ? attachments.map((xFile) => FileAttachment(File(xFile.path))).toList() : [];

    try {
      // Invia l'email
      final sendReport = await send(message, smtpServer);
      print('Email inviata con successo: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('Errore durante l\'invio della mail: $e');
      return false;
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.text = Manager.password ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password Email'),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  Manager.password = _passwordController.text.trim();
                });
                snackBar(
                  'Password impostata correttamente',
                  severity: InfoBarSeverity.success,
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
