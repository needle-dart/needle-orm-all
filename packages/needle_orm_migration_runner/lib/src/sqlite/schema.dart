import 'dart:async';
import 'package:needle_orm_migration/needle_orm_migration.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'table.dart';

class SqliteSchema extends Schema {
  final _log = Logger('SqliteSchema');

  final int _indent;
  final StringBuffer _buf;

  SqliteSchema._(this._buf, this._indent);

  factory SqliteSchema() => SqliteSchema._(StringBuffer(), 0);

  Future<int> run(sqlite.Database connection) async {
    var sql = compile();
    print(sql);
    connection.prepare(sql).execute();
    return 0;
  }

  String compile() => _buf.toString();

  void _writeln(String str) {
    for (var i = 0; i < _indent; i++) {
      _buf.write('  ');
    }

    _buf.writeln(str);
  }

  @override
  void drop(String tableName, {bool cascade = false}) {
    var c = cascade == true ? ' CASCADE' : '';
    _writeln('DROP TABLE $tableName$c;');
  }

  @override
  void alter(String tableName, void Function(MutableTable table) callback) {
    var tbl = SqliteAlterTable(tableName);
    callback(tbl);
    _writeln('ALTER TABLE $tableName');
    tbl.compile(_buf, _indent + 1);
    _buf.write(';');
  }

  void _create(String tableName, void Function(MigrationTable table) callback,
      bool ifNotExists) {
    var op = ifNotExists ? ' IF NOT EXISTS' : '';
    var tbl = SqliteTable();
    callback(tbl);
    _writeln('CREATE TABLE$op $tableName (');
    tbl.compile(_buf, _indent + 1);
    _buf.writeln();
    _writeln(');');
  }

  @override
  void create(String tableName, void Function(MigrationTable table) callback) =>
      _create(tableName, callback, false);

  @override
  void createIfNotExists(
          String tableName, void Function(MigrationTable table) callback) =>
      _create(tableName, callback, true);
}
