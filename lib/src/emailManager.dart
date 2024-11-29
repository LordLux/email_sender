import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

import '../functions.dart';
import '../src/manager.dart';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cross_file/cross_file.dart';

class EmailSender {
  /// Sends an email with optional subject, body, and attachments.
  Future<bool> sendEmail({
    required List<String> bcc, // BCC recipients
    String? subject,
    String? body,
    List<XFile>? attachments, // Attachments as XFile objects
  }) async {
    final String? password = Manager.sourcePassword;

    if (Manager.sourceMail.isEmpty || password == null || password.isEmpty) {
      snackBar('Credenziali non impostate. Configurarle nella Sezione Credenziali.', severity: InfoBarSeverity.error);
      infoBadge('/credentials', false);
      return false;
    }

    // Configura il server SMTP (aggiorna con i dettagli corretti, se necessari)
    final smtpServer = gmail(Manager.sourceMail, Manager.sourcePassword!); // Gmail SMTP

    String formattedSubject = subject ?? '';

    // Crea l'email
    final message = Message()
      ..from = Address(Manager.sourceMail, Manager.sourceName) // Mittente con nome opzionale
      ..bccRecipients.addAll(bcc) // Aggiungi destinatari BCC
      ..subject = formattedSubject // Oggetto
      //..text = body // Testo della mail
      ..html = body // Testo della mail in HTML
      ..attachments = attachments != null ? attachments.map((xFile) => FileAttachment(File(xFile.path))).toList() : [];

    try {
      // Invia l'email
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) print('Email inviata con successo: $sendReport');
      
      return true;
      //
    } on MailerException catch (e) {
      // Invalid Recipient Address
      if (e.message.contains('The recipient address') && e.message.contains('is not a valid RFC')) {
        final regex = RegExp(r'The recipient address <(.+?)> is not a valid RFC');
        final match = regex.firstMatch(e.message);
        String emailError = "";
        //
        if (match != null && match.groupCount >= 1) {
          emailError = match.group(1) ?? '';
          snackBar('Errore durante l\'invio dell\'Email:\nIndirizzo Email non valido: "$emailError"', severity: InfoBarSeverity.error);
          return false;
        }
        // Fallback to generic error message
        snackBar('Errore durante l\'invio dell\'Email:\nIndirizzo Email non valido.', severity: InfoBarSeverity.error);
        return false;
      }
      
      // Invalid Message
      if (e.message.contains('Invalid Message.') || e is SmtpMessageValidationException) {
        String error = 'Errore durante l\'invio dell\'Email:';
        if (bcc.isEmpty) error += '\nNessun Destinatario specificato';
        snackBar(error, severity: InfoBarSeverity.error);
        return false;
      }
      
      // Authentication Error
      if (e is SmtpClientAuthenticationException) {
        snackBar('Errore durante l\'invio dell\'Email:\nCredenziali non valide.', severity: InfoBarSeverity.error);
        return false;
      }
      
      // Generic Error
      snackBar('Errore durante l\'invio dell\'Email:\n$e', severity: InfoBarSeverity.error, hasError: true);
      return false;
    }
  }
}
