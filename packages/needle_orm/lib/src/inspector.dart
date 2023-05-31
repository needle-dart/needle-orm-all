import 'api.dart';
import 'meta.dart';
import 'helper.dart';

/// Inspector: to spy and operate on model objects
abstract class ModelInspector<M extends Model> {
  static Map<String, OrmMetaClass> metaMap = {};
  static Map<String, ModelInspector> inspectorMap = {};

  static ModelHelper _helper(Model model) => Needle.helper(model);

  static void registerMetaClass(String className, OrmMetaClass metaClass) {
    metaMap[className] = metaClass;
  }

  static void registerAllMetaClasses(List<OrmMetaClass> metaClasses) {
    for (var metaClass in metaClasses) {
      metaMap[metaClass.name] = metaClass;
    }
  }

  static void register(String className, ModelInspector inspector) {
    inspectorMap[className] = inspector;
  }

  static void registerAll(List<ModelInspector> inspectors) {
    for (var inspector in inspectors) {
      inspectorMap[inspector.className] = inspector;
    }
  }

  static ModelInspector<T> lookup<T extends Model>(String className) {
    var mi = inspectorMap[className];
    if (mi == null) {
      throw UnimplementedError('no inspector for: $className');
    }
    return mi as ModelInspector<T>;
  }

  static OrmMetaClass lookupClass(String className) {
    var clz = metaMap[className];
    if (clz == null) {
      throw UnimplementedError();
    }
    return clz;
  }

  /// return the class name of [model]
  static String getClassName(Model model) {
    return model.runtimeType.toString();
  }

  /// create a new instance of specified [className]
  /// newInstance() might return an instance cached in top query.
  static Model newModel(String className,
      {bool attachDb = false, dynamic id, required ModelQuery topQuery}) {
/*     if (id != null) {
      var cacheModel =
          (topQuery as _BaseModelQuery)._modelCache.find(className, id);
      if (cacheModel != null) {
        return cacheModel;
      }
    }
 */
    var inspector = lookup(className);
    Model model = inspector.newInstance(topQuery: topQuery, id: id);

    // topQuery._modelCache.add(model);
    return model;
  }

  /// init model properties after [newInstance()]
  void initInstance(M m, {required ModelQuery<Model> topQuery}) {}

  static bool storeLoaded(Model model) => _helper(model).storeLoaded;

  String get className;

  /// create a new instance of specified [className]
  /// newInstance() might return an instance cached in top query.
  M newInstance(
      {bool attachDb = false, dynamic id, required ModelQuery<M> topQuery});
/* 
  ModelQuery newQuery(Database db, String className) {
    throw UnimplementedError();
  }
 */
  /// return class meta info for [className]
  static OrmMetaClass? meta(String className) => metaMap[className];

  /// all known classes
  static List<OrmMetaClass> get allOrmMetaClasses => metaMap.values.toList();

  /// check whether a [type] is a model name.
  static bool isModelType(String type) {
    if (type.endsWith('?')) {
      type = type.substring(0, type.length - 1);
    }
    return meta(type) != null;
  }

  /// return id fields of [className]
  static List<OrmMetaField>? idFields(String className) {
    return meta(className)?.idFields;
  }

  /// return all fields of [className]
  static List<OrmMetaField>? allFields(String className,
      {bool searchParents = false}) {
    return meta(className)?.allFields(searchParents: searchParents);
  }

  /// return soft-delete field of [className]
  static List<OrmMetaField>? softDeleteField(String className) {
    return meta(className)?.idFields;
  }

  /// return modified fields of [model] as a Map
  Map<String, dynamic> getDirtyFields(M model) {
    var fields = _helper(model).dirtyFields;
    var map = <String, dynamic>{};
    for (String name in fields) {
      map[name] = getFieldValue(model, name);
    }
    return map;
  }

  /// return the value of [model].[fieldName]
  dynamic getFieldValue(M model, String fieldName) {
    switch (fieldName) {
      case "id":
        return model.id;
    }
  }

  /// set the value of [model].[fieldName] as [value]
  void setFieldValue(M model, String fieldName, dynamic value,
      {errorOnNonExistField = false}) {
    switch (fieldName) {
      case "id":
        model.id = value;
        break;

      default:
        if (errorOnNonExistField) {
          throw 'field "$fieldName" not exist in model "$className"';
        }
        break;
    }
  }

  /// mark [model] as [deleted], to support soft-delete
  void markDeleted(M model, bool deleted) {
    var clz = meta(getClassName(model))!;
    var softDeleteField = clz.softDeleteField;
    if (softDeleteField == null) {
      return;
    }
    setFieldValue(model, softDeleteField.name, deleted);
    _helper(model).markDirty(false, true, softDeleteField.name);
  }

  /// load [model] fields with a Map [m]
  void loadModel(M model, Map<String, dynamic> m,
      {errorOnNonExistField = false}) {
    model.loadMap(m, errorOnNonExistField: false);
    var helper = _helper(model);
    helper.storeAttached = true;
    helper.storeLoaded = true;
    helper.cleanDirty();
  }

  /// mark [model] has been loaded from DB.
  void markLoaded(M model) {
    _helper(model).markLoaded(true);
  }

  /// mark [model] has been attached with DB.
  void markAttached(M model, {ModelQuery? topQuery}) {
    _helper(model).markAttached(true, topQuery: topQuery);
  }

  bool isStoreLoaded(M model) => _helper(model).storeLoaded;

  /// ensure [model] is loaded
  void ensureLoaded(M model) {
    _helper(model).ensureLoaded();
  }

  /// mark [model] field [fieldName] is dirty when necessary.
  void markDirty(
      M model, String fieldName, Object? oldValue, Object? newValue) {
    _helper(model).markDirty(oldValue, newValue, fieldName);
  }

  /// convert a [model] to a map
  Map<String, dynamic> toMap(M model,
      {String fields = '*',
      bool ignoreNull = true,
      Map<String, dynamic>? map}) {
    var filter = FieldFilter(fields, idFields(className)![0].columnName);
    var map2 = map ??= <String, dynamic>{};

    allFields(className, searchParents: true)
        ?.where((field) => filter.contains(field.name))
        .forEach((field) {
      var name = field.name;
      var value = getFieldValue(model, name);

      if (value is DateTime) {
        value = value.toIso8601String();
      } else if (value is Model) {
        value =
            value.toMap(fields: filter.subFilter(name), ignoreNull: ignoreNull);
      } else if (value is List) {
        value = value.map((e) {
          if (e is Model) {
            return e.toMap(
                fields: filter.subFilter(name), ignoreNull: ignoreNull);
          } else {
            return e;
          }
        }).toList();
      }
      if (ignoreNull) {
        value != null ? map2[name] = value : "";
      } else {
        map2[name] = value;
      }
    });
    return map2;
  }

  /// set current user by [Needle.currentUser]
  void setCurrentUser(M model, {bool insert = false, bool update = false}) {
    if (Needle.currentUser == null) {
      return;
    }
    if (!insert && !update) {
      return;
    }
    dynamic current = Needle.currentUser!.call();

    if (insert) {
      allFields(className, searchParents: true)
          ?.where((field) =>
              field.ormAnnotations.any((annot) => annot is WhoCreated))
          .forEach((field) {
        setFieldValue(model, field.name, current);
      });
    }

    if (update) {
      allFields(className, searchParents: true)
          ?.where((field) =>
              field.ormAnnotations.any((annot) => annot is WhoModified))
          .forEach((field) {
        setFieldValue(model, field.name, current);
      });
    }
  }

  void postLoad(M model) {}
  void prePersist(M model) {}
  void postPersist(M model) {}
  void preUpdate(M model) {}
  void postUpdate(M model) {}
  void preRemove(M model) {}
  void postRemove(M model) {}
  void preRemovePermanent(M model) {}
  void postRemovePermanent(M model) {}
}

/// support toMap(fields:'*'), toMap(fields:'name,price,author(*),editor(name,email)')
class FieldFilter {
  final String fields;
  final String? idField;

  List<String> _fieldList = [];

  List<String> get fieldList => List.of(_fieldList);

  FieldFilter(this.fields, this.idField) {
    _fieldList = _parseFields();
  }

  bool contains(String field) {
    if (shouldIncludeIdFields()) {
      if (field == idField) {
        return true;
      }
    }
    return fieldList.any(
        (name) => name == '*' || name == field || name.startsWith('$field('));
  }

  bool shouldIncludeIdFields() {
    return fields.trim().isEmpty;
  }

  String subFilter(String field) {
    List<String> subList = fieldList
        .where((name) => name == field || name.startsWith('$field('))
        .toList();
    if (subList.isEmpty) {
      return '';
    }
    var str = subList.first;
    int i = str.indexOf('(');
    if (i != -1) {
      return str.substring(i + 1, str.length - 1);
    }
    return '';
  }

  List<String> _parseFields() {
    var result = <String>[];
    var str = fields.trim().replaceAll(' ', '');
    int j = 0;
    for (int i = 1; i < str.length; i++) {
      if (str[i] == ',') {
        result.add(str.substring(j, i));
        j = i + 1;
      } else if (str[i] == '(') {
        int k = _readTillParenthesisEnd(str, i + 1);
        if (k == -1) {
          throw '( and ) do NOT match';
        }
        i = k;
      }
    }
    if (j < str.length) {
      result.add(str.substring(j));
    }
    return result;
  }

  int _readTillParenthesisEnd(String str, int index) {
    int left = 1;
    for (; index < str.length; index++) {
      if (str[index] == ')') {
        left--;
      } else if (str[index] == '(') {
        left++;
      }
      if (left == 0) {
        return index;
      }
    }
    return -1;
  }
}
