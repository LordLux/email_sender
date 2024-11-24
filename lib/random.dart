import 'dart:math';

import 'src/database.dart' as db;

/// Generate random email entries
Map<String, dynamic> generateRandomEmail() {
  final random = Random();

  // Generate a random subject
  String subject = "Subject ${random.nextInt(1000)}";

  // Generate random recipients
  int recipientCount = random.nextInt(20) + 1; // Between 1 and 20 recipients
  List<String> emails = List.generate(
    recipientCount,
    (index) => "user${random.nextInt(1000)}@example.com",
  );
  List<String> names = List.generate(
    recipientCount,
    (index) => "Name${random.nextInt(1000)}",
  );
  String recipients = db.joinRecipients(emails, names);

  // Generate a random body
  String body = "This is a random email body number ${random.nextInt(1000)}.";

  // Generate random attachment paths
  int attachmentCount = random.nextInt(6); // Between 0 and 5 attachments
  List<String> attachments = List.generate(
    attachmentCount,
    (index) => "/path/to/attachment${random.nextInt(100)}.file",
  );
  String attachmentsString = attachments.join(',');

  return {
    "subject": subject,
    "recipients": recipients,
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