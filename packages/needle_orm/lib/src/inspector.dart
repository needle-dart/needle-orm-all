import 'meta.dart';
import 'query.dart';
import 'sql.dart';

/// an Inspector to spy and operate on model objects
abstract class ModelInspector<M> {
  /// return the class name of [model]
  String getClassName(M model);

  /// create a new instance of specified [className]
  M newInstance(String className,
      {bool attachDb = false, required BaseModelQuery topQuery});

  BaseModelQuery newQuery(Database db, String className);

  /// return class meta info for [className]
  OrmMetaClass? meta(String className);

  /// all known classes
  List<OrmMetaClass> get allOrmMetaClasses;

  /// return modified fields of [model] as a Map
  Map<String, dynamic> getDirtyFields(M model);

  /// return the value of [model].[fieldName]
  dynamic getFieldValue(M model, String fieldName);

  /// set the value of [model].[fieldName] as [value]
  void setFieldValue(M model, String fieldName, dynamic value);

  /// mark [model] as [deleted], to support soft-delete
  void markDeleted(M model, bool deleted);

  /// load [model] fields with a Map [m]
  void loadModel(M model, Map<String, dynamic> m,
      {errorOnNonExistField = false});

  /// check whether a [type] is a model name.
  bool isModelType(String type) {
    if (type.endsWith('?')) {
      type = type.substring(0, type.length - 1);
    }
    return meta(type) != null;
  }

  /// return id fields of [className]
  List<OrmMetaField>? idFields(String className) {
    return meta(className)?.idFields;
  }

  /// return soft-delete field of [className]
  List<OrmMetaField>? softDeleteField(String className) {
    return meta(className)?.idFields;
  }

  /// mark [model] has been loaded from DB.
  void markLoaded(M model);
}
