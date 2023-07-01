import 'dart:async';

import 'sql_adapter.dart';

// ignore: constant_identifier_names
enum DbCategory { MariaDB, PostgreSQL, Sqlite }

class DbType {
  final DbCategory category;
  final String version;

  DbType(this.category, this.version);
}

/// abstract class for all kinds of Database.
abstract class Database {
  final DbType dbType;

  const Database(this.dbType);

  static const String defaultDbName = "defaultDb";
  static final Map<String, Database> _map = {};

  static Database get defaultDb => lookup(defaultDbName)!;
  static set defaultDb(Database db) {
    _map[defaultDbName] = db;
  }

  static void register(String name, Database db) {
    // first one will be the default. or you can set default db explictly
    if (_map.isEmpty) {
      _map[defaultDbName] = db;
    }
    _map[name] = db;
  }

  static Database? lookup(String dbName) {
    return _map[dbName];
  }

  /// return all databases registered!
  static Map<String, Database> all() {
    return Map.unmodifiable(_map);
  }

  static Future<void> closeAll() async {
    for (var db in _map.values) {
      await db.close();
    }
  }

  /// Executes a single query.
  Future<DbQueryResult> query(
      String sql, Map<String, dynamic> substitutionValues,
      {List<String> returningFields = const [],
      String? tableName,
      Map<String, QueryHint> hints = const {}});

  /// Enters a database transaction, performing the actions within,
  /// and returning the results of [f].
  ///
  /// If [f] fails, the transaction will be rolled back, and the
  /// responsible exception will be re-thrown.
  ///
  /// Whether nested transactions are supported depends on the
  /// underlying driver.
  Future<T> transaction<T>(FutureOr<T> Function(Database) f);

  Future<void> close();

  Future<void> truncate(String tableName) {
    return query(truncateTable(tableName, dbType), {});
  }
}

enum QueryHint {
  lob,
}

abstract class DbQueryResult implements List<List> {
  /// How many rows did this query affect?
  int? get affectedRowCount;
  List<DbColumnDescription> get columnDescriptions;
}

abstract class DbColumnDescription {
  /// The name of the column returned by the query.
  String get columnName;

  /// The resolved name of the referenced table.
  String get tableName;
}
