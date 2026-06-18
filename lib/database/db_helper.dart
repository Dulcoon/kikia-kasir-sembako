import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

class DbHelper {
  DbHelper._();

  static const String _dbFileName = 'warungkasir.db';

  static Database? _database;

  static Future<Database> get database async {
    return _database ??= await _open();
  }

  static Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  static Future<Database> _open() async {
    final path = await _dbPath();
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
    );
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
