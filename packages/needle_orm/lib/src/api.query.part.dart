part of 'api.dart';

/// Query for a Model
abstract class ModelQuery<M extends Model> {
  static ModelQuery newQuery(Database db, String className) {
    return ModelInspector.lookup(className).newQuery(db, className);
  }

  ModelQuery();

  Database get db;

  String get className;

  // operate for Model instance.

  /// return how many rows affected!
  Future<void> insert(M model);

  /// return how many rows affected!
  Future<void> update(M model);

  /// return how many rows affected!
  Future<void> delete(M model);

  /// return how many rows affected!
  Future<void> deletePermanent(M model);

  // operate for query.

  /// find single model by [id]
  /// if [existModel] is given, [existModel] will be filled and returned, otherwise a new model will be returned.
  Future<M?> findById(ID id, {M? existModel, bool includeSoftDeleted = false});

  /// find models by [idList]
  Future<List<M>> findByIds(List idList,
      {List<Model>? existModeList, bool includeSoftDeleted = false});

  /// find models by params
  Future<List<M>> findBy(Map<String, dynamic> params,
      {List<Model>? existModeList, bool includeSoftDeleted = false});

  /// find list
  Future<List<M>> findList({bool includeSoftDeleted = false});

  /// return count of this query.
  Future<int> count();

  /// select with raw sql.
  /// example: findListBySql(' select distinct(t.*) from table t, another_table t2 where t.column_name=t2.id and t.column_name2=@param1 and t2.column_name3=@param2 order by t.id, limit 10 offset 10 ', {'param1':100,'param2':'hello'})
  Future<List<M>> findListBySql(String rawSql,
      [Map<String, dynamic> params = const {}]);

  Future<int> deleteAll();

  Future<int> deleteAllPermanent();

  Future<void> ensureLoaded(Model m, {int batchSize = 1});
}

class LazyOneToManyList<T extends Model> with ListMixin<T> implements List<T> {
  late Database db; // model who holds the reference id
  late OrmMetaClass clz; // model who holds the reference id
  late OrmMetaField refField; // field in model
  late dynamic refFieldValue; // usually foreign id

  late List<Model> _list;
  var _loaded = false;

  LazyOneToManyList(
      {required this.db,
      required this.clz,
      required this.refField,
      required this.refFieldValue});

  LazyOneToManyList.of(List<Model> list) {
    _list = list;
    _loaded = true;
  }

  @override
  int get length {
    _checkLoaded();
    return _list.length;
  }

  @override
  set length(int value) {
    throw UnimplementedError();
  }

  @override
  T operator [](int index) {
    _checkLoaded();
    return _list[index] as T;
  }

  @override
  void operator []=(int index, T value) {}

  void _checkLoaded() {
    if (!_loaded) {
      throw 'please invoke load() first!';
    }
  }

  /// load list from db.
  Future<void> load() async {
    if (_loaded) return;
    var modelInspector = ModelInspector.lookup(clz.name);
    var query = modelInspector.newQuery(db, clz.name) as ModelQuery<T>;
    _list = await query.findBy({refField.name: refFieldValue});
    _loaded = true;
  }
}

extension LazyListEnhancement on List<Model> {
  Future<void> load() {
    return (this as LazyOneToManyList).load();
  }
}
