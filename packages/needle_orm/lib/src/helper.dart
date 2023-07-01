import 'package:logging/logging.dart';

import '../impl.dart';
import 'api.dart';
import 'sql.dart';
import 'sql_adapter.dart';

final Logger _logger = Logger('ORM');

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

  Future<void> insert({Database? db}) async {
    inspector.prePersist(model);
    await __insert(db: db);
    cleanDirty();
    inspector.postPersist(model);
  }

  Future<void> update({Database? db}) async {
    inspector.preUpdate(model);

    if (dirtyFields.isEmpty) {
      return;
    }

    await __update(db: db);
    cleanDirty();
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
    await __delete(db: db);
    inspector.postRemove(model);
  }

  Future<void> deletePermanent({Database? db}) async {
    inspector.preRemovePermanent(model);
    await __deletePermanent(db: db);
    inspector.postRemovePermanent(model);
  }

  Future<int> __insert({Database? db}) async {
    db ??= Database.defaultDb;
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

    var ssFieldValues = ssFields.map((e) {
      var annot = e.ormAnnotations
          .firstWhere((element) => element.isServerSide(action));

      return serverSideExpr(annot, action, db!.dbType);
    });

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
        var value = convertValue(id[0][0], idField, db.dbType);
        modelInspector.setFieldValue(model, idField.name, value);
        return value;
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

  Future<void> __update({Database? db}) async {
    db ??= Database.defaultDb;
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
      var ann = field.ormAnnotations
          .firstWhere((element) => element.isServerSide(action));
      var value = serverSideExpr(ann, action, db.dbType);

      setClause.add("${field.columnName}=$value");
    }

    dirtyMap[idField.name] = idValue;
    var newVersion = -1;
    var sql =
        'update $tableName set ${setClause.join(',')} where ${idField.name}=@${idField.name}';
    if (versionField != null) {
      int oldVersion =
          modelInspector.getFieldValue(model, versionField.name) as int;
      newVersion = oldVersion + 1;
      sql =
          'update $tableName set ${setClause.join(',')}, ${versionField.columnName}=$newVersion where ${idField.name}=@${idField.name} and ${versionField.columnName}=$oldVersion';
    }
    _logger.fine('Update SQL: $sql');

    dirtyMap.forEach((key, value) {
      if (value is Model) {
        var clz = ModelInspector.meta(ModelInspector.getClassName(value));
        dirtyMap[key] =
            modelInspector.getFieldValue(value, clz!.idFields.first.name);
      }
    });

    // _logger.info(' >>> query sql: $sql');

    var queryResult = await db.query(sql, dirtyMap,
        tableName: tableName,
        // returningFields: [if (versionField != null) versionField.columnName],
        hints: _hints(clz, dirtyMap));

    // _logger.info(' >>> query returned: $queryResult');

    // update version field
    if (queryResult.affectedRowCount! > 0) {
      if (versionField != null && newVersion > 0) {
        // var v = convertValue(queryResult[0][0], versionField, db.dbType);
        modelInspector.setFieldValue(model, versionField.name, newVersion);
      }
      return;
    }

    if (versionField != null && queryResult.affectedRowCount != 1) {
      throw 'update failed, expected 1 row affected, but ${queryResult.affectedRowCount} rows affected actually!';
    }
  }

  Future<void> __delete({Database? db}) async {
    db ??= Database.defaultDb;
    var className = ModelInspector.getClassName(model);
    var modelInspector = ModelInspector.lookup(className);
    var clz = ModelInspector.meta(className)!;
    var softDeleteField = clz.softDeleteField;
    if (softDeleteField == null) {
      return __deletePermanent(db: db);
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

  Future<void> __deletePermanent({Database? db}) async {
    db ??= Database.defaultDb;
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
}
