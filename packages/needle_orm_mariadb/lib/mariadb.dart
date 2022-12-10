import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';

class MariaDbDatabase extends Database {
  late Logger logger;

  final MySqlConnection _connection;
  // final dynamic
  // _connection; // connection can be of type MySqlConnection / TransactionContext

  MariaDbDatabase(this._connection, {Logger? logger})
      : super(DatabaseType.MariaDB, '10.0') {
    this.logger = logger ?? Logger('MariaDbDatabase');
  }

  @override
  Future<void> close() {
    return _connection.close();
  }

  @override
  Future<DbQueryResult> query(
      String sql, Map<String, dynamic> substitutionValues,
      {List<String> returningFields = const [],
      String? tableName,
      Map<String, QueryHint> hints = const {}}) async {
    var params = _sortedValues(sql, substitutionValues, hints);

    for (var name in substitutionValues.keys) {
      if (substitutionValues[name] is List &&
          substitutionValues[name] is! Uint8List) {
        // expand List, for example : id IN @idList => id IN (?,?,?)
        var list = substitutionValues[name] as List;
        var q = List.filled(list.length, '?', growable: false).join(',');
        sql = sql.replaceAll('@$name', '($q)');
      } else {
        sql = sql.replaceAll('@$name', '?');
      }
    }

    var params2 = <Object?>[];
    for (var p in params) {
      if (p.value is List) {
        if (QueryHint.lob == p.hint) {
          params2.add(Blob.fromBytes(p.value));
        } else {
          // expand params for List
          params2.addAll([...p.value]);
        }
      } else {
        params2.add(p.value);
      }
    }

    if (returningFields.isNotEmpty) {
      sql += ' RETURNING ${returningFields.join(',')}';
    }

    logger.config('query: $sql ; params: $params2');
    try {
      var results = await _connection.query(sql, params2);
      logger.config('query return');
      return MariaDbQueryResult(results);
    } catch (e, s) {
      logger.severe('query error', e, s);
      rethrow;
    } finally {
      logger.config('query end!');
    }
    // return results.map((r) => r.toList()).toList();
  }

  static List<_PositionValue> _sortedValues(String query,
      Map<String, dynamic> substitutionValues, Map<String, QueryHint> hints) {
    List<_PositionValue> positions = [];
    for (var name in substitutionValues.keys) {
      for (var start = 0;
          start < query.length &&
              (start = query.indexOf('@$name', start)) != -1;
          start++) {
        positions.add(
            _PositionValue(name, start, substitutionValues[name], hints[name]));
      }
    }
    positions.sort((a, b) => a.position.compareTo(b.position));
    return positions;
  }

  @override
/*   Future<T> transaction<T>(FutureOr<T> Function(Database) f) async {
    T? returnValue = await _connection.transaction((ctx) async {
      try {
        logger.config('Entering transaction');
        var tx = MariaDbDatabase(ctx, logger: logger);
        return await f(tx);
      } catch (e, s) {
        logger.severe('Failed to run transaction', e, s);
        rethrow;
      } finally {
        logger.config('Exiting transaction');
      }
    });

    return returnValue!;
  }
 */
  Future<T> transaction<T>(FutureOr<T> Function(Database) f) async {
    await _connection.query('start transaction');
    T result;
    try {
      result = await f(this);
      await _connection.query('commit');
    } catch (e, s) {
      logger.severe('transaction error', e, s);
      await _connection.query('rollback');
      rethrow;
    } finally {
      logger.info('transaction end');
    }
    return result;
  }
}

class _PositionValue {
  final String name;
  final int position;
  final dynamic value;
  final QueryHint? hint;
  _PositionValue(this.name, this.position, this.value, this.hint);
}

class MariaDbQueryResult extends DbQueryResult with ListMixin<List> {
  final Results _result;
  final List<ResultRow> rows;

  MariaDbQueryResult(this._result) : rows = _result.toList() {
    for (var row in rows) {
      var values = row.values;
      if (values != null) {
        for (int i = 0; i < values.length; i++) {
          if (values[i] is Blob) {
            // @see: /include/mysql_com.h
            if ((_result.fields[i].flags! & 0x80) != 0) {
              values[i] = (values[i] as Blob).toBytes();
            } else {
              values[i] = String.fromCharCodes((values[i] as Blob).toBytes());
            }
          }
        }
      }
    }
  }

  @override
  int get length => _result.length;
  @override
  set length(int value) {
    throw UnimplementedError();
  }

  @override
  List operator [](int index) {
    return rows[index];
  }

  @override
  void operator []=(int index, List value) {
    throw UnimplementedError();
  }

  @override
  int? get affectedRowCount => _result.affectedRows;

  @override
  List<DbColumnDescription> get columnDescriptions =>
      _result.fields.map((desc) => MariaDbColumnDescription(desc)).toList();
}

class MariaDbColumnDescription extends DbColumnDescription {
  final Field desc;
  MariaDbColumnDescription(this.desc);

  /// The name of the column returned by the query.
  @override
  String get columnName => desc.name ?? '';

  /// The resolved name of the referenced table.
  @override
  String get tableName => desc.table ?? '';
}
