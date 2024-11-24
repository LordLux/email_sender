import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

// Model class for Email
class Email {
  int? id; // Primary key (optional)
  String subject;
  String body;
  String recipients; // Comma-separated list of recipients
  String attachments; // Comma-separated list of attachment paths
  String timestamp; // ISO 8601 formatted timestamp

  Email({
    this.id,
    required this.subject,
    required this.body,
    required this.recipients,
    required this.attachments,
    required this.timestamp,
  });

  // Convert Email object to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipients': recipients,
      'subject': subject,
      'body': body,
      'attachments': attachments,
      'timestamp': timestamp,
    };
  }

  // Create Email object from Map (from database)
  factory Email.fromMap(Map<String, dynamic> map) {
    return Email(
      id: map['id'],
      subject: map['subject'],
      body: map['body'],
      recipients: map['recipients'],
      attachments: map['attachments'],
      timestamp: map['timestamp'],
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
      version: 2,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE emails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT,
            body TEXT,
            recipients TEXT,
            attachments TEXT,
            timestamp TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE emails ADD COLUMN timestamp TEXT');
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
}

String joinRecipients(List<String> emails, List<String> names) {
  assert(emails.isNotEmpty && names.isNotEmpty && names.length == emails.length);
  return List.generate(emails.length, (index) {
    if (names.isNotEmpty && names.length > index) return '${names[index]} <${emails[index]}>';
    return emails[index];
  }).join(', ');
}

String fromIso8601String(String iso8601String) {
  final DateTime dateTime = DateTime.parse(iso8601String);
  final DateTime now = DateTime.now();

  // If the year is different, show the full date
  if (dateTime.year != now.year) return DateFormat('dd/MM/yyyy').format(dateTime);

  // If the day or month is different, show the day and month
  if (dateTime.day != now.day || dateTime.month != now.month) return DateFormat('dd/MM hh:mm').format(dateTime);

  // If the hour is different, show the hour and minute
  if (now.difference(dateTime).inHours >= 1) return DateFormat('hh:mm').format(dateTime);

  // Otherwise, show the time
  return DateFormat('hh:mm:ss').format(dateTime);
}
