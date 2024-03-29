import 'dart:async';
import 'package:logging/logging.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:needle_orm/api.dart';

import 'postgres.dart';

/// A [QueryExecutor] that uses `package:postgres_pool` for connetions pooling.
class PostgreSqlPoolDatabase extends Database {
  final PgPool _pool;

  /// An optional [Logger] to print information to.
  late Logger logger;

  PostgreSqlPoolDatabase(this._pool, {Logger? logger})
      : super(DbType(DbCategory.PostgreSQL, '10.0')) {
    this.logger = logger ?? Logger('PostgreSqlPoolDatabase');
  }

  /// The underlying connection pooling.
  PgPool get pool => _pool;

  /// Closes all the connections in the pool.
  @override
  Future<void> close() async {
    await _pool.close();
  }

  /// Run query.
  @override
  Future<DbQueryResult> query(
      String sql, Map<String, dynamic> substitutionValues,
      {List<String> returningFields = const [],
      String? tableName,
      Map<String, QueryHint> hints = const {}}) async {
    if (returningFields.isNotEmpty) {
      var fields = returningFields.join(', ');
      var returning = 'RETURNING $fields';
      sql = '$sql $returning';
    }

    // logger.config('query2: $sql ; params: $substitutionValues');

    // expand List first
    var param = <String, dynamic>{};
    substitutionValues.forEach((key, value) {
      if (QueryHint.lob == hints[key]) {
        sql = sql.replaceAll('@$key', '@$key:bytea ');
        param[key] = value;
      } else if (value is List) {
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

    // logger.config('final query: $sql ; params: $param');
    PostgreSQLResult rs = await _pool.run<PostgreSQLResult>((pgContext) {
      return pgContext.query(sql, substitutionValues: param);
    });
    return PgQueryResult(rs);
  }

  /// Run query in a transaction.
  @override
  Future<T> transaction<T>(FutureOr<T> Function(Database) f) async {
    return _pool.runTx((pgContext) async {
      var exec = PostgreSqlDatabase(pgContext, logger: logger);
      return await f(exec);
    });
  }
}
