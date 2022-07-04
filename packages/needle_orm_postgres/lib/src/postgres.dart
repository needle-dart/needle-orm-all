import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';
import 'package:postgres/postgres.dart';
import 'package:needle_orm/needle_orm.dart';

/// A [QueryExecutor] that queries a PostgreSQL database.
class PostgreSqlDatabase extends Database {
  final PostgreSQLExecutionContext _connection;

  /// An optional [Logger] to print information to. A default logger will be used
  /// if not set
  late Logger logger;

  PostgreSqlDatabase(this._connection, {Logger? logger})
      : super(DatabaseType.PostgreSQL, '10.0') {
    this.logger = logger ?? Logger('PostgreSqlDatabase');
  }

  /// The underlying connection.
  PostgreSQLExecutionContext get connection => _connection;

  /// Closes the connection.
  @override
  Future<void> close() async {
    if (_connection is PostgreSQLConnection) {
      return (_connection as PostgreSQLConnection).close();
    } else {
      return Future.value();
    }
  }

  @override
  Future<DbQueryResult> query(
      String sql, Map<String, dynamic> substitutionValues,
      {List<String> returningFields = const [], String? tableName}) async {
    if (returningFields.isNotEmpty) {
      var fields = returningFields.join(', ');
      var returning = 'RETURNING $fields';
      sql = '$sql $returning';
    }

    logger.config('query: $sql ; params: $substitutionValues');

    // expand List first
    var param = <String, dynamic>{};
    substitutionValues.forEach((key, value) {
      if (value is List) {
        var newKeys = [];
        for (var i = 0; i < value.length; i++) {
          var key2 = '${key}_$i';
          param[key2] = value[i];
          newKeys.add('@$key2');
        }

        var strReplace = "(${newKeys.join(',')})";
        sql = sql.replaceAll('@$key ',
            strReplace); // '@$key ' means all key must be followed by a ' ' to prevent mis-replace!
      } else {
        param[key] = value;
      }
    });

    return PgQueryResult(
        await _connection.query(sql, substitutionValues: param));
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Database) f) async {
    if (_connection is! PostgreSQLConnection) {
      return await f(this);
    }

    var conn = _connection as PostgreSQLConnection;
    T? returnValue;

    var txResult = await conn.transaction((ctx) async {
      try {
        logger.config('Entering transaction');
        var tx = PostgreSqlDatabase(ctx, logger: logger);
        returnValue = await f(tx);

        return returnValue;
      } catch (e) {
        ctx.cancelTransaction(reason: e.toString());
        rethrow;
      } finally {
        logger.config('Exiting transaction');
      }
    });

    if (txResult is PostgreSQLRollback) {
      //if (txResult.reason == null) {
      //  throw StateError('The transaction was cancelled.');
      //} else {
      throw StateError(
          'The transaction was cancelled with reason "${txResult.reason}".');
      //}
    } else {
      return returnValue!;
    }
  }
}

/// A [QueryExecutor] that manages a pool of PostgreSQL connections.
class PostgreSqlDatabasePool extends Database {
  /// The maximum amount of concurrent connections.
  final int size;

  /// Creates a new [PostgreSQLConnection], on demand.
  ///
  /// The created connection should **not** be open.
  final PostgreSQLConnection Function() connectionFactory;

  /// An optional [Logger] to print information to.
  late Logger logger;

  final List<PostgreSqlDatabase> _connections = [];
  int _index = 0;
  late final Pool _pool;
  final _connMutex = Pool(1);

  PostgreSqlDatabasePool(this.size, this.connectionFactory, {Logger? logger})
      : super(DatabaseType.PostgreSQL, '10.0') {
    _pool = Pool(size);
    if (logger != null) {
      this.logger = logger;
    } else {
      this.logger = Logger('PostgreSqlDatabasePool');
    }

    assert(size > 0, 'Connection pool cannot be empty.');
  }

  /// Closes all connections.
  @override
  Future<void> close() async {
    await _pool.close();
    await _connMutex.close();
    Future.wait(_connections.map((c) => c.close()));
  }

  Future<void> _open() async {
    if (_connections.isEmpty) {
      _connections.addAll(await Future.wait(List.generate(size, (_) async {
        logger.config('Spawning connections...');
        var conn = connectionFactory();
        await conn.open();
        //return conn
        //    .open()
        //    .then((_) => PostgreSqlExecutor(conn, logger: logger));
        return PostgreSqlDatabase(conn, logger: logger);
      })));
    }
  }

  Future<PostgreSqlDatabase> _next() {
    return _connMutex.withResource(() async {
      await _open();
      if (_index >= size) _index = 0;
      return _connections[_index++];
    });
  }

  @override
  Future<DbQueryResult> query(
      String sql, Map<String, dynamic> substitutionValues,
      {List<String> returningFields = const [], String? tableName}) {
    return _pool.withResource(() async {
      var executor = await _next();
      return executor.query(sql, substitutionValues,
          returningFields: returningFields, tableName: tableName);
    });
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Database) f) {
    return _pool.withResource(() async {
      var executor = await _next();
      return executor.transaction(f);
    });
  }
}

class PgQueryResult extends DbQueryResult with ListMixin<List> {
  final PostgreSQLResult _result;

  PgQueryResult(this._result);

  @override
  int get length => _result.length;
  @override
  set length(int value) {
    throw UnimplementedError();
  }

  @override
  List operator [](int index) {
    return _result[index];
  }

  @override
  void operator []=(int index, List value) {
    throw UnimplementedError();
  }

  @override
  int? get affectedRowCount => _result.affectedRowCount;

  @override
  List<DbColumnDescription> get columnDescriptions => _result.columnDescriptions
      .map((desc) => PgDbColumnDescription(desc))
      .toList();
}

class PgDbColumnDescription extends DbColumnDescription {
  final ColumnDescription desc;
  PgDbColumnDescription(this.desc);

  /// The name of the column returned by the query.
  @override
  String get columnName => desc.columnName;

  /// The resolved name of the referenced table.
  @override
  String get tableName => desc.tableName;
}
