import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/color_project.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('color_pop.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  avatarPath TEXT NOT NULL
)
''');
      // Create default user
      await db.insert('users', {
        'name': 'Alex',
        'avatarPath': 'assets/images/avatars/avatar_1.png',
      });
    }
  }

  Future _createTables(Database db) async {
    await db.execute('''
CREATE TABLE projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  imagePath TEXT NOT NULL,
  status TEXT NOT NULL,
  createdAt INTEGER NOT NULL
)
''');
    
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  avatarPath TEXT NOT NULL
)
''');
    
    // Create default user
    await db.insert('users', {
      'name': 'Alex',
      'avatarPath': 'assets/images/avatars/avatar_1.png', // Or some default asset path
    });
  }

  Future<int> insertProject(ColorProject project) async {
    final db = await instance.database;
    return await db.insert('projects', project.toMap());
  }

  Future<int> updateProject(ColorProject project) async {
    final db = await instance.database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<List<ColorProject>> getProjectsByStatus(String status) async {
    final db = await instance.database;
    final result = await db.query(
      'projects',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => ColorProject.fromMap(json)).toList();
  }
  
  Future<List<ColorProject>> getAllProjects() async {
    final db = await instance.database;
    final result = await db.query(
      'projects',
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => ColorProject.fromMap(json)).toList();
  }

  Future<Map<String, int>> getStats() async {
    final db = await instance.database;
    final inProgressCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM projects WHERE status = ?', ['in_progress'])
    ) ?? 0;
    
    final completedCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM projects WHERE status = ?', ['completed'])
    ) ?? 0;

    return {
      'in_progress': inProgressCount,
      'completed': completedCount,
    };
  }

  // --- User Operations ---

  Future<UserModel> getUser() async {
    final db = await instance.database;
    final result = await db.query('users', limit: 1);
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    } else {
      // Fallback if empty for some reason
      return UserModel(name: 'Alex', avatarPath: 'assets/images/avatars/avatar_1.png');
    }
  }

  Future<int> updateUser(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
