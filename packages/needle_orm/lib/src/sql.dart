import 'dart:async';

// ignore: constant_identifier_names
enum DatabaseType { MariaDB, PostgreSQL }

abstract class Database {
  final DatabaseType databaseType;
  final String databaseVersion;

  const Database(this.databaseType, this.databaseVersion);

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

  static Future<void> closeAll() async {
    for (var db in _map.values) {
      await db.close();
    }
  }

  /// Executes a single query.
  Future<DbQueryResult> query(
      String sql, Map<String, dynamic> substitutionValues,
      {List<String> returningFields = const [], String? tableName});

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
