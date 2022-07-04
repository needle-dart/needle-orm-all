import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';

/// generator model parital file.
class NeedleOrmModelGenerator extends GeneratorForAnnotation<Entity> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw 'The top @OrmAnnotation() annotation can only be applied to classes.';
    }
    return ClassInspector(element, annotation).generate();
  }
}

class FieldInspector {
  final FieldElement fieldElement;
  String name;
  bool isId = false;
  List<OrmAnnotation> ormAnnotations = [];

  FieldInspector(this.fieldElement) : name = fieldElement.name.removePrefix() {
    handleAnnotations(fieldElement);
    if (ormAnnotations.whereType<ID>().isNotEmpty) {
      isId = true;
    }
  }

  bool get notExistsInDb =>
      ormAnnotations.whereType<ManyToMany>().isNotEmpty ||
      ormAnnotations.whereType<OneToMany>().isNotEmpty ||
      ormAnnotations.whereType<Transient>().isNotEmpty;

  bool get isOneToMany => ormAnnotations.whereType<OneToMany>().isNotEmpty;

  void handleAnnotations(FieldElement ce) {
    ce.metadata.forEach((annot) {
      var name = annot.name;
      switch (name) {
        case 'DbComment':
          ormAnnotations.add(annot.toDbComment());
          break;
        case 'Column':
          ormAnnotations.add(annot.toColumn());
          break;
        case 'ID':
          ormAnnotations.add(ID());
          break;
        case 'Lob':
          ormAnnotations.add(Lob());
          break;
        case 'Version':
          ormAnnotations.add(Version());
          break;
        case 'SoftDelete':
          ormAnnotations.add(SoftDelete());
          break;
        case 'WhenCreated':
          ormAnnotations.add(WhenCreated());
          break;
        case 'WhenModified':
          ormAnnotations.add(WhenModified());
          break;
        case 'WhoCreated':
          ormAnnotations.add(WhoCreated());
          break;
        case 'WhoModified':
          ormAnnotations.add(WhoModified());
          break;
        case 'OneToOne':
          ormAnnotations.add(annot.toOneToOne());
          break;
        case 'OneToMany':
          ormAnnotations.add(annot.toOneToMany());
          break;
        case 'ManyToOne':
          ormAnnotations.add(ManyToOne());
          break;
        case 'ManyToMany':
          ormAnnotations.add(ManyToMany());
          break;
        case 'Transient':
          ormAnnotations.add(Transient());
          break;
      }
    });
  }

  String generate() {
    var lazyOneToManyList = '';
    if (isOneToMany) {
      var oneToMany = ormAnnotations.whereType<OneToMany>().first;
      var fieldName = oneToMany.mappedBy!;
      lazyOneToManyList = '''
        if (__dbAttached && _books==null) {
          var meta = _modelInspector.meta('$_queryCleanType')!;
          var field = meta.fields.firstWhere((f) => f.name=='${fieldName.removePrefix()}');
          _$name = LazyOneToManyList(db: __topQuery!.db, clz: meta, refField:field, refFieldValue: id);
        }
      ''';
    }
    return '''
      $_cleanType _$name ;
      $_cleanType get $name {
        ${isId ? '' : (isOneToMany ? lazyOneToManyList : '__ensureLoaded();')}
        return _$name;
      }
      set $name($_cleanType v) {
        _$name = v;
        ${notExistsInDb ? '' : '__markDirty(\'$name\');'}
      }
    ''';
  }

  String generateColumnQuery() {
    var queryClassName = ColumnQuery.classNameForType(_queryCleanType);
    return '$queryClassName $name = $queryClassName("$name");';
  }

  String generateJoin() {
    var queryClassName = '${_queryCleanType}ModelQuery';
    //@TODO late : prevent cycle dependency, should be removed in later release
    // UserModelQuery get author => topQuery.findQuery('User');
    return '$queryClassName get $name => topQuery.findQuery(db, "$_queryCleanType","$name");';
  }

  static List<String> simpleTypes = [
    'int',
    'double',
    'bool',
    'String',
    'DateTime'
  ];

  bool get _isSimpleType => simpleTypes.indexOf(_queryCleanType) >= 0;

  String get _cleanType =>
      fieldElement.type.toString().replaceAll(RegExp('_'), '');

  String get _queryCleanType =>
      fieldElement.type.toString().replaceAll(RegExp('(List)|[<>_?]+'), '');
}

class ClassInspector {
  final ClassElement classElement;
  String name;

  late String tableName;
  ClassElement? superClassElement;
  String? superClassName;
  List<OrmAnnotation> ormAnnotations = [];
  late Entity entity;

  bool isTopClass = true;
  List<FieldElement> fields = [];

  ClassInspector(this.classElement, ConstantReader annotation)
      : name = classElement.name.removePrefix() {
    if (classElement.supertype != null &&
        classElement.supertype!.element.name != 'Object') {
      superClassElement = classElement.supertype!.element;
      superClassName = superClassElement!.name.removePrefix();
      isTopClass = false;
    }

    handleAnnotations(this.classElement);

    this.entity = this.ormAnnotations.whereType<Entity>().first;

    tableName = name.toLowerCase();
  }

  void handleAnnotations(ClassElement ce) {
    ce.metadata.forEach((annot) {
      var name = annot.name;
      switch (name) {
        case 'Entity':
          ormAnnotations.add(annot.toEntity());
          break;
      }
    });
  }

  String generate() {
    var fields =
        classElement.fields.map((f) => FieldInspector(f).generate()).join('\n');

    var _superClassName = isTopClass ? "__Model" : superClassName;

    var _abstract = classElement.isAbstract ? "abstract" : "";
    return '''
    ${genModelQuery()}

    $_abstract class $name extends $_superClassName { 

      $fields

      $name(); 

      @override String get __className => '$name';

      static ${name}ModelQuery query({Database? db}) => ${name}ModelQuery(db: db);

      ${overrideGetField(classElement)}
      ${overrideSetField(classElement)}

      ${overrideToMap(classElement)}

      // @override
      // String get __tableName {
      //   return "$tableName";
      // }

      @override
      String? get __idFieldName{
        return "id";
      }

      ${overrideprePersist()}
      ${overridepreUpdate()}
      ${overridepreRemove()}
      ${overridepreRemovePermanent()}
      ${overridepostPersist()}
      ${overridepostUpdate()}
      ${overridepostRemove()}
      ${overridepostRemovePermanent()}
      ${overridepostLoad()}

    }''';
  }

  String genModelQuery() {
    var _fields = classElement.fields.map((f) => FieldInspector(f));

    var fields = _fields
        .map(
            (f) => f._isSimpleType ? f.generateColumnQuery() : f.generateJoin())
        .join('\n');

    var columns =
        _fields.where((f) => f._isSimpleType).map((e) => e.name).join(',');

    var joins =
        _fields.where((f) => !f._isSimpleType).map((e) => e.name).join(',');

    var queryClassName = name == 'BaseModel'
        ? 'BaseModelModelQuery<T extends BaseModel>'
        : '${name}ModelQuery';
    var queryExtendsClass = name == 'BaseModel'
        ? '_BaseModelQuery<T, int>'
        : 'BaseModelModelQuery<$name>';

    return '''
      class $queryClassName extends $queryExtendsClass {
        @override
        String get className => '$name';

        ${name}ModelQuery(
          // ignore: library_private_types_in_public_api
          {_BaseModelQuery? topQuery, String? propName, Database? db})
          : super(topQuery: topQuery, propName: propName, db:db);

        $fields

        @override
        List<ColumnQuery> get columns => [$columns];

        @override
        List<BaseModelQuery> get joins => [$joins];

      }
      ''';
  }

  String overrideEvent(String eventType, String eventHandler) {
    return '''
      @override void __${eventType}() {
        ${eventHandler}();
      }
      ''';
  }

  String overridepostLoad() {
    if (entity.postLoad == null) {
      return '';
    }
    return overrideEvent('postLoad', entity.postLoad!);
  }

  String overrideprePersist() {
    if (entity.prePersist == null) {
      return '';
    }
    return overrideEvent('prePersist', entity.prePersist!);
  }

  String overridepostPersist() {
    if (entity.postPersist == null) {
      return '';
    }
    return overrideEvent('postPersist', entity.postPersist!);
  }

  String overridepreUpdate() {
    if (entity.preUpdate == null) {
      return '';
    }
    return overrideEvent('preUpdate', entity.preUpdate!);
  }

  String overridepostUpdate() {
    if (entity.postUpdate == null) {
      return '';
    }
    return overrideEvent('postUpdate', entity.postUpdate!);
  }

  String overridepreRemove() {
    if (entity.preRemove == null) {
      return '';
    }
    return overrideEvent('preRemove', entity.preRemove!);
  }

  String overridepostRemove() {
    if (entity.postRemove == null) {
      return '';
    }
    return overrideEvent('postRemove', entity.postRemove!);
  }

  String overridepreRemovePermanent() {
    if (entity.preRemovePermanent == null) {
      return '';
    }
    return overrideEvent('preRemovePermanent', entity.preRemovePermanent!);
  }

  String overridepostRemovePermanent() {
    if (entity.postRemovePermanent == null) {
      return '';
    }
    return overrideEvent('postRemovePermanent', entity.postRemovePermanent!);
  }

  String overrideGetField(ClassElement clazz) {
    var defaultStmt = isTopClass
        ? "if(errorOnNonExistField){ throw 'class ${clazz.name} has now such field: \$fieldName'; }"
        : "return super.__getField(fieldName, errorOnNonExistField:errorOnNonExistField);";
    return '''
      @override
      dynamic __getField(String fieldName, {errorOnNonExistField = true}) {
        switch (fieldName) {
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": return _${e.name.removePrefix()};').join('\n')} 
          default: $defaultStmt
        }
      }''';
  }

  String overrideSetField(ClassElement clazz) {
    var defaultStmt = isTopClass
        ? "if(errorOnNonExistField){ throw 'class ${clazz.name} has now such field: \$fieldName'; }"
        : "super.__setField(fieldName, value, errorOnNonExistField:errorOnNonExistField );";

    var normalField = 'value';
    var boolField =
        'value is bool ? value : ( 0==value || null==value || ""==value ? false : true )';
    return '''
      @override
      void __setField(String fieldName, dynamic value, {errorOnNonExistField = true}){
        switch (fieldName) {
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": ${e.name.removePrefix()} = ${e.type.isDartCoreBool ? boolField : normalField}; break;').join('\n')} 
          default: $defaultStmt
        }
      }''';
  }

  TypeChecker tsChecker = TypeChecker.fromRuntime(DateTime);

  String _toMap(FieldElement field) {
    var name = field.name.removePrefix();
    return '''if (filter.contains('${name}'))  "${name}": ${_toMapValue(field)},''';
  }

  String _toNonNullMap(FieldElement field) {
    var name = field.name.removePrefix();
    return '$name!=null && filter.contains("${name}") ? m["$name"] = ${_toMapValue(field)} : "" ;';
  }

  String _toMapValue(FieldElement field) {
    var isDate = field.type.toString().startsWith("DateTime");
    var toStr = isDate
        ? '?.toIso8601String()'
        : isModel(field)
            ? '?.toMap(fields: filter.subFilter("${field.name.removePrefix()}"), ignoreNull:ignoreNull)'
            : '';
    return '${field.name.removePrefix()}$toStr';
  }

  bool isModel(FieldElement field) {
    return field.metadata.ormAnnotations().whereType<ManyToOne>().isNotEmpty ||
        field.metadata.ormAnnotations().whereType<OneToOne>().isNotEmpty;
  }

  String overrideToMap(ClassElement clazz) {
    var superStmt = isTopClass
        ? ""
        : "...super.toMap(fields:fields, ignoreNull: ignoreNull),";
    return '''
      @override
        Map<String, dynamic> toMap({String fields = '*', bool ignoreNull = true}) {
          var filter = FieldFilter(fields, __idFieldName);
          if (ignoreNull) {
            var m = <String, dynamic>{};
            ${clazz.fields.map(_toNonNullMap).join('\n')} 
            ${name == 'BaseModel' ? '' : 'm.addAll(super.toMap(fields:fields, ignoreNull: true));'}
            return m;
          }
          return {
            ${clazz.fields.map(_toMap).join('\n')} 
            ${superStmt}
          };
        }''';
  }
}
