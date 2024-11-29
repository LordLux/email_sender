import 'dart:math';

import 'package:recase/recase.dart';

import 'src/database.dart' as db;

String generateRandomString(int length) {
  final random = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join().titleCase;
}

/// Generate random email entries
Map<String, dynamic> generateRandomEmail() {
  final random = Random();

  // Generate a random subject
  String subject = "Subject ${generateRandomString(random.nextInt(20) + 20)}";

  // Generate random uffici
  int ufficiCount = random.nextInt(2) + 0; // Between 0 and 2 uffici
  List<String> uffici = List.generate(
    ufficiCount,
    (index) {
      String ufficio = "Ufficio${generateRandomString(random.nextInt(20))}";
      int recipientCount = random.nextInt(5) + 1; // Between 1 and 5 recipients
      List<String> emails = List.generate(
        recipientCount,
        (index) => "user${generateRandomString(random.nextInt(20))}@example.com",
      );
      List<String> names = List.generate(
        recipientCount,
        (index) => "Name${generateRandomString(random.nextInt(20))}",
      );
      List<String> comuni = List.generate(
        recipientCount,
        (index) => "Comune${generateRandomString(random.nextInt(20))}",
      );
      String recipients = db.joinRecipients(emails, names, comuni);
      return "$ufficio[$recipients]";
    },
  );

  // Generate random recipients
  int recipientCount = random.nextInt(2) + (uffici.isEmpty ? 1 : 0); // Between 0 or 1 and 2 recipients
  List<String> emails = List.generate(
    recipientCount,
    (index) => "user${generateRandomString(random.nextInt(20))}@example.com",
  );
  List<String> names = List.generate(
    recipientCount,
    (index) => "Name${generateRandomString(random.nextInt(20))}",
  );
  String recipients = (recipientCount == 0) ? "" : db.joinRecipients(emails, names);

  // Generate a random body
  String body = "This is a random email body number ${generateRandomString(random.nextInt(200))}.";

  // Generate random attachment paths
  int attachmentCount = random.nextInt(6) + 0; // Between 0 and 5 attachments
  List<String> attachments = List.generate(
    attachmentCount,
    (index) => "\\path\\to\\attachment${generateRandomString(random.nextInt(10))}${random.nextInt(1000)}.file",
  );
  String attachmentsString = attachments.join(',');

  /*print('''Generated random email:
  \tSubject: '$subject'
  \tRecipients: '$recipients'
  \tUffici: '${uffici.join(', ')}'
  \tBody: '$body'
  \tAttachments: '$attachmentsString\'''');*/
  print('Generated random email: ufficiCount: $ufficiCount, recipientCount: $recipientCount, attachmentCount: $attachmentCount,\nRecipients: \'$recipients\'\tUffici: \'${uffici.join(', ')}');

  return {
    "subject": subject,
    "recipients": recipients,
    "uffici": uffici.join(', '),
    "body": body,
    "attachments": attachmentsString,
    "timestamp": DateTime.now().toUtc().toIso8601String(),
  };
}

Future<void> addRandomEmails(int count) async {
  for (int i = 0; i < count; i++) {
    await db.emailDb.addEmail(db.Email.fromMap(generateRandomEmail()));
  }
}
