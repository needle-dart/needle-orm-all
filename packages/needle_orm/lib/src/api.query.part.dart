part of 'api.dart';

/// Query for a Model
abstract class ModelQuery<M extends Model> {
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
