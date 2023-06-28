import 'api.dart';
import 'inspector.dart';
import 'sql.dart';

/// [ModelHelper] keeps inner state of a [Model] instance.
/// can ONLY be used by generators!
class ModelHelper<M extends Model> {
  final M model;
  bool storeLoaded = false; // if fields has been loaded from db.
  bool storeAttached = false; // if this instance is created by Query
  // mark all modified fields after loaded
  final dirtyFields = <String>{};
  String className;

  late ModelInspector<M> inspector;
  ModelHelper(this.model, this.className) {
    inspector = ModelInspector.lookup(className);
  }

  /// mark model as [attached]
  /// can also bind to a [ModelQuery] as well
  void markAttached(bool attached) {
    storeAttached = attached;
  }

  /// mark model as [loaded]
  /// will clean dirty fields as well
  void markLoaded(bool loaded) {
    storeLoaded = loaded;
    cleanDirty();
  }

  /// mark field [fieldName] as dirty when necessary ( value is truely changed!)
  void markDirty(Object? oldValue, Object? newValue, String fieldName) {
    if (oldValue == null && newValue == null) {
      // both are null: not dirty.
      return;
    } else if (oldValue == null || newValue == null) {
      // only one is null: dirty
      dirtyFields.add(fieldName);
      return;
    }
    // both are non-null:
    if (oldValue != newValue) {
      dirtyFields.add(fieldName);
    }
  }

  /// clean dirty fields
  void cleanDirty() {
    dirtyFields.clear();
  }

  /// ensure model is attached & loaded , otherwise an error will be thown.
  void ensureLoaded() {
    if (storeAttached && !storeLoaded) {
      throw 'should call load() before accessing properties!';
    }
  }

  Map<String, dynamic> toMap(
      {String fields = '*',
      bool ignoreNull = true,
      Map<String, dynamic>? map}) {
    return inspector.toMap(model,
        fields: fields, ignoreNull: ignoreNull, map: map);
  }

  void loadMap(Map<String, dynamic> m, {errorOnNonExistField = false}) {
    m.forEach((key, value) {
      inspector.setFieldValue(model, key, value,
          errorOnNonExistField: errorOnNonExistField);
    });
  }

  ModelQuery _query(Database? db) => throw UnimplementedError();
  // @TODO ModelQuery.newQuery(db ?? Database.defaultDb, className);

  Future<void> insert({Database? db}) async {
    inspector.prePersist(model);
    await _query(db).insert(model);
    cleanDirty();
    inspector.postPersist(model);
  }

  Future<void> update({Database? db}) async {
    inspector.preUpdate(model);
    if (dirtyFields.isNotEmpty) {
      await _query(db).update(model);
      cleanDirty();
    }
    inspector.postUpdate(model);
  }

  Future<void> save({Database? db}) async {
    if (model.id != null) {
      await update(db: db);
    } else {
      await insert(db: db);
    }
  }

  Future<void> delete({Database? db}) async {
    inspector.preRemove(model);
    await _query(db).delete(model);
    inspector.postRemove(model);
  }

  Future<void> deletePermanent({Database? db}) async {
    inspector.preRemovePermanent(model);
    await _query(db).deletePermanent(model);
    inspector.postRemovePermanent(model);
  }
}
