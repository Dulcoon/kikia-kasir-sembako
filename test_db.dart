import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  // Search path candidates
  final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final candidates = [
    p.join(homeDir, 'Documents', 'warungkasir.db'),
    p.join(Directory.current.path, '.dart_tool', 'sqflite_common_ffi', 'databases', 'warungkasir.db'),
    p.join(Directory.current.path, '.dart_tool', 'sqflite_common_ffi', 'databases', 'kasirsembako.db'),
    '/home/dulcoon/projects/kasirsembako/.dart_tool/sqflite_common_ffi/databases/kasirsembako.db',
  ];

  String? dbPath;
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      dbPath = candidate;
      break;
    }
  }

  if (dbPath == null) {
    print('=== Database Not Found ===');
    print('Tested paths:');
    for (final c in candidates) {
      print(' - $c');
    }
    print('\nTo test with your emulator/device database, pull the database using ADB:');
    print('  mkdir -p .dart_tool/sqflite_common_ffi/databases/');
    print('  adb pull /data/data/com.example.kasirsembako/databases/warungkasir.db .dart_tool/sqflite_common_ffi/databases/warungkasir.db');
    print('\nAfter pulling, run this test script again.');
    return;
  }
  
  print('Using database at: $dbPath');
  final db = await databaseFactory.openDatabase(dbPath);
  final rows = await db.query('transactions', orderBy: 'created_at DESC');
  print('Total transactions: ${rows.length}');
  
  for (var r in rows) {
    final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int);
    print('${r['invoice_number']} - ${dt.toIso8601String()}');
  }

  // test filter 16 - 18
  final start = DateTime(2026, 6, 16);
  final end = DateTime(2026, 6, 18).add(Duration(days: 1));
  print('\nFilter Test: start=$start, end=$end');
  
  final filtered = await db.query(
    'transactions',
    where: 'created_at >= ? AND created_at < ?',
    whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    orderBy: 'created_at DESC'
  );
  print('Filtered transactions: ${filtered.length}');
  for (var r in filtered) {
    final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int);
    print('${r['invoice_number']} - ${dt.toIso8601String()}');
  }
}
