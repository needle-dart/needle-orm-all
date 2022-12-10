part of 'api.dart';

abstract class ModelQueryFactory {
  ModelQuery? newQuery(Database db, String className);
}

/// Query for a Model
abstract class ModelQuery<M extends Model> {
  static ModelQuery newQuery(Database db, String className) {
    return ModelInspector.lookup(className).newQuery(db, className);
  }

  ModelQuery();

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
