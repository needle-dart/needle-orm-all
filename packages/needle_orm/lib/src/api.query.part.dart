part of 'api.dart';

/// Query for a Model
abstract class ModelQuery<M extends Model> {
  /* static ModelQuery newQuery(Database db, String className) {
    return ModelInspector.lookup(className).newQuery(db, className);
  } */

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

  Future<int> deleteAll();

  Future<int> deleteAllPermanent();

  Future<void> ensureLoaded(Model m, {int batchSize = 1});
}

class LazyOneToManyList<T extends Model> with ListMixin<T> implements List<T> {
  // late Database db; // model who holds the reference id
  late OrmMetaClass clz; // model who holds the reference id
  late OrmMetaField refField; // field in model
  late dynamic refFieldValue; // usually foreign id

  late List<Model> _list;
  var _loaded = false;

  LazyOneToManyList(
      { //required this.db,
      required this.clz,
      required this.refField,
      required this.refFieldValue});

  LazyOneToManyList.of(List<Model> list) {
    _list = list;
    _loaded = true;
  }

  @override
  int get length {
    if(!_loaded){
      return 0;
    }
    //_checkLoaded();
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
/* @TODO 
    var modelInspector = ModelInspector.lookup(clz.name);
    var query = modelInspector.newQuery(db, clz.name) as ModelQuery<T>;
    _list = await query.findBy({refField.name: refFieldValue});
 */
    _loaded = true;
  }
}

extension LazyListEnhancement on List<Model> {
  Future<void> load() {
    return (this as LazyOneToManyList).load();
  }
}
