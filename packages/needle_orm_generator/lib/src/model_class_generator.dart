import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm/impl.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';
import 'package:recase/recase.dart';

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

  bool get isTransient => ormAnnotations.whereType<Transient>().isNotEmpty;

  bool get isOneToMany => ormAnnotations.whereType<OneToMany>().isNotEmpty;

  void handleAnnotations(FieldElement ce) {
    ce.metadata.forEach((annot) {
      var name = annot.name;
      switch (name) {
        case 'Comment':
          ormAnnotations.add(annot.toComment());
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
        if (__dbAttached && _$name == null) {
          var meta = _modelInspector.meta('$_queryCleanType')!;
          var field = meta.fields.firstWhere((f) => f.name=='${fieldName.removePrefix()}');
          _$name = LazyOneToManyList(clz: meta, refField:field, refFieldValue: id);
        }
      ''';
    }
    return '''
      $_cleanType _$name ;
      ${isTransient ? '// ignore: unnecessary_getters_setters\n' : ''}$_cleanType get $name {
        ${isId ? '' : (isOneToMany ? lazyOneToManyList : isTransient ? '' : '__ensureLoaded();')}
        return _$name;
      }
      set $name($_cleanType v) {
        ${notExistsInDb ? '' : '__markDirty(_$name , v , \'$name\');'}
        _$name = v;
      }
    ''';
  }

  String generateColumnQuery() {
    var queryClassName = ColumnQuery.classNameForType(_queryCleanType);
    if (_isSimpleType) {
      return '$queryClassName get $name => $queryClassName(this, "$name");';
    } else {
      var strJoinRelation = '..joinRelation=JoinRelation()';
      if (isOneToMany) {
        var oneToMany = ormAnnotations.whereType<OneToMany>().first;
        strJoinRelation =
            '..joinRelation=JoinRelation(JoinKind.oneToMany,"${oneToMany.mappedBy}")';
      }
      return '${_queryCleanType}Column get $name => ${_queryCleanType}Column(this, "$name")$strJoinRelation;';
    }
  }

  String getColumnName(String fieldName) {
    return ReCase(fieldName).snakeCase;
  }

  String generateJoin() {
    var queryClassName = '${_queryCleanType}Query';
    //@TODO late : prevent cycle dependency, should be removed in later release
    // UserModelQuery get author => topQuery.findQuery('User');
    return '$queryClassName get $name => topQuery.findQuery(db, className ,"$name","$_queryCleanType");';
  }

  static List<String> simpleTypes = [
    'int',
    'double',
    'bool',
    'String',
    'List<int>',
    'DateTime'
  ];

  bool get _isSimpleType => simpleTypes.contains(_queryCleanType);

  String get _cleanType =>
      fieldElement.type.toString().replaceAll(RegExp('_'), '');

  String get _queryCleanType {
    var t = fieldElement.type.toString().replaceAll('?', '');
    if (simpleTypes.contains(t)) {
      return t;
    }
    return t.replaceAll(RegExp('(^List)|[<>_?]+'), '');
  }
}

class SuperClassInfo {
  final ClassElement superClassElement;
  final String superClassName;
  SuperClassInfo(this.superClassElement, this.superClassName);

  static SuperClassInfo? of(ClassElement ce) {
    if (ce.supertype != null && ce.supertype!.element.name != 'Object') {
      return SuperClassInfo(ce.supertype!.element as ClassElement,
          ce.supertype!.element.name.removePrefix());
    }
    return null;
  }

  static List<SuperClassInfo> chainOf(ClassElement ce) {
    var list = <SuperClassInfo>[];
    var sci = of(ce);
    while (sci != null) {
      list.add(sci);
      sci = of(sci.superClassElement);
    }
    return list;
  }
}

class ClassInspector {
  final ClassElement classElement;
  String name;

  late String tableName;
  ClassElement? superClassElement;
  String? superClassName;
  List<OrmAnnotation> ormAnnotations = [];
  late Entity entity;
  List<SuperClassInfo> superClassChain = [];

  bool isTopClass = true;
  List<FieldElement> fields = [];
  List<MethodElement> methods = [];

  ClassInspector(this.classElement, ConstantReader annotation)
      : name = classElement.name.removePrefix() {
    if (classElement.supertype != null &&
        classElement.supertype!.element.name != 'Object') {
      superClassElement = classElement.supertype!.element as ClassElement;
      superClassName = superClassElement!.name.removePrefix();
      isTopClass = false;

      superClassChain = SuperClassInfo.chainOf(classElement);
    }

    handleAnnotations(this.classElement);

    this.entity = this.ormAnnotations.whereType<Entity>().first;

    this.fields = classElement.fields;
    this.methods = classElement.methods;

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

  MethodElement? findAnnotatedMethod<T extends OrmAnnotation>() {
    var list = methods
        .where((element) =>
            element.metadata.ormAnnotations().whereType<T>().isNotEmpty)
        .toList();
    if (list.isEmpty) {
      return null;
    }
    return list.first;
  }

  String generate() {
    return [genMixin(), genColumnClass(), genQueryClass()].join('\n');
  }

  String genMixin() {
    var isAbstract = classElement.isAbstract;
    var def = isAbstract
        ? 'mixin ${name}Mixin<T> on TableQuery<T>'
        : 'mixin ${name}Mixin on TableQuery<${name}> ';
    var _fields = classElement.fields.map((f) => FieldInspector(f));
    var fields = _fields
        .map((f) => f.isTransient ? '' : f.generateColumnQuery())
        .join('\n');

    return '''
$def {
  $fields
}
''';
  }

  String genColumnClass() {
    var superMins =
        superClassChain.map((e) => '${e.superClassName}Mixin').join(', ');
    return '''
      class ${name}Column extends TableQuery<${name}>
          with $superMins, ${name}Mixin {
        ${name}Column(super.owner, super.name);
      }
  ''';
  }

  String genQueryClass() {
    var superMins =
        superClassChain.map((e) => '${e.superClassName}Mixin').join(', ');
    return '''
class ${name}Query extends TopTableQuery<${name}>
    with $superMins, ${name}Mixin {
  ${name}Query({super.db});
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
    var method = findAnnotatedMethod<PostLoad>();
    if (method == null) {
      return '';
    }
    return overrideEvent('postLoad', method.name);
  }

  String overrideprePersist() {
    var method = findAnnotatedMethod<PrePersist>();
    if (method == null) {
      return '';
    }
    return overrideEvent('prePersist', method.name);
  }

  String overridepostPersist() {
    var method = findAnnotatedMethod<PostPersist>();
    if (method == null) {
      return '';
    }
    return overrideEvent('postPersist', method.name);
  }

  String overridepreUpdate() {
    var method = findAnnotatedMethod<PreUpdate>();
    if (method == null) {
      return '';
    }
    return overrideEvent('preUpdate', method.name);
  }

  String overridepostUpdate() {
    var method = findAnnotatedMethod<PostUpdate>();
    if (method == null) {
      return '';
    }
    return overrideEvent('postUpdate', method.name);
  }

  String overridepreRemove() {
    var method = findAnnotatedMethod<PreRemove>();
    if (method == null) {
      return '';
    }
    return overrideEvent('preRemove', method.name);
  }

  String overridepostRemove() {
    var method = findAnnotatedMethod<PostRemove>();
    if (method == null) {
      return '';
    }
    return overrideEvent('postRemove', method.name);
  }

  String overridepreRemovePermanent() {
    var method = findAnnotatedMethod<PostRemove>();
    if (method == null) {
      return '';
    }
    return overrideEvent('preRemovePermanent', method.name);
  }

  String overridepostRemovePermanent() {
    var method = findAnnotatedMethod<PostRemove>();
    if (method == null) {
      return '';
    }
    return overrideEvent('postRemovePermanent', method.name);
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
          var filter = _FieldFilter(fields, __idFieldName);
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
