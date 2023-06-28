// ignore_for_file: constant_identifier_names
import 'dart:collection';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:recase/recase.dart';

import 'api.dart';
import 'generator.dart';
import 'meta.dart';
import 'inspector.dart';
import 'sql.dart';
import 'sql_query.dart';

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
    return '${p.alias}.${column!._name} ${oper.text} ${preparedConditions.add(value)} ';
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

enum JoinKind {
  oneToOne,
  oneToMany,
  manyToOne,
  manyToMany
}

final class JoinRelation {
  final JoinKind kind;
  final String mappedBy;

  JoinRelation([this.kind=JoinKind.manyToOne, this.mappedBy=""]);

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

  String get _innerType => '$T';

  @override
  String toString() {
    return '${super._name}:$_innerType';
  }
}

/* 
  SqlJoin _toSqlJoin() {
    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;
    var columnName = getColumnName(propName!);
    var joinStmt = '${relatedQuery!._alias}.${columnName}_id = $_alias.id';

    var join = SqlJoin(tableName, _alias, joinStmt);
    columns.where((column) => column._hasCondition).forEach((column) {
      join.conditions.appendAll(
          column.toSqlConditions(_alias, clz.softDeleteField?.columnName));
    });
    return join;
  } */

class TopTableQueryHelper<T> {
  List<QueryCondition> conditions = [];

  void addCondition(QueryCondition queryCondition) {
    conditions.add(queryCondition);
  }

  void addAllCondition(Iterable<QueryCondition> queryConditions) {
    conditions.addAll(queryConditions);
  }

  void debugQuery() {
    print(conditions);

    print('------------ origin (sorted) \n');
    JoinTranslator joinTranslator = JoinTranslator.of(this);
    joinTranslator.debug();

    print('------------ _insert Mid Path\n');
    joinTranslator._insertMidPath();
    joinTranslator.debug();

    print('------------ assign alias\n');
    joinTranslator._assignTableAlias();
    joinTranslator.debug();

    print('------------ join sql \n');
    String joins = joinTranslator._joinSql().join('\n');
    if (joins.isEmpty) {
      joins = 'from $T';
    }

    var clz = ModelInspector.meta('$T')!;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var strAllFields = allFields.map((f) => "t0.${f.columnName}").join(',');

    String sql = 'select $strAllFields $joins';

    print(sql);

    if (conditions.isEmpty) {
      return;
    }

    {
      print('------------ with where sql[prepared style] \n');
      var where = <String>[];
      PreparedConditions preparedConditions = PreparedConditions();
      for (var cond in conditions) {
        where.add(cond.toSql(joinTranslator, preparedConditions));
      }
      sql += '\n where ${where.join(' AND ')}';
      print('sql: $sql');
      print('preparedConditions: ${preparedConditions.values}');
    }
  }

  PreparedQuery toPreparedQuery() {
    JoinTranslator joinTranslator = JoinTranslator.of(this);
    joinTranslator._insertMidPath();
    joinTranslator._assignTableAlias();
    String joins = joinTranslator._joinSql().join('\n');
    var clsName = '$T';
    if (joins.isEmpty) {
      joins = 'from ${genTableName(clsName)} t0';
    }

    var clz = ModelInspector.meta('$T')!;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var strAllFields = allFields.map((f) => "t0.${f.columnName}").join(',');

    String sql = 'select distinct $strAllFields $joins';

    if (conditions.isEmpty) {
      return PreparedQuery(sql, PreparedConditions());
    }

    var where = <String>[];
    PreparedConditions preparedConditions = PreparedConditions();
    for (var cond in conditions) {
      where.add(cond.toSql(joinTranslator, preparedConditions));
    }
    sql += '\n where ${where.join(' AND ')}';
    return PreparedQuery(sql, preparedConditions);
  }
}

class PreparedQuery {
  final String sql;
  final PreparedConditions conditions;

  PreparedQuery(this.sql, this.conditions);
}

class TopTableQuery<T extends Model> extends TableQuery<T> {
  final TopTableQueryHelper<T> _helper = TopTableQueryHelper<T>();
  final Database? _db;

  List<OrderField> orders = [];
  int offset = 0;
  int maxRows = 0;

  TopTableQuery({Database? db})
      : _db = db,
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
    _helper.debugQuery();
  }

  void paging(int pageNumber, int pageSize) {
    maxRows = pageSize;
    offset = pageNumber * pageSize;
  }

  @override
  QueryCondition eq(T value) {
    throw 'should not call eq() directly on TopTableQuery($runtimeType)';
  }

  // operate for query.

  /// find list
  Future<List<T>> findList({bool includeSoftDeleted = false}) async {
    var preparedQuery = _helper.toPreparedQuery();

    var rows = await _db!.query(
        preparedQuery.sql, preparedQuery.conditions.values,
        tableName: "");
    print('result: $rows');

    var clz = ModelInspector.meta('$T')!;
    var fields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);
 
    var result = rows.map((row) {
      return toModel(row, fields);
    });

    return result.toList();

    // throw UnimplementedError();
  }


  T toModel(
      List<dynamic> dbRow, List<OrmMetaField> selectedFields,
      {T? existModel}) {
    T? model = existModel;
    var className = '$T';
    var modelInspector = ModelInspector.lookup(className);
    if (model == null) {
      var idField = ModelInspector.idFields(className)?.first;
      if (idField != null) {
        int j = selectedFields.indexOf(idField);
        if (j >= 0) {
          model = ModelInspector.newModel(className,
              attachDb: true, id: dbRow[j]) as T;
        }
      } else {
        model = ModelInspector.newModel(className,
            attachDb: true) as T;
      }
    }

    for (int i = 0; i < dbRow.length; i++) {
      var f = selectedFields[i];
      var name = f.name;
      var value = dbRow[i];
      if (f.isModelType) {
        if (value != null) {
          var obj = ModelInspector.newModel(f.elementType,
              id: value, attachDb: true);
          modelInspector.setFieldValue(model!, name, obj);
        }
      } else {
        modelInspector.setFieldValue(model!, name, value);
      }
    }
    modelInspector.markLoaded(model!);
    return model;
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
  Future<int> count({bool includeSoftDeleted = false}) {
    throw UnimplementedError();
  }

  /// select with raw sql.
  /// example: findListBySql(' , another_table t1 where t.column_name=t1.id and t.column_name2=@param1 and t1.column_name3=@param2 order by t0.id limit 10 offset 10 ', {'param1':100,'param2':'hello'})
  Future<List<T>> findListBySql(String rawSql,
      [Map<String, dynamic> params = const {}]) async {

    var clzName = '$T';
    var clz = ModelInspector.meta(clzName)!;
    var tableName = genTableName(clzName);

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var strAllFields = allFields.map((f) => "t0.${f.columnName}").join(',');
    var rows = await _db!.query('select distinct $strAllFields from $tableName t0 $rawSql', params);

    print('result: $rows');


    var result = rows.map((row) {
      return toModel(row, allFields);
    });

    return result.toList();
  }

  Future<int> deleteAll() {
    throw UnimplementedError();
  }

  Future<int> deleteAllPermanent() {
    throw UnimplementedError();
  }

  Future<void> insertBatch(List<T> modelList, {int batchSize = 100}) {
    throw UnimplementedError();
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
  final List<JoinPath> paths;
  JoinTranslator(this.paths);

  factory JoinTranslator.of(TopTableQueryHelper helper) {
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
    return JoinTranslator(all);
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

  List<String> _joinSql() {
    var result = <String>[];
    for (var path in paths) {
      if (path.length == 1) {
        result.add('from ${path._lastTableName()} ${path.alias}');
      } else {
        var p = _searchLeftJoin(path);
        // join = '${p.text} :: ${p.alias}';
        var joinColumns = path._findJoinColumns();
        result.add(
            'left join ${path._lastTableName()} ${path.alias} on ${path.alias}.${joinColumns[0]} = ${p.alias}.${joinColumns[1]} ');
      }
      //print('${path.text} :: ${path.alias} ---> $join');
    }
    return result;
  }

  void debug() {
    for (var element in paths) {
      print(element);
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

  String _lastTableName() {
    return genTableName(path.last._innerType);
  }

  List<String> _findJoinColumns() {
    var joinRelation = path.last.joinRelation;
    var joinKind = joinRelation.kind;
    if(joinKind==JoinKind.manyToOne){
      return ['id',"${path.last._columnName}_id"];
    }else if(joinKind==JoinKind.oneToMany){
      // find mappedBy
      var mappedByColumnName = joinRelation.mappedByColumnName;
      return ["${mappedByColumnName}_id",'id'];
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
  final List<ColumnCondition> _conditions = [];
  final String _name;
  final TableQuery? _tableQuery;

  ColumnQuery(TableQuery? parentTableQuery, String columnName)
      : _tableQuery = parentTableQuery,
        _name = columnName;

  List<TableQuery> get _path =>
      _tableQuery == null ? [] : [..._tableQuery!._path, _tableQuery!];

  bool get _hasCondition => _conditions.isNotEmpty;

  String get _columnName => genColumnName(_name);

  void _clear() {
    _conditions.clear();
  }

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
  // _addCondition(ColumnConditionOper.EQ, value);

  Iterable<SqlCondition> toSqlConditions(
      String tableAlias, String? softDeleteColumnName) {
    return _conditions
        .map((e) => _toSqlCondition(tableAlias, softDeleteColumnName, e));
  }

  SqlCondition _toSqlCondition(
      String tableAlias, String? softDeleteColumnName, ColumnCondition cc) {
    SqlCondition sc = SqlCondition("r.$softDeleteColumnName = 0");
    String columnName = '$tableAlias.$_name';
    String paramName = '${tableAlias}__$_name';
    bool isRemote = false;
    String? ssExpr;
    if (cc.value is ServerSideExpr) {
      isRemote = true;
      ssExpr = (cc.value as ServerSideExpr).expr;
    }
    String op = toSql(cc.oper);
    switch (cc.oper) {
      case ColumnConditionOper.EQ:
      case ColumnConditionOper.GT:
      case ColumnConditionOper.LT:
      case ColumnConditionOper.GE:
      case ColumnConditionOper.LE:
      case ColumnConditionOper.LIKE:
        sc = isRemote
            ? SqlCondition("$columnName $op ${ssExpr!} ")
            : SqlCondition(
                "$columnName $op @$paramName ", {paramName: cc.value});
        break;
      case ColumnConditionOper.BETWEEN:
      case ColumnConditionOper.NOT_BETWEEN:
        sc = SqlCondition(
            "$columnName $op @${paramName}_from and @${paramName}_to",
            {'${paramName}_from': cc.value[0], '${paramName}_to': cc.value[1]});
        break;
      case ColumnConditionOper.IN:
      case ColumnConditionOper.NOT_IN:
        sc =
            SqlCondition("$columnName $op @$paramName ", {paramName: cc.value});
        break;
      case ColumnConditionOper.IS_NULL:
      case ColumnConditionOper.IS_NOT_NULL:
        sc = SqlCondition("$columnName $op ");
        break;
      case ColumnConditionOper.EXISTS:
      case ColumnConditionOper.NOT_EXISTS:
      case ColumnConditionOper.NOT:
        break;
      case ColumnConditionOper.AND:
        break;
      case ColumnConditionOper.OR:
        break;
    }
    return sc;
  }

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

const List<String> _sql = [
  '=',
  '>',
  '<',
  '>=',
  '<=',
  'between',
  'not between',
  'like',
  'in',
  'not in',
  'is null',
  'is not null'
];

String toSql(ColumnConditionOper oper) {
  return _sql[oper.index];
}

/// basic implement for AbstractModelQuery
abstract class BaseModelQuery<M extends Model> extends ModelQuery<M> {
  static final Logger _logger = Logger('ORM');

  @override
  final Database db;
  // final ModelInspector modelInspector;

  late BaseModelQuery _topQuery;

  final Map<String, BaseModelQuery> queryMap = {};

  // String get className;

  String _alias = '';

  String get alias => _alias;

  // IntColumn get id => IntColumn(this, "id");

  // List<ColumnQuery> get columns => [id];
  List<ColumnQuery> get columns => [];

  // List<BaseModelQuery> get joins;

  List<OrderField> orders = [];
  int offset = 0;
  int maxRows = 0;

  // for join
  BaseModelQuery? relatedQuery;
  String? propName;

  BaseModelQuery(this.db, {BaseModelQuery? topQuery, this.propName}) {
    _topQuery = topQuery ?? this;
  }
/* 
  bool __hasCondition([List<BaseModelQuery>? historyCache]) {
    // prevent cycle reference
    print('>> \t$propName:$className');
    if (historyCache == null) {
      historyCache = [this];
    } else {
      if (historyCache.contains(this)) {
        return false;
      } else {
        historyCache.add(this);
      }
    }

    var flag = columns.any((c) => c._hasCondition) ||
        joins.any((j) => j.__hasCondition(historyCache));
    print('<< \t$propName:$className.flag:$flag');
    return flag;
  } */

  BaseModelQuery get topQuery => _topQuery;

  SqlJoin _toSqlJoin() {
    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;
    var columnName = getColumnName(propName!);
    var joinStmt = '${relatedQuery!._alias}.${columnName}_id = $_alias.id';

    var join = SqlJoin(tableName, _alias, joinStmt);
    columns.where((column) => column._hasCondition).forEach((column) {
      join.conditions.appendAll(
          column.toSqlConditions(_alias, clz.softDeleteField?.columnName));
    });
    return join;
  }

  String getColumnName(String fieldName) {
    return ReCase(fieldName).snakeCase;
  }

  @override
  Future<int> insert(M model) async {
    var action = ActionType.insert;
    var className = ModelInspector.getClassName(model);
    var modelInspector = ModelInspector.lookup(className);
    var clz = ModelInspector.meta(className)!;
    var idField = clz.idFields.first;
    var tableName = clz.tableName;

    var softDeleteField = clz.softDeleteField;
    if (softDeleteField != null) {
      modelInspector.markDeleted(model, false);
    }

    var versionField = clz.versionField;
    if (versionField != null) {
      modelInspector.setFieldValue(model, versionField.name, 1);
    }

    modelInspector.setCurrentUser(model, insert: true, update: true);

    var dirtyMap = modelInspector.getDirtyFields(model);
    var ssFields = clz.serverSideFields(action, searchParents: true);

    var ssFieldNames = ssFields.map((e) => e.name);
    var columnNames = [...dirtyMap.keys, ...ssFieldNames]
        .map((fn) => clz.findField(fn)!.columnName)
        .join(',');

    var ssFieldValues = ssFields.map((e) => e.ormAnnotations
        .firstWhere((element) => element.isServerSide(action))
        .serverSideExpr(action));

    var fieldVariables = [
      ...dirtyMap.keys.map((e) => '@$e'),
      ...ssFieldValues,
    ].join(',');
    var sql =
        'insert into $tableName( $columnNames ) values( $fieldVariables )';
    _logger.fine('Insert SQL: $sql');

    dirtyMap.forEach((key, value) {
      if (value is Model) {
        var clsName = ModelInspector.getClassName(value);
        var inspector = ModelInspector.lookup(clsName);
        var clz = ModelInspector.meta(clsName);
        dirtyMap[key] =
            inspector.getFieldValue(value, clz!.idFields.first.name);
      }
    });

    var id = await db.query(sql, dirtyMap,
        returningFields: [idField.columnName],
        tableName: tableName,
        hints: _hints(clz, dirtyMap));
    _logger.fine(' >>> query returned: $id');
    if (id.isNotEmpty) {
      if (id[0].isNotEmpty) {
        modelInspector.setFieldValue(model, idField.name, id[0][0]);
        return id[0][0];
      }
    }
    return 0;
  }

  Map<String, QueryHint> _hints(
      OrmMetaClass metaClass, Map<String, dynamic> params) {
    var hints = <String, QueryHint>{};
    params.forEach((key, value) {
      var f = metaClass.findField(key);
      if (f != null) {
        if (f.ormAnnotations.whereType<Lob>().isNotEmpty &&
            !f.type.contains('String')) {
          hints[key] = QueryHint.lob;
        }
      }
    });
    return hints;
  }

  Future<void> insertBatch(List<M> modelList, {int batchSize = 100}) async {
    if (modelList.isEmpty) return;
    if (modelList.length <= batchSize) return _insertBatch(modelList);

    for (int i = 0; i < modelList.length; i += batchSize) {
      var sublist = modelList.sublist(i, min(modelList.length, i + batchSize));
      await _insertBatch(sublist);
    }
  }

  Future<void> _insertBatch(List<M> modelList) async {
    if (modelList.isEmpty) return;
    var count = modelList.length;
    // var action = ActionType.Insert;
    var className = ModelInspector.getClassName(modelList[0]);
    var modelInspector = ModelInspector.lookup(className);
    var clz = ModelInspector.meta(className)!;
    var idField = clz.idFields.first;
    var idColumnName = idField.columnName;
    var tableName = clz.tableName;

    var softDeleteField = clz.softDeleteField;
    if (softDeleteField != null) {
      for (var model in modelList) {
        modelInspector.markDeleted(model, false);
      }
    }

    var versionField = clz.versionField;
    if (versionField != null) {
      for (var model in modelList) {
        modelInspector.setFieldValue(model, versionField.name, 1);
      }
    }

    for (var model in modelList) {
      modelInspector.setCurrentUser(model, insert: true, update: true);
    }

    // all but id fields
    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.isIdField || f.notExistsInDb);

    var columnNames = allFields.map((e) => e.columnName).join(',');

    var fieldVariables = [];
    //allFields.map((e) => '@${e.name}').join(',');

    for (int i = 0; i < count; i++) {
      var one = allFields.map((e) => '@${e.name}_$i').join(',');
      fieldVariables.add('( $one )');
    }

    var sql =
        'insert into $tableName( $columnNames ) values ${fieldVariables.join(",")}';
    _logger.fine('Insert SQL: $sql');

    var dirtyMap = <String, dynamic>{};

    for (var f in allFields) {
      for (int i = 0; i < count; i++) {
        dirtyMap['${f.name}_$i'] =
            modelInspector.getFieldValue(modelList[i], f.name);
      }
    }
    dirtyMap.forEach((key, value) {
      if (value is Model) {
        var clz = ModelInspector.meta(ModelInspector.getClassName(value));
        dirtyMap[key] =
            modelInspector.getFieldValue(value, clz!.idFields.first.name);
      }
    });
    var rows = await db.query(sql, dirtyMap,
        returningFields: [idColumnName],
        tableName: tableName,
        hints: _hints(clz, dirtyMap));
    _logger.fine(' >>> query returned: $rows');
    if (rows.isNotEmpty) {
      for (int i = 0; i < rows.length; i++) {
        var id = rows[i][0];
        modelInspector.setFieldValue(modelList[i], idField.name, id);
      }
    }
  }

  @override
  Future<void> update(M model) async {
    var action = ActionType.update;
    var className = ModelInspector.getClassName(model);
    var modelInspector = ModelInspector.lookup(className);
    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;

    modelInspector.setCurrentUser(model, insert: false, update: true);

    var dirtyMap = modelInspector.getDirtyFields(model);

    var idField = clz.idFields.first; // @TODO
    dirtyMap.remove(idField.name);

    var versionField = clz.versionField;
    if (versionField != null) {
      dirtyMap.remove(versionField.name);
    }

    var idValue = modelInspector.getFieldValue(model, clz.idFields.first.name);

    var ssFields = clz.serverSideFields(action, searchParents: true);

    var setClause = <String>[];

    for (var name in dirtyMap.keys) {
      setClause.add('${clz.findField(name)!.columnName}=@$name');
    }

    for (var field in ssFields) {
      // var name = field.name;
      var value = field.ormAnnotations
          .firstWhere((element) => element.isServerSide(action))
          .serverSideExpr(action);

      setClause.add("${field.columnName}=$value");
    }

    dirtyMap[idField.name] = idValue;
    var sql =
        'update $tableName set ${setClause.join(',')} where ${idField.name}=@${idField.name}';
    if (versionField != null) {
      int oldVersion =
          modelInspector.getFieldValue(model, versionField.name) as int;
      sql =
          'update $tableName set ${setClause.join(',')}, ${versionField.columnName}=${oldVersion + 1} where ${idField.name}=@${idField.name} and ${versionField.columnName}=$oldVersion';
    }
    _logger.fine('Update SQL: $sql');

    dirtyMap.forEach((key, value) {
      if (value is Model) {
        var clz = ModelInspector.meta(ModelInspector.getClassName(value));
        dirtyMap[key] =
            modelInspector.getFieldValue(value, clz!.idFields.first.name);
      }
    });

    var queryResult = await db.query(sql, dirtyMap,
        tableName: tableName, hints: _hints(clz, dirtyMap));
    if (versionField != null && queryResult.affectedRowCount != 1) {
      throw 'update failed, expected 1 row affected, but ${queryResult.affectedRowCount} rows affected actually!';
    }
  }

  @override
  Future<void> delete(M model) async {
    var className = ModelInspector.getClassName(model);
    var modelInspector = ModelInspector.lookup(className);
    var clz = ModelInspector.meta(className)!;
    var softDeleteField = clz.softDeleteField;
    if (softDeleteField == null) {
      return deletePermanent(model);
    }
    var idField = clz.idFields.first;
    var idValue = modelInspector.getFieldValue(model, idField.name);
    var tableName = clz.tableName;
    _logger.fine('delete $tableName , fields: $idValue');
    var sql =
        'update $tableName set ${softDeleteField.columnName} = 1 where ${idField.columnName} = @id ';
    var versionField = clz.versionField;
    if (versionField != null) {
      sql =
          'update $tableName set ${softDeleteField.columnName} = 1, ${versionField.columnName}=${versionField.columnName}+1 where ${idField.columnName} = @id ';
    }
    await db.query(sql, {"id": idValue}, tableName: tableName);
  }

  @override
  Future<void> deletePermanent(M model) async {
    var className = ModelInspector.getClassName(model);
    var modelInspector = ModelInspector.lookup(className);
    var clz = ModelInspector.meta(className)!;
    var idField = clz.idFields.first;
    var idValue = modelInspector.getFieldValue(model, idField.name);
    var tableName = clz.tableName;
    _logger.fine('deleteOnePermanent $tableName , id: $idValue');
    var sql = 'delete $tableName where ${idField.columnName} = @id ';
    await db.query(sql, {"id": idValue}, tableName: tableName);
  }

  @override
  Future<int> deleteAll() async {
    // init all table aliases.
    _beforeQuery();

    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;
    var idField = clz.idFields.first;
    var softDeleteField = clz.softDeleteField;

    if (softDeleteField == null) {
      return deleteAllPermanent();
    }

    SqlQuery q = SqlQuery(tableName, _alias);

    // _allJoins().map((e) => )
    q.joins.addAll(_allJoins().map((e) => e._toSqlJoin()));

    var conditions = columns.fold<List<SqlCondition>>(
        [],
        (init, e) => init
          ..addAll(e.toSqlConditions(_alias, softDeleteField.columnName)));

    q.conditions.appendAll(conditions);

    var sql = q.toSoftDeleteSql(idField.columnName, softDeleteField.columnName,
        clz.versionField?.columnName);
    var params = q.params;
    params['deleted'] = true;
    _logger.fine('\t soft delete sql: $sql');
    var rows = await db.query(sql, params, tableName: tableName);
    _logger.fine('\t soft delete result rows: ${rows.affectedRowCount}');
    return rows.affectedRowCount ?? -1;
  }

  @override
  Future<int> deleteAllPermanent() async {
    // init all table aliases.
    _beforeQuery();

    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;
    var idField = clz.idFields.first;

    SqlQuery q = SqlQuery(tableName, _alias);

    // _allJoins().map((e) => )
    q.joins.addAll(_allJoins().map((e) => e._toSqlJoin()));

    var conditions = columns.fold<List<SqlCondition>>(
        [], (init, e) => init..addAll(e.toSqlConditions(_alias, null)));

    q.conditions.appendAll(conditions);

    var sql = q.toPermanentDeleteSql(idField.columnName);
    var params = q.params;
    _logger.fine('\t hard delete sql: $sql');

    var rows = await db.query(sql, params, tableName: tableName);
    _logger.fine('\t hard delete result rows: ${rows.affectedRowCount}');
    return rows.affectedRowCount ?? -1;
  }

  @override
  Future<M?> findById(dynamic id,
      {M? existModel, bool includeSoftDeleted = false}) async {
    var clz = ModelInspector.meta(className)!;

    var idFields = clz.idFields;
    var idFieldName = idFields.first.name;
    var tableName = clz.tableName;
    var softDeleteField = clz.softDeleteField;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var columnNames = allFields.map((f) => f.columnName).join(',');

    var sql = 'select $columnNames from $tableName where $idFieldName = $id';
    var params = <String, dynamic>{};

    if (softDeleteField != null && !includeSoftDeleted) {
      sql += ' and ${softDeleteField.columnName}=@_deleted ';
      params['_deleted'] = false;
    }

    _logger.fine('findById: $className [$id] => $sql');

    var rows = await db.query(sql, params, tableName: tableName);

    if (rows.isNotEmpty) {
      return toModel(rows[0], allFields, className, existModel: existModel);
    }
    return null;
  }

  @override
  Future<List<M>> findByIds(List idList,
      {List<Model>? existModeList, bool includeSoftDeleted = false}) async {
    var clz = ModelInspector.meta(className)!;

    var idFields = clz.idFields;
    var idFieldName = idFields.first.name;
    var tableName = clz.tableName;
    var softDeleteField = clz.softDeleteField;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var columnNames = allFields.map((f) => f.columnName).join(',');

    var sql =
        'select $columnNames from $tableName where $idFieldName in @idList';
    var params = <String, dynamic>{'idList': idList};
    if (softDeleteField != null && !includeSoftDeleted) {
      sql += ' and ${softDeleteField.columnName}=@_deleted ';
      params['_deleted'] = false;
    }
    _logger.fine('findByIds: $className $idList => $sql');

    var rows = await db.query(sql, params, tableName: tableName);
    // _logger.info('\t rows: ${rows.length}');

    return _toModel(rows, allFields, idFieldName, existModeList);
  }

  List<M> _toModel(DbQueryResult rows, List<OrmMetaField> allFields,
      String idFieldName, List<Model>? existModeList) {
    var modelInspector = ModelInspector.lookup(className);

    if (rows.isNotEmpty) {
      var idIndex = 0;
      if (existModeList != null) {
        for (int i = 0; i < allFields.length; i++) {
          if (allFields[i].name == idFieldName) {
            idIndex = i;
            break;
          }
        }
      }
      var result = <M>[];
      for (int i = 0; i < rows.length; i++) {
        if (existModeList == null) {
          result.add(toModel(rows[i], allFields, className));
        } else {
          var id = rows[i][idIndex];
          // _logger.info('\t id: $id');
          M? m;
          var list = existModeList.where((element) =>
              modelInspector.getFieldValue(element, idFieldName) == id);
          if (list.isNotEmpty) {
            m = list.first as M;
          }
          // _logger.info('\t existModel: $m');
          result.add(toModel(rows[i], allFields, className, existModel: m));
        }
      }
      return result;
    }
    return [];
  }

  @override
  Future<List<M>> findBy(Map<String, dynamic> params,
      {List<Model>? existModeList, bool includeSoftDeleted = false}) async {
    var clz = ModelInspector.meta(className)!;
    var modelInspector = ModelInspector.lookup(className);

    var idFields = clz.idFields;
    var idFieldName = idFields.first.name;
    var tableName = clz.tableName;
    var softDeleteField = clz.softDeleteField;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var columnNames = allFields.map((f) => f.columnName).join(',');

    var sql = 'select $columnNames from $tableName where ';

    sql += params.keys.map((key) {
      var f = allFields.firstWhere((element) => element.name == key);
      if (f.isModelType) {
        // replace model with it's id.
        var m = params[key];
        if (ModelInspector.isModelType(m.runtimeType.toString())) {
          var idFieldName =
              ModelInspector.idFields(ModelInspector.getClassName(m))!
                  .first
                  .name;
          params[key] = modelInspector.getFieldValue(m, idFieldName);
        }
        return '${f.columnName}=@$key';
      }
      return '${f.columnName}=@$key';
    }).join(' and ');

    if (softDeleteField != null && !includeSoftDeleted) {
      sql += ' and ${softDeleteField.columnName}=@_deleted ';
      params['_deleted'] = false;
    }
    //_logger.fine('findByIds: ${className} $idList => $sql');

    var rows = await db.query(sql, params, tableName: tableName);

    return _toModel(rows, allFields, idFieldName, existModeList);
  }

  paging(int pageNumber, int pageSize) {
    maxRows = pageSize;
    offset = pageNumber * pageSize;
  }

  N toModel<N extends Model>(
      List<dynamic> dbRow, List<OrmMetaField> selectedFields, String className,
      {N? existModel}) {
    N? model = existModel;
    var modelInspector = ModelInspector.lookup(className);
    if (existModel == null) {
      var idField = ModelInspector.idFields(className)?.first;
      if (idField != null) {
        int j = selectedFields.indexOf(idField);
        if (j >= 0) {
          model = ModelInspector.newModel(className,
              attachDb: true, id: dbRow[j]) as N;
        }
      } else {
        model = ModelInspector.newModel(className,
            attachDb: true) as N;
      }
    }

    for (int i = 0; i < dbRow.length; i++) {
      var f = selectedFields[i];
      var name = f.name;
      var value = dbRow[i];
      if (f.isModelType) {
        if (value != null) {
          var obj = ModelInspector.newModel(f.elementType,
              id: value, attachDb: true);
          modelInspector.setFieldValue(model!, name, obj);
        }
      } else {
        modelInspector.setFieldValue(model!, name, value);
      }
    }
    modelInspector.markLoaded(model!);
    return model;
  }

  @override
  Future<List<M>> findList({bool includeSoftDeleted = false}) async {
    // init all table aliases.
    _beforeQuery();

    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;
    var softDeleteField = clz.softDeleteField;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    SqlQuery q = SqlQuery(tableName, _alias);
    q.columns.addAll(allFields.map((f) => "$_alias.${f.columnName}"));

    q.joins.addAll(_allJoins().map((e) => e._toSqlJoin()));

    if (softDeleteField != null && !includeSoftDeleted) {
      q.conditions.append(
          SqlCondition('$_alias.${softDeleteField.columnName}=@_deleted'));
    }

    var conditions = columns.fold<List<SqlCondition>>(
        [],
        (init, e) => init
          ..addAll(e.toSqlConditions(_alias, softDeleteField?.columnName)));
    q.conditions.appendAll(conditions);

    var sql = q.toSelectSql();
    var params = q.params;
    if (softDeleteField != null && !includeSoftDeleted) {
      params['_deleted'] = false;
    }

    if (orders.isNotEmpty) {
      sql += ' order by ${orders.map((e) => e.toString()).join(',')}';
    }

    if (maxRows > 0) {
      sql += ' limit $maxRows';
    }

    if (offset > 0) {
      sql += ' offset $offset';
    }

    var rows = await db.query(sql, params, tableName: tableName);

    _logger.fine('\t sql: $sql');
    _logger.fine('\t rows: ${rows.length}');

    var result = rows.map((row) {
      return toModel<M>(row, allFields, className);
    });

    return result.toList();
  }

  @override
  Future<List<M>> findListBySql(String rawSql,
      [Map<String, dynamic> params = const {}]) async {
    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;

    var allFields = clz.allFields(searchParents: true)
      ..removeWhere((f) => f.notExistsInDb);

    var rows = await db.query(rawSql, params, tableName: tableName);

    _logger.fine('\t sql: $rawSql');
    _logger.fine('\t rows: ${rows.length}');

    var fields = rows.columnDescriptions
        .map((c) => allFields.firstWhere((f) => f.columnName == c.columnName))
        .toList();

    var result = rows.map((row) {
      return toModel<M>(row, fields, className);
    });

    return result.toList();
  }

  @override
  Future<int> count({bool includeSoftDeleted = false}) async {
    // init all table aliases.
    _beforeQuery();

    var clz = ModelInspector.meta(className)!;
    var tableName = clz.tableName;
    var softDeleteField = clz.softDeleteField;

    var idColumnName = clz.idFields.first.columnName;

    SqlQuery q = SqlQuery(tableName, _alias);

    // _allJoins().map((e) => )
    q.joins.addAll(_allJoins().map((e) => e._toSqlJoin()));

    if (softDeleteField != null && !includeSoftDeleted) {
      q.conditions.append(
          SqlCondition('$_alias.${softDeleteField.columnName}=@_deleted'));
    }

    var conditions = columns.fold<List<SqlCondition>>(
        [],
        (init, e) => init
          ..addAll(e.toSqlConditions(_alias, softDeleteField?.columnName)));
    q.conditions.appendAll(conditions);

    var sql = q.toCountSql(idColumnName);
    var params = q.params;

    if (softDeleteField != null && !includeSoftDeleted) {
      params['_deleted'] = false;
    }

    var rows = await db.query(sql, params, tableName: tableName);

    _logger.fine('\t sql: $sql');
    _logger.fine('\t rows: ${rows.length} \t\t $rows');
    return (rows[0][0]).toInt();
  }

  T findQuery<T extends BaseModelQuery>(Database db, String ownerModelName,
      String propName, String propModelName) {
    var key = '$ownerModelName-$propName';
    print('>> lookup query: $key');
    var q = topQuery.queryMap[key];

/*  @TODO   
    if (q == null) {
      q = ModelInspector.lookup(propModelName).newQuery(db, propModelName)
          as BaseModelQuery
        .._topQuery = this
        ..propName = propName
        ..relatedQuery = this;
      topQuery.queryMap[key] = q;
    }
 */
    return q as T;
  }

  void _beforeQuery() {
    if (_topQuery != this) return;
    var allJoins = _allJoins();
    int i = 0;
    _alias = "t${i++}";
    for (var join in allJoins) {
      join._alias = "t${i++}";
    }
  }

  List<BaseModelQuery> _allJoins() {
    return _subJoins([], []);
  }

  List<BaseModelQuery> _subJoins(
      List<BaseModelQuery> refrenceCache, List<BaseModelQuery> historyCache) {
    /* print('==allJoins of $this , $className');
    var joins2 = joins
        // filter those with conditions
        .where((j) => j._hasCondition(historyCache))
        .toList();
    // prevent cycle reference
    var joins3 = joins2.where((j) => !refrenceCache.contains(j)).toList();
    joins3.forEach((j) {
      refrenceCache.add(j);
    });
    return refrenceCache; */
    return [];
  }
}

/// lazy list
