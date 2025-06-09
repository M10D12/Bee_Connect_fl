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
      version: 5,  // <--- Versão atualizada para 5
      onCreate: (db, version) async {
        // Criando a tabela apiaries
        await db.execute('''
        CREATE TABLE apiaries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          location TEXT,
          environment TEXT,
          latitude REAL,
          longitude REAL,
          imageBase64 TEXT,
          owner_username TEXT
        )
      ''');

        // Criando a tabela hives com coluna alcas
        await db.execute('''
          CREATE TABLE hives (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            creation_date TEXT,
            description TEXT,
            image TEXT,
            apiary_id TEXT,
            alcas INTEGER DEFAULT 0  -- <--- NOVO CAMPO!
          )
        ''');

        // Criando a tabela inspecoes
        await db.execute('''
          CREATE TABLE inspecoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hive_id TEXT,
            data TEXT,
            alimentacao TEXT,
            tratamentos TEXT,
            problemas TEXT,
            observacoes TEXT,
            proxima_visita TEXT
          )
        ''');

        // Criando a tabela users
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT,
              password TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS inspecoes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              hive_id TEXT,
              data TEXT,
              alimentacao TEXT,
              tratamentos TEXT,
              problemas TEXT,
              observacoes TEXT,
              proxima_visita TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          // ADICIONA coluna 'alcas' se vier de versão anterior
          await db.execute('''
            ALTER TABLE hives ADD COLUMN alcas INTEGER DEFAULT 0
          ''');
        }
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
    String ownerUsername,
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
        'owner_username': ownerUsername,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getApiaries(String ownerUsername) async {
    final db = await database;
    return await db.query(
      'apiaries',
      where: 'owner_username = ?',
      whereArgs: [ownerUsername],
    );
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
    int alcas = 0,  // <--- novo parametro com default
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
        'alcas': alcas,  // <--- inserir alcas
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

  Future<void> updateHive({
    required String id,
    required String name,
    required String type,
    required String description,
    required int alcas,
  }) async {
    final db = await database;
    await db.update(
      'hives',
      {
        'name': name,
        'type': type,
        'description': description,
        'alcas': alcas,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteHive(String id) async {
    final db = await database;
    await db.delete('hives', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------ INSPECOES ------------------

  Future<void> insertInspecao({
    required String hiveId,
    required String data,
    required String alimentacao,
    required String tratamentos,
    required String problemas,
    required String observacoes,
    String? proximaVisita,
  }) async {
    final db = await database;
    await db.insert(
      'inspecoes',
      {
        'hive_id': hiveId,
        'data': data,
        'alimentacao': alimentacao,
        'tratamentos': tratamentos,
        'problemas': problemas,
        'observacoes': observacoes,
        'proxima_visita': proximaVisita,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getInspecoes(String hiveId) async {
    final db = await database;
    return await db.query(
      'inspecoes',
      where: 'hive_id = ?',
      whereArgs: [hiveId],
      orderBy: 'data DESC',
    );
  }

  // ------------------ USERS ------------------

  Future<void> insertUser(String username, String password) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'username': username,
        'password': password,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateUserProfile(String userId, String name, String email, String? profilePicBase64) async {
    final db = await database;
    await db.update(
      'users',
      {
        'username': name,
        'email': email,
        'profilePic': profilePicBase64,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
