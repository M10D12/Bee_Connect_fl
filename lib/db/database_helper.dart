import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'beeconnect.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE apiaries(id TEXT PRIMARY KEY, name TEXT, location TEXT)',
        );
      },
    );
  }

  Future<void> insertApiary(String id, String name, String location) async {
    final db = await database;
    await db.insert(
      'apiaries',
      {'id': id, 'name': name, 'location': location},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getApiaries() async {
    final db = await database;
    return db.query('apiaries');
  }

  Future<void> deleteApiary(String id) async {
    final db = await database;
    await db.delete('apiaries', where: 'id = ?', whereArgs: [id]);
  }
}
