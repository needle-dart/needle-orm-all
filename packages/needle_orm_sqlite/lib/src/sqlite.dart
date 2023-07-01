import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:logging/logging.dart';
import 'package:needle_orm/api.dart';

class SqliteDatabase extends Database {
  late Logger logger;

  late sqlite.Database _connection;

  SqliteDatabase([String? db, Logger? logger])
      : super(DbType(DbCategory.Sqlite, '3.0')) {
    this.logger = logger ?? Logger('SqliteDatabase');
    if (db != null) {
      _connection = sqlite.sqlite3.open(db);
    } else {
      _connection = sqlite.sqlite3.openInMemory();
    }
  }

  @override
  Future<void> close() async {
    return _connection.dispose();
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
        // expand params for List
        params2.addAll([...p.value]);
      } else {
        params2.add(p.value);
      }
    }

    if (returningFields.isNotEmpty) {
      sql += ' RETURNING ${returningFields.join(',')}';
    }

    // logger.config('query: $sql ; params: $params2');
    try {
      final stmt = _connection.prepare(sql);
      var start = sql.trim().toLowerCase();
      if (start.startsWith("select ")) {
        sqlite.ResultSet resultSet = stmt.select(params2);
        return SqliteQueryResult(rs: resultSet);
      } else if (start.startsWith('insert ')) {
        stmt.execute(params2);
        // return last insert id
        sqlite.ResultSet resultSet = _connection
            .select("select last_insert_rowid() from $tableName LIMIT 1;");
        return SqliteQueryResult(rs: resultSet);
      } else if (start.startsWith('update ') && returningFields.isNotEmpty) {
        sqlite.ResultSet rs1 = stmt.select(params2);
        sqlite.ResultSet rs2 = _connection.select("select changes();");
        return SqliteQueryResult(
            rs: rs1, affectedRowCount: rs2.first[0] as int);
      } else if (start.startsWith('update ') || start.startsWith('delete ')) {
        //
        stmt.execute(params2);
        sqlite.ResultSet resultSet = _connection.select("select changes();");
        return SqliteQueryResult(affectedRowCount: resultSet.first[0] as int);
      } else {
        stmt.execute(params2);
      }
    } catch (e, s) {
      // logger.severe('query error', e, s);
      rethrow;
    } finally {
      // logger.config('query end!');
    }
    return SqliteQueryResult();
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
  Future<T> transaction<T>(FutureOr<T> Function(Database) f) async {
    return f(this);
  }
}

class _PositionValue {
  final String name;
  final int position;
  final dynamic value;
  final QueryHint? hint;
  _PositionValue(this.name, this.position, this.value, this.hint);
}

class SqliteQueryResult extends DbQueryResult with ListMixin<List> {
  final sqlite.ResultSet? rs;
  final List<_Row>? _rows;

  @override
  final int affectedRowCount;

  SqliteQueryResult({this.rs, this.affectedRowCount = 0})
      : _rows = rs?.map((e) => _Row(e)).toList();

  @override
  int get length => rs?.length ?? 0;
  @override
  set length(int value) {}

  @override
  List<Object?> operator [](int index) {
    return _rows![index];
  }

  @override
  void operator []=(int index, List value) {}

  @override
  List<DbColumnDescription> get columnDescriptions => [];
}

class _Row with ListMixin<Object?> {
  final sqlite.Row row;

  _Row(this.row);

  @override
  int get length => row.length;

  @override
  set length(int newLength) {}

  @override
  Object? operator [](int index) => row.columnAt(index);

  @override
  void operator []=(int index, Object? value) {}
}
