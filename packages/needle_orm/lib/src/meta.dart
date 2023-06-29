import 'api.dart';
import 'inspector.dart';

import 'package:recase/recase.dart';
import 'package:inflection3/inflection3.dart';

/// Orm meta class, used by generator
class OrmMetaClass {
  final String name;
  final String? superClassName;
  final bool isAbstract;
  final List<OrmAnnotation> ormAnnotations;
  final List<OrmMetaField> fields;
  final List<OrmMetaMethod> methods;
  // final ModelInspector modelInspector;

  String? _tableName;

  OrmMetaClass(this.name,
      {this.superClassName,
      this.isAbstract = false,
      this.ormAnnotations = const [],
      this.fields = const [],
      this.methods = const []}) {
    for (var f in fields) {
      f.clz = this;
    }
    var tables = ormAnnotations.whereType<Table>();
    if (tables.isNotEmpty) {
      _tableName = tables.first.name;
    }
    _tableName = _tableName ?? _getTableName(name);
  }

  String get tableName => _tableName!;

  String _getTableName(String className) {
    return pluralize(ReCase(className).snakeCase);
  }

  List<OrmMetaField> allFields({bool searchParents = false}) {
    var parentClz =
        superClassName == null ? null : ModelInspector.meta(superClassName!);
    return [
      ...fields,
      if (searchParents && parentClz != null)
        ...parentClz.allFields(searchParents: searchParents)
    ];
  }

  OrmMetaField? findField(String name) {
    if (fields.any((element) => element.name == name)) {
      return fields.where((element) => element.name == name).first;
    }
    if (superClassName != null) {
      var parentClz = ModelInspector.meta(superClassName!);
      return parentClz?.findField(name);
    }
    return null;
  }

/*   List<OrmMetaField> get idFields => allFields(searchParents: true)
      .where((f) => f.ormAnnotations.any((annot) => annot.runtimeType == ID))
      .toList();
 */
  List<OrmMetaField> get idFields => [idField];

  static OrmMetaField idField = OrmMetaField('id', 'int', ormAnnotations: [
    ID(),
  ]);

  OrmMetaField? get softDeleteField =>
      allFields(searchParents: true).firstWhere((f) =>
          f.ormAnnotations.any((annot) => annot.runtimeType == SoftDelete));

  OrmMetaField? get versionField => allFields(searchParents: true).firstWhere(
      (f) => f.ormAnnotations.any((annot) => annot.runtimeType == Version));

  OrmMetaField? get whenModifiedField =>
      allFields(searchParents: true).firstWhere((f) =>
          f.ormAnnotations.any((annot) => annot.runtimeType == WhenModified));

  List<OrmMetaField> serverSideFields(ActionType actionType,
      {bool searchParents = false}) {
    var fields = allFields(searchParents: false)
        .where((element) => element.ormAnnotations
            .any((element) => element.isServerSide(actionType)))
        .toList();

    if (searchParents && superClassName != null) {
      var superClz = ModelInspector.meta(superClassName!);
      if (superClz == null) return fields;
      return [
        ...fields,
        ...superClz.serverSideFields(actionType, searchParents: searchParents)
      ];
    }
    return fields;
  }
}

/// orm meta field , used by generator
class OrmMetaField {
  final String name;
  final String type;
  final List<OrmAnnotation> ormAnnotations;

  late OrmMetaClass clz;
  OrmMetaField(this.name, this.type, {this.ormAnnotations = const []});

  bool get isModelType => ModelInspector.isModelType(elementType);

  bool get isIdField => ormAnnotations.whereType<ID>().isNotEmpty;

  bool get notExistsInDb =>
      ormAnnotations.whereType<ManyToMany>().isNotEmpty ||
      ormAnnotations.whereType<OneToMany>().isNotEmpty ||
      ormAnnotations.whereType<Transient>().isNotEmpty;

  String get elementType {
    var t = type;
    if (t.startsWith('List<')) {
      t = t.substring(5, t.length - 1);
    }
    if (t.startsWith('Set<')) {
      t = t.substring(4, t.length - 1);
    }
    if (t.endsWith('?')) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  String get columnName {
    var s = ReCase(name).snakeCase;
    if (isModelType) s += '_id';
    return s;
  }
}

/// orm meta method , used by generator
class OrmMetaMethod {
  final String name;
  final List<OrmAnnotation> ormAnnotations;

  late OrmMetaClass clz;
  OrmMetaMethod(this.name, {this.ormAnnotations = const []});
}
