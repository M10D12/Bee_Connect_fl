import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'beeconnect.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE apiaries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            location TEXT,
            environment TEXT,
            latitude REAL,
            longitude REAL,
            imageBase64 TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE hives (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            creation_date TEXT,
            description TEXT,
            image TEXT,
            apiary_id TEXT
          )
        ''');
      },
    );
  }

  // ------------------ APIARIES ------------------

  Future<void> insertApiary(
    String id,
    String name,
    String location,
    String env,
    double lat,
    double lon,
    String? imageBase64,
  ) async {
    final db = await database;
    await db.insert(
      'apiaries',
      {
        'id': id,
        'name': name,
        'location': location,
        'environment': env,
        'latitude': lat,
        'longitude': lon,
        'imageBase64': imageBase64,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getApiaries() async {
    final db = await database;
    return await db.query('apiaries');
  }

  Future<void> deleteApiary(int id) async {
    final db = await database;
    await db.delete('apiaries', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------ HIVES ------------------

  Future<void> insertHive({
    required String id,
    required String name,
    String? imageBase64,
    required String apiaryId,
    required String type,
    required String creationDate,
    required String description,
  }) async {
    final db = await database;
    await db.insert(
      'hives',
      {
        'id': id,
        'name': name,
        'image': imageBase64,
        'apiary_id': apiaryId,
        'type': type,
        'creation_date': creationDate,
        'description': description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<List<Map<String, dynamic>>> getHivesByApiary(String apiaryId) async {
    final db = await database;
    return await db.query(
      'hives',
      where: 'apiary_id = ?',
      whereArgs: [apiaryId],
    );
  }

  Future<void> deleteHive(String id) async {
    final db = await database;
    await db.delete('hives', where: 'id = ?', whereArgs: [id]);
  }
}
