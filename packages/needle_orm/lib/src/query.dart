// ignore_for_file: constant_identifier_names
import 'dart:collection';

import 'package:logging/logging.dart';

import 'api.dart';
import 'sql_adapter.dart';
import 'sql_generator.dart';
import 'meta.dart';
import 'inspector.dart';
import 'sql.dart';

final Logger _logger = Logger('ORM');

class QueryCondition {
  final ColumnConditionOper oper;

  final ColumnQuery? column;

  final dynamic value;

  QueryCondition(this.column, this.oper, this.value);

  @override
  String toString() {
    var p = _path;
    return [
      if (p.isNotEmpty) ...[p, '.'],
      column?._name ?? '',
      ' ',
      oper,
      ' {',
      value ?? '',
      '}',
    ].join('');
  }

  String toSql(
      JoinTranslator joinTranslator, PreparedConditions preparedConditions) {
    var jp = JoinPath(_path);
    var p = joinTranslator._search(jp);
    switch (oper) {
      case ColumnConditionOper.BETWEEN || ColumnConditionOper.NOT_BETWEEN:
        return '${p.alias}.${column!._name} ${oper.text} ${preparedConditions.add(value[0])} and ${preparedConditions.add(value[1])} ';
      case ColumnConditionOper.IS_NULL || ColumnConditionOper.IS_NOT_NULL:
        return '${p.alias}.${column!._name} ${oper.text} ';
      default:
        return '${p.alias}.${column!._name} ${oper.text} ${preparedConditions.add(value)} ';
    }
  }

  List<TableQuery> get _path => column == null ? [] : column!._path;
}

class PreparedConditions {
  final Map<String, dynamic> values = {};

  String add(dynamic value) {
    var key = '_v${values.length}';
    values[key] = value;
    return '@$key';
  }
}

class CompoundQueryCondition extends QueryCondition {
  CompoundQueryCondition(super.column, super.oper, super.value);

  @override
  String toSql(
      JoinTranslator joinTranslator, PreparedConditions preparedConditions) {
    List<QueryCondition> queryConditions = value as List<QueryCondition>;
    switch (oper) {
      case ColumnConditionOper.AND:
        var str = queryConditions
            .map((q) => q.toSql(joinTranslator, preparedConditions))
            .join(' and ');
        return "( $str )";
      case ColumnConditionOper.OR:
        var str = queryConditions
            .map((q) => q.toSql(joinTranslator, preparedConditions))
            .join(' or ');
        return "( $str )";
      case ColumnConditionOper.NOT:
        var str = queryConditions[0].toSql(joinTranslator, preparedConditions);
        return " not ( $str )";
      default:
        return '';
    }
  }
}

Iterable<List<TableQuery>> _getPath(QueryCondition value) sync* {
  if (value is CompoundQueryCondition) {
    for (var v in (value.value as List<QueryCondition>)) {
      for (List<TableQuery> sub in _getPath(v)) {
        yield sub;
      }
    }
  } else {
    yield value._path;
  }
}

enum JoinKind { oneToOne, oneToMany, manyToOne, manyToMany }

final class JoinRelation {
  final JoinKind kind;
  final String mappedBy;

  JoinRelation([this.kind = JoinKind.manyToOne, this.mappedBy = ""]);

  String get mappedByColumnName => genColumnName(mappedBy);
}

class TableQuery<T> extends ColumnQuery<T> {
  @override
  final List<TableQuery> _path;

  late JoinRelation joinRelation;

  TableQuery(super.parentTableQuery, super.columnName)
      : _path = parentTableQuery == null
            ? []
            : [...parentTableQuery._path, parentTableQuery];

  String get className => '$T';

  @override
  String toString() {
    return '${super._name}:$className';
  }
}

class TopTableQueryHelper<T> {
  late final String className;
  late final String tableName;
  late final OrmMetaClass clz;

  int offset = 0;
  int maxRows = 0;

  List<QueryCondition> conditions = [];

  TopTableQueryHelper() {
    className = '$T';
    clz = ModelInspector.meta('$T')!;
    tableName = clz.tableName;
  }

  void paging(int pageNumber, int pageSize) {
    maxRows = pageSize;
    offset = pageNumber * pageSize;
  }

  void addCondition(QueryCondition queryCondition) {
    conditions.add(queryCondition);
  }

  void addAllCondition(Iterable<QueryCondition> queryConditions) {
    conditions.addAll(queryConditions);
  }

  void debugQuery(DbType dbType, {bool includeSoftDeleted = false}) {
    _logger.info(conditions);

    _logger.info('------------ origin (sorted) \n');
    JoinTranslator joinTranslator =
        JoinTranslator.of(this, includeSoftDeleted: includeSoftDeleted);
    joinTranslator.debug();

    _logger.info('------------ _insert Mid Path\n');
    joinTranslator._insertMidPath();
    joinTranslator.debug();

    _logger.info('------------ assign alias\n');
    joinTranslator._assignTableAlias();
    joinTranslator.debug();

    _logger.info('------------ join sql \n');
    String joins = joinTranslator._joinSql(dbType).join(' ');

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var strAllFields = allFields.map((f) => "t0.${f.columnName}").join(',');

    String sql = 'select $strAllFields $joins';

    _logger.info(sql);

    var preparedQuery =
        PreparedQuery.forSelect(sql, joinTranslator, conditions);

    {
      _logger.info('------------ with where sql[prepared style] \n');
      _logger.info('sql: ${preparedQuery.sql}');
      _logger.info('preparedConditions: ${preparedQuery.conditions}');
    }
  }

  PreparedQuery toPreparedQuery(DbType dbType,
      {bool includeSoftDeleted = false}) {
    JoinTranslator joinTranslator =
        JoinTranslator.of(this, includeSoftDeleted: includeSoftDeleted);
    joinTranslator._insertMidPath();
    joinTranslator._assignTableAlias();
    String joins = joinTranslator._joinSql(dbType).join(' ');

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var strAllFields = allFields.map((f) => "t0.${f.columnName}").join(',');

    String sql = 'select distinct $strAllFields $joins';

    return PreparedQuery.forSelect(sql, joinTranslator, conditions,
        offset: offset, maxRows: maxRows);
  }

  PreparedQuery toCountPreparedQuery(DbType dbType,
      {bool includeSoftDeleted = false}) {
    JoinTranslator joinTranslator =
        JoinTranslator.of(this, includeSoftDeleted: includeSoftDeleted);
    joinTranslator._insertMidPath();
    joinTranslator._assignTableAlias();
    String joins = joinTranslator._joinSql(dbType).join(' ');

    String sql = 'select count(t0.${clz.idFields.first.columnName}) $joins';

    return PreparedQuery.forSelect(sql, joinTranslator, conditions);
  }

  PreparedQuery toSoftDeletePreparedQuery(DbType dbType) {
    JoinTranslator joinTranslator =
        JoinTranslator.of(this, includeSoftDeleted: false);
    joinTranslator._insertMidPath();
    joinTranslator._assignTableAlias();
    if (joinTranslator.paths.isNotEmpty) {
      joinTranslator.paths[0].alias = tableName;
    }
    String joins = joinTranslator._joinSqlForUpdate(dbType).join(' ');
    String sql =
        'update $tableName set ${clz.softDeleteField!.columnName} = true ';

    if (clz.versionField != null) {
      var versionColumn = clz.versionField!.columnName;
      sql += ', $versionColumn = $versionColumn+1 ';
    }

    var strNow = serverNowExpr(dbType);
    if (clz.whenModifiedField != null) {
      var whenModifiedColumn = clz.whenModifiedField!.columnName;
      sql += ", $whenModifiedColumn = $strNow ";
    }

    sql += joins;

    return PreparedQuery.forUpdate(sql, joinTranslator, conditions);
  }
}

class PreparedQuery {
  final String sql;
  final PreparedConditions conditions;

  PreparedQuery(this.sql, this.conditions);

  factory PreparedQuery.forSelect(String sqlPrefix,
      JoinTranslator joinTranslator, List<QueryCondition> conditions,
      {int offset = 0, int maxRows = 0}) {
    if (conditions.isEmpty) {
      if (maxRows > 0) {
        sqlPrefix += ' limit $maxRows';
      }

      if (offset > 0) {
        sqlPrefix += ' offset $offset';
      }
      return PreparedQuery(sqlPrefix, PreparedConditions());
    }
    var where = <String>[];
    PreparedConditions preparedConditions = PreparedConditions();
    if (!joinTranslator.includeSoftDeleted) {
      var clz = joinTranslator.helper.clz;
      var softDeleteField = clz.softDeleteField;
      if (softDeleteField != null) {
        where.add('t0.${softDeleteField.columnName} is false');
      }
    }
    for (var cond in conditions) {
      where.add(cond.toSql(joinTranslator, preparedConditions));
    }
    sqlPrefix += '\n where ${where.join(' AND ')}';

    if (maxRows > 0) {
      sqlPrefix += ' limit $maxRows';
    }

    if (offset > 0) {
      sqlPrefix += ' offset $offset';
    }

    return PreparedQuery(sqlPrefix, preparedConditions);
  }

  factory PreparedQuery.forUpdate(String sqlPrefix,
      JoinTranslator joinTranslator, List<QueryCondition> conditions) {
    var where = <String>[];
    PreparedConditions preparedConditions = PreparedConditions();
    if (!joinTranslator.includeSoftDeleted) {
      if (joinTranslator.helper.clz.softDeleteField != null) {
        var softDeleteField = joinTranslator.helper.clz.softDeleteField!;
        where.add(
            '${joinTranslator.helper.tableName}.${softDeleteField.columnName} is false');
      }
      // add where for first join
      var firstJoin =
          joinTranslator.paths.where((p) => p.length > 1).firstOrNull;
      if (firstJoin != null) {
        var clzName = firstJoin._lastClassName();
        var clz = ModelInspector.meta(clzName)!;
        var softDeleteField = clz.softDeleteField;
        if (softDeleteField != null) {
          where
              .add('${firstJoin.alias}.${softDeleteField.columnName} is false');
        }
      }
    }
    for (var cond in conditions) {
      where.add(cond.toSql(joinTranslator, preparedConditions));
    }
    sqlPrefix += '\n where ${where.join(' AND ')}';
    return PreparedQuery(sqlPrefix, preparedConditions);
  }
}

class TopTableQuery<T extends Model> extends TableQuery<T> {
  final TopTableQueryHelper<T> _helper = TopTableQueryHelper<T>();
  final Database? _db;

  List<OrderField> orders = [];

  TopTableQuery({Database? db})
      : _db = db ?? Database.defaultDb,
        super(null, "");

  QueryCondition and(List<QueryCondition> queryConditions) =>
      CompoundQueryCondition(null, ColumnConditionOper.AND, queryConditions);

  QueryCondition or(List<QueryCondition> queryConditions) =>
      CompoundQueryCondition(null, ColumnConditionOper.OR, queryConditions);

  QueryCondition not(QueryCondition queryCondition) =>
      CompoundQueryCondition(null, ColumnConditionOper.NOT, [queryCondition]);

  TopTableQuery<T> where(Iterable<QueryCondition> conditions) {
    _helper.addAllCondition(conditions);
    return this;
  }

  void debugQuery() {
    _helper.debugQuery(DbType(DbCategory.PostgreSQL, "10.0"));
  }

  void paging(int pageNumber, int pageSize) {
    _helper.paging(pageNumber, pageSize);
  }

  void noPaging() {
    _helper.paging(0, 0);
  }

  @override
  QueryCondition eq(T value) {
    throw 'should not call eq() directly on TopTableQuery($runtimeType)';
  }

  // operate for query.

  /// find list
  Future<List<T>> findList({bool includeSoftDeleted = false}) async {
    var preparedQuery = _helper.toPreparedQuery(_db!.dbType,
        includeSoftDeleted: includeSoftDeleted);

    var rows = await _db!.query(
        preparedQuery.sql, preparedQuery.conditions.values,
        tableName: _helper.tableName);
    _logger.info('result: $rows');

    var clz = ModelInspector.meta('$T')!;
    var fields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var result = rows.map((row) {
      return toModel(row, fields);
    });

    return result.toList();
  }

  T toModel(List<dynamic> dbRow, List<OrmMetaField> selectedFields,
      {T? existModel}) {
    T? model = existModel;
    var className = '$T';
    var modelInspector = ModelInspector.lookup(className);
    if (model == null) {
      var idField = ModelInspector.idFields(className)?.first;
      if (idField != null) {
        int j = selectedFields.indexOf(idField);
        if (j >= 0) {
          model =
              ModelInspector.newModel(className, attachDb: true, id: dbRow[j])
                  as T;
        }
      } else {
        model = ModelInspector.newModel(className, attachDb: true) as T;
      }
    }

    for (int i = 0; i < dbRow.length; i++) {
      var f = selectedFields[i];
      var name = f.name;
      var value = dbRow[i];
      if (f.isModelType) {
        if (value != null) {
          var obj =
              ModelInspector.newModel(f.elementType, id: value, attachDb: true);
          modelInspector.setFieldValue(model!, name, obj);
        }
      } else {
        modelInspector.setFieldValue(
            model!, name, convertValue(value, f, _db!.dbType));
      }
    }
    modelInspector.markLoaded(model!);
    return model;
  }

  /// find first
  Future<T?> findFirst({bool includeSoftDeleted = false}) async {
    paging(0, 1);
    return await findUnique(includeSoftDeleted: includeSoftDeleted);
  }

  /// find unique
  Future<T?> findUnique({bool includeSoftDeleted = false}) async {
    var list = await findList(includeSoftDeleted: includeSoftDeleted);
    if (list.isEmpty) {
      return null;
    }
    if (list.length == 1) {
      return list.first;
    }
    throw 'findUnique error[actually returned lenght is : ${list.length}]';
  }

  /// return count of this query.
  Future<int> count({bool includeSoftDeleted = false}) async {
    var preparedQuery = _helper.toCountPreparedQuery(_db!.dbType,
        includeSoftDeleted: includeSoftDeleted);
    var rows = await _db!.query(
        preparedQuery.sql, preparedQuery.conditions.values,
        tableName: _helper.tableName);

    _logger.info(rows);
    return (rows[0][0]).toInt();
  }

  /// select with raw sql.
  /// example: findListBySql(' , another_table t1 where t.column_name=t1.id and t.column_name2=@param1 and t1.column_name3=@param2 order by t0.id limit 10 offset 10 ', {'param1':100,'param2':'hello'})
  Future<List<T>> findListBySql(String rawSql,
      [Map<String, dynamic> params = const {}]) async {
    var clz = _helper.clz;
    var tableName = _helper.tableName;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var strAllFields = allFields.map((f) => "t0.${f.columnName}").join(',');
    var rows = await _db!.query(
        'select distinct $strAllFields from $tableName t0 $rawSql', params);

    _logger.info('result: $rows');

    var result = rows.map((row) {
      return toModel(row, allFields);
    });

    return result.toList();
  }

  Future<int> deleteAll() async {
    if (_helper.clz.softDeleteField == null) {
      throw 'deleteAll() only support soft delete model for safety.';
    }
    var preparedQuery = _helper.toSoftDeletePreparedQuery(_db!.dbType);

    var rows = await _db!.query(
        preparedQuery.sql, preparedQuery.conditions.values,
        tableName: _helper.tableName);
    return rows.affectedRowCount ?? 0;
  }
}

/*
// step1:Query
  
  var q = UserQuery();
  q.where([
      q.age.gt(18),
      q.books.lastUpdatedBy.name.endsWith('_user'),
    ]);

// step2:QueryCondition
  
  [
      [:User].age > {18},
      [:User, books:Book, lastUpdatedBy:User].name like {%_user}
  ]

// step3:find all Paths

  [:User]
  [:User, books:Book, lastUpdatedBy:User]

// step4:Path[] with middle paths

  [:User]
  [:User, books:Book]
  [:User, books:Book, lastUpdatedBy:User]

// step5:Path[] assign alias table name

  [:User] -> t0
  [:User, books:Book] -> t1
  [:User, books:Book, lastUpdatedBy:User] -> t1

// step6:generate join statements

   select distinct(t0.*)
   from user t0
   left join book t1 on t1.author_id = t0.id
   left join user t2 on t2.id = t1.last_updated_by_id

// step7:generate where statement

   select distinct(t0.*)
   from user t0
   left join book t1 on t1.author_id = t0.id
   left join user t2 on t2.id = t1.last_updated_by_id
   where
    t0.age > 18  
    and t2.name like '%[_]user'
 */

class JoinTranslator {
  final TopTableQueryHelper helper;
  final List<JoinPath> paths;
  final bool includeSoftDeleted;
  JoinTranslator(this.helper, this.paths, {this.includeSoftDeleted = false});

  factory JoinTranslator.of(TopTableQueryHelper helper,
      {bool includeSoftDeleted = false}) {
    var all = <JoinPath>[];
    var set = <String>{}; // remove duplicated list;
    for (var cond in helper.conditions) {
      _getPath(cond).forEach((element) {
        var jp = JoinPath(element);
        if (set.add(jp.text)) {
          all.add(jp);
        }
      });
    }
    all.sort((a, b) => a.text.compareTo(b.text));
    return JoinTranslator(helper, all, includeSoftDeleted: includeSoftDeleted);
  }

  void _insertMidPath() {
    //whether first path is the root path
    if (paths.isEmpty) {
      return;
    }
    if (paths[0].length != 1) {
      paths.insert(0, JoinPath([paths[0].path[0]]));
    }
    if (paths.length < 2) {
      return;
    }
    for (int i = 1; i < paths.length; i++) {
      List<JoinPath> midPathList = _findMidPath(paths[i - 1], paths[i]);
      if (midPathList.isNotEmpty) {
        for (int j = 0; j < midPathList.length; j++) {
          paths.insert(i, midPathList[j]);
        }
        i += midPathList.length;
      }
    }
  }

  List<JoinPath> _findMidPath(JoinPath pathStart, JoinPath pathEnd) {
    var result = <JoinPath>[];
    for (int i = 0; i < pathEnd.length; i++) {
      if (i >= pathStart.length ||
          pathStart[i].toString() != pathEnd[i].toString()) {
        for (int k = i; k < pathEnd.length - 1; k++) {
          result.add(JoinPath(pathEnd.sublist(0, k + 1)));
        }
        break;
      }
    }
    return result;
  }

  bool _exist(JoinPath path) {
    return paths.any((element) => path.text == element.text);
  }

  void _assignTableAlias() {
    for (int i = 0; i < paths.length; i++) {
      paths[i].alias = 't$i';
    }
  }

  JoinPath _searchLeftJoin(JoinPath path) {
    if (path.length < 2) throw 'no join needed!';
    var index = paths.indexWhere((element) =>
        element.text == JoinPath(path.path.sublist(0, path.length - 1)).text);
    return paths[index];
  }

  JoinPath _search(JoinPath path) {
    var index = paths.indexWhere((element) => element.text == path.text);
    return paths[index];
  }

  List<String> _joinSql(dbType) {
    var result = <String>[];
    for (var path in paths) {
      if (path.length == 1) {
        result.add('from ${path._lastTableName()} ${path.alias}');
      } else {
        var p = _searchLeftJoin(path);
        // join = '${p.text} :: ${p.alias}';
        var joinColumns = path._findJoinColumns();
        var type = path.last.className;
        var clz = ModelInspector.meta(type)!;
        var softDeleteField = clz.softDeleteField;
        if (softDeleteField != null && !includeSoftDeleted) {
          result.add(
              'left join ${path._lastTableName()} ${path.alias} on ${path.alias}.${joinColumns[0]} = ${p.alias}.${joinColumns[1]} and ${path.alias}.${softDeleteField.columnName} is false');
        } else {
          result.add(
              'left join ${path._lastTableName()} ${path.alias} on ${path.alias}.${joinColumns[0]} = ${p.alias}.${joinColumns[1]} ');
        }
      }
      //_logger.info('${path.text} :: ${path.alias} ---> $join');
    }

    if (result.isEmpty) {
      result = [
        ' from ${helper.tableName} t0',
        if (helper.clz.softDeleteField != null)
          ' where t0.${helper.clz.softDeleteField!.columnName} is false'
      ];
    }

    return result;
  }

  List<String> _joinSqlForUpdate(DbType dbType) {
    var result = <String>[];
    for (var path in paths) {
      if (path.length == 1) {
        // ignore
      } else {
        var p = _searchLeftJoin(path);
        if (result.isEmpty) {
          result.add(' from ${path._lastTableName()} ${path.alias}');
          continue;
        }
        // join = '${p.text} :: ${p.alias}';
        var joinColumns = path._findJoinColumns();
        var type = path.last.className;
        var clz = ModelInspector.meta(type)!;
        var softDeleteField = clz.softDeleteField;
        if (softDeleteField != null && !includeSoftDeleted) {
          result.add(
              'left join ${path._lastTableName()} ${path.alias} on ${path.alias}.${joinColumns[0]} = ${p.alias}.${joinColumns[1]} and ${path.alias}.${softDeleteField.columnName} is false');
        } else {
          result.add(
              'left join ${path._lastTableName()} ${path.alias} on ${path.alias}.${joinColumns[0]} = ${p.alias}.${joinColumns[1]} ');
        }
      }
      //_logger.info('${path.text} :: ${path.alias} ---> $join');
    }

    return result;
  }

  void debug() {
    for (var element in paths) {
      _logger.info(element);
    }
  }
}

class JoinPath with ListMixin<TableQuery> {
  final List<TableQuery> path;
  final String text;
  String alias = '';

  JoinPath(this.path) : text = _toText(path);

  static String _toText(List<TableQuery> path) {
    return path.map((e) => e.toString()).join('/');
  }

  String _lastClassName() {
    return path.last.className;
  }

  String _lastTableName() {
    return ModelInspector.meta(path.last.className)!.tableName;
  }

  List<String> _findJoinColumns() {
    var joinRelation = path.last.joinRelation;
    var joinKind = joinRelation.kind;
    if (joinKind == JoinKind.manyToOne) {
      return ['id', "${path.last._columnName}_id"];
    } else if (joinKind == JoinKind.oneToMany) {
      // find mappedBy
      var mappedByColumnName = joinRelation.mappedByColumnName;
      return ["${mappedByColumnName}_id", 'id'];
    }
    return ['id', "${path.last._name}_id"];
  }

  @override
  String toString() {
    return '$text :: $alias';
  }

  @override
  int get length => path.length;
  @override
  set length(int length) => path.length = length;

  @override
  TableQuery operator [](int index) => path[index];

  @override
  void operator []=(int index, TableQuery value) {
    path[index] = value;
  }
}

/// ColumnQuery defines operations for column
class ColumnQuery<T> {
  final String _name;
  final TableQuery? _tableQuery;

  ColumnQuery(TableQuery? parentTableQuery, String fieldName)
      : _tableQuery = parentTableQuery,
        _name = fieldName;

  List<TableQuery> get _path =>
      _tableQuery == null ? [] : [..._tableQuery!._path, _tableQuery!];

  String get _columnName =>
      ModelInspector.meta(_tableQuery!.className)!.findField(_name)!.columnName;

  static String classNameForType(String type) {
    switch (type) {
      case 'int':
        return 'IntColumn';
      case 'double':
        return 'DoubleColumn';
      case 'bool':
        return 'BoolColumn';
      case 'DateTime':
        return 'DateTimeColumn';
      case 'String':
        return 'StringColumn';
      default:
        return 'ColumnQuery';
    }
  }

  QueryCondition eq(T value) =>
      QueryCondition(this, ColumnConditionOper.EQ, value);

  OrderField asc() => OrderField(this, Order.asc);

  OrderField desc() => OrderField(this, Order.desc);
}

/// Order
enum Order { asc, desc }

/// fields used in Order
class OrderField {
  ColumnQuery column;
  Order order;
  OrderField(this.column, this.order);

  @override
  String toString() {
    return column._name + (order == Order.desc ? ' desc' : '');
  }
}

/// server side expression
class ServerSideExpr {
  final String expr;
  ServerSideExpr(this.expr);
}

/// support IN , notIn for columns
mixin RangeCondition<T> on ColumnQuery<T> {
  // ignore: non_constant_identifier_names
  QueryCondition IN(List<T> value) =>
      QueryCondition(this, ColumnConditionOper.IN, value);

  QueryCondition notIn(List<T> value) =>
      QueryCondition(this, ColumnConditionOper.NOT_IN, value);
}

/// support isNull, isNotNull for columns
mixin NullCondition<T> on ColumnQuery<T> {
  QueryCondition isNull() =>
      QueryCondition(this, ColumnConditionOper.IS_NULL, null);

  QueryCondition isNotNull() =>
      QueryCondition(this, ColumnConditionOper.IS_NOT_NULL, null);
}

/// support > < = >= <= between for columns
mixin ComparableCondition<T> on ColumnQuery<T> {
  QueryCondition gt(T value) =>
      QueryCondition(this, ColumnConditionOper.GT, value);

  QueryCondition ge(T value) =>
      QueryCondition(this, ColumnConditionOper.GE, value);

  QueryCondition lt(T value) =>
      QueryCondition(this, ColumnConditionOper.LT, value);

  QueryCondition le(T value) =>
      QueryCondition(this, ColumnConditionOper.LE, value);

  QueryCondition between(T beginValue, T endValue) =>
      QueryCondition(this, ColumnConditionOper.BETWEEN, [beginValue, endValue]);

  QueryCondition notBetween(T beginValue, T endValue) => QueryCondition(
      this, ColumnConditionOper.NOT_BETWEEN, [beginValue, endValue]);
}

mixin ListCondition<T> on ColumnQuery<T> {
  QueryCondition isEmpty() =>
      QueryCondition(this, ColumnConditionOper.NOT_EXISTS, null);
  QueryCondition isNotEmpty() =>
      QueryCondition(this, ColumnConditionOper.EXISTS, null);
}

/// ColumnCondition
class ColumnCondition {
  final String name;
  final ColumnConditionOper oper;
  final dynamic value;

  ColumnCondition(this.name, this.oper, this.value);

  @override
  String toString() => '($name : ${oper.name} : $value)';
}

/// number column
class NumberColumn<T> extends ColumnQuery<T>
    with ComparableCondition<T>, RangeCondition<T> {
  NumberColumn(super.owner, super.name);
}

/// int column
class IntColumn extends NumberColumn<int> {
  IntColumn(super.owner, super.name);
}

/// double column
class DoubleColumn extends NumberColumn<double> {
  DoubleColumn(super.owner, super.name);
}

/// string column
class StringColumn extends ColumnQuery<String>
    with
        ComparableCondition<String>,
        RangeCondition<String>,
        NullCondition<String> {
  StringColumn(super.owner, super.name);

  QueryCondition like(String pattern) =>
      QueryCondition(this, ColumnConditionOper.LIKE, pattern);

  QueryCondition startsWith(String prefix) =>
      QueryCondition(this, ColumnConditionOper.LIKE, '$prefix%');

  QueryCondition endsWith(String prefix) =>
      QueryCondition(this, ColumnConditionOper.LIKE, '%$prefix');

  QueryCondition contains(String subString) =>
      QueryCondition(this, ColumnConditionOper.LIKE, '%$subString%');
}

/// bool column
class BoolColumn extends ColumnQuery<bool> {
  BoolColumn(super.owner, super.name);

  QueryCondition isTrue() => QueryCondition(this, ColumnConditionOper.EQ, true);

  QueryCondition isFalse() =>
      QueryCondition(this, ColumnConditionOper.EQ, false);
}

/// DateTime column
class DateTimeColumn extends ColumnQuery<DateTime>
    with ComparableCondition<DateTime>, NullCondition<DateTime> {
  DateTimeColumn(super.owner, super.name);
}

enum ColumnConditionOper {
  EQ('='),
  GT('>'),
  LT('<'),
  GE('>='),
  LE('<='),
  BETWEEN('between'),
  NOT_BETWEEN('not between'),
  LIKE('like'),
  IN('in'),
  NOT_IN('not in'),
  IS_NULL('is null'),
  IS_NOT_NULL('is not null'),
  EXISTS('exists'),
  NOT_EXISTS('not exists'),
  NOT('not'),
  AND('and'),
  OR('or');

  final String text;

  const ColumnConditionOper(this.text);

  @override
  String toString() {
    return text;
  }
}
