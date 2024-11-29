import 'package:email_sender/screens/excel.dart';
import 'package:recase/recase.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

import 'classes.dart';

// Model class for Email
class Email {
  int? id; // Primary key (optional)
  String subject;
  String body;
  String uffici; // Comma-separated list of uffici 'Ufficio1[recipient1Name <recipient1Email>, recipient2Name <recipient2Email>], Ufficio2[...]'
  String recipients; // Comma-separated list of recipients 'Name <email>, Name <email>, ...'
  String attachments; // Comma-separated list of attachment paths
  String timestamp; // ISO 8601 formatted timestamp

  Email({
    this.id,
    required this.timestamp,
    required this.uffici,
    required this.recipients,
    required this.subject,
    required this.body,
    required this.attachments,
  });

  // Convert Email object to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'uffici': uffici,
      'recipients': recipients,
      'subject': subject,
      'body': body,
      'attachments': attachments,
    };
  }

  // Create Email object from Map (from database)
  factory Email.fromMap(Map<String, dynamic> map) {
    return Email(
      id: map['id'],
      timestamp: map['timestamp'],
      uffici: map['uffici'],
      recipients: map['recipients'],
      subject: map['subject'],
      body: map['body'],
      attachments: map['attachments'],
    );
  }
}

// Database Helper Class

final emailDb = EmailDatabase();

class EmailDatabase {
  static final EmailDatabase _instance = EmailDatabase._internal();
  static Database? _database;

  EmailDatabase._internal();

  factory EmailDatabase() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emails.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE emails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            uffici TEXT,
            recipients TEXT,
            subject TEXT,
            body TEXT,
            attachments TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE emails ADD COLUMN timestamp TEXT');
        }
        if (oldVersion < 3) {
          db.execute('ALTER TABLE emails ADD COLUMN uffici TEXT');
        }
      },
    );
  }

  // Add a new email to the database
  Future<int> addEmail(Email email) async {
    final db = await database;
    return await db.insert(
      'emails',
      email.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all emails from the database
  Future<List<Email>> getEmails() async {
    final db = await database;
    final List<Map<String, dynamic>> emailMaps = await db.query('emails');
    return emailMaps.map((map) => Email.fromMap(map)).toList();
  }

  // Update an existing email in the database
  Future<int> updateEmail(Email email) async {
    final db = await database;
    return await db.update(
      'emails',
      email.toMap(),
      where: 'id = ?',
      whereArgs: [email.id],
    );
  }

  // Delete an email from the database
  Future<int> deleteEmail(int id) async {
    final db = await database;
    return await db.delete(
      'emails',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cleanDatabase() async {
    final db = await database;

    await db.delete('emails');
    print('All entries in the emails table have been deleted.');
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emails.db');

    await deleteDatabase(path);
    print('Database deleted.');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

// JOIN functions
/// Join the recipients into a single string 'Name <email>, Name <email>, ...'
String joinRecipients(List<String> emails, List<String> names, [List<String> comuni = const []]) {
  assert(names.length == emails.length, 'Emails and names must have the same length.: "$emails", "$names"');
  if (emails.isEmpty || names.isEmpty) {
    print('No recipients found: emails: "$emails", names: "$names"');
    return "";
  }
  return List.generate(emails.length, (index) {
    if (names.length > index) return '${names[index]} ${comuni.isEmpty ? '' : "(${comuni[index]}) "}<${emails[index]}>';
    return emails[index];
  }).join(', ');
}

/// Join the uffici into a single string 'Ufficio1[recipient1Name <recipient1Email>, recipient2Name (comune2) <recipient2Email>], Ufficio2[...]'
String joinUffici(List<Ufficio> uffici) {
  return List.generate(uffici.length, (index) {
    final Ufficio ufficio = uffici[index];
    if (ufficio.entries.isNotEmpty) {
      final List<String> emails = ufficio.entries.map((entry) => entry[2]).toList();
      final List<String> ufficiNames = ufficio.entries.map((entry) => entry[1]).toList();
      return "${ufficio.nome}[${joinRecipients(emails, ufficiNames)}]";
    }
    return '';
  }).join(', ');
}

// SPLIT functions
/// Split the recipients string into a list of emails and a list of names from 'Name <email>, Name <email>, ...' to ['email', 'email', ...] and ['Name', 'Name', ...]
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

/// Split the uffici string into a list of Ufficio objects
/// Format: 'Ufficio1[recipient1Name <recipient1Email>, recipient2Name (recipient2Comune) <recipient2Email>], Ufficio2[...]'
List<Ufficio> parseUffici(String uffici) {
  List<String> ufficiList = uffici.split('],'); // Split by Ufficio entries
  List<Ufficio> ufficiObjects = [];

  for (String ufficio in ufficiList) {
    if (ufficio.isNotEmpty) {
      // Extract the Ufficio name
      final String nome = ufficio.split('[')[0].trim();

      // Extract the Ufficio entries (inside square brackets)
      final String entriesPart = ufficio.contains('[') ? ufficio.split('[')[1].replaceAll(']', '').trim() : '';

      // Split the entries into individual participants
      List<String> ufficiParticipants = entriesPart.split(',');

      // Parse each participant
      List<List<String>> entriesData = [];
      for (String participant in ufficiParticipants) {
        participant = participant.trim();
        if (participant.isNotEmpty) {
          String name = '';
          String email = '';
          String comune = '';

          if (participant.contains('<') && participant.contains('>')) {
            // Extract email
            email = participant.split('<')[1].replaceAll('>', '').trim(); // Extract Email

            // Extract comune if present (e.g., "Name (Comune) <email>")
            name = participant.split('<')[0].trim(); // Extract Name (Comune)
            if (name.contains('(') && name.contains(')')) {
              comune = name.split('(')[1].replaceAll(')', '').trim(); // Extract comune
              name = name.split('(')[0].trim(); // Take the name without the comune
            }
          }

          entriesData.add([name, comune, email]);
        }
      }

      // Create the Ufficio object
      ufficiObjects.add(
        Ufficio(
          nome: nome,
          headers: ['Name', 'Comune', 'Email'],
          entries: entriesData,
        ),
      );
    }
  }

  return ufficiObjects;
}

// DATES

String fromIso8061String(String iso8601String, DateFormat format) {
  final DateTime dateTime = DateTime.parse(iso8601String);
  return format.format(dateTime);
}

String formatDate(String date, [bool fullDate = false, bool fullfullDate = false]) {
  DateTime dateTime = DateTime.parse(date);
  final DateTime now = DateTime.now();

  if (fullfullDate) return fromIso8061String(date, DateFormat('HH:mm:ss - dd MMMM yyyy', 'it'));

  DateFormat format = DateFormat('HH:mm');

  if (fullDate) {
    if (dateTime.year != now.year)
      format = DateFormat('HH:mm:ss - dd MMM yyyy', 'it');
    else
      format = DateFormat('HH:mm:ss - dd MMM', 'it');
    return fromIso8061String(date, format).titleCase;
  }

  // If the year is different, show the full date
  if (dateTime.year != now.year)
    format = DateFormat('dd MMM yy', 'it');

  // If the day or month is different, show the day and month
  else if (dateTime.day != now.day || dateTime.month != now.month)
    format = DateFormat('dd MMM', 'it');

  // If the hour is different, show the hour and minute
  else
    format = DateFormat('HH:mm');

  return fromIso8061String(date, format).titleCase;
}
