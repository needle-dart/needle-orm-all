import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm_generator/src/common.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';

class NeedleOrmInspectorGenerator extends Generator {
  const NeedleOrmInspectorGenerator();

  TypeChecker get typeChecker => TypeChecker.fromRuntime(OrmAnnotation);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    final all = <String>{};

    var elements = library.annotatedWith(typeChecker);
    if (elements.isEmpty) {
      return '';
    }

    values.add(toBool);

    var classes =
        elements.map((e) => e.element).whereType<ClassElement>().toList();

    for (var clz in classes) {
      var classGen = _InspectoroGenerator(clz);
      values.add(classGen.generate());
      all.add('${classGen.inspectorClassName}()');
    }

    values
        .add('final _allModelInspectors = <ModelInspector>[${all.join(',')}];');

    values.add("""
      initNeedle() {
        Needle.registerAll(_allModelInspectors);
        Needle.registerAllMetaClasses(_allModelMetaClasses);
      }
      """);
    return values.join('\n\n');
  }
}

/// generator for meta classes
class _InspectoroGenerator {
  final ClassElement clazz;
  String name;
  String get inspectorClassName => '_${name}ModelInspector';
  bool isAbstract;
  String superClassName;

  _InspectoroGenerator(this.clazz)
      : name = clazz.name.removePrefix(),
        isAbstract = clazz.isAbstract,
        superClassName = clazz.supertype?.element.name.removePrefix() ?? '';

  String generate() {
    var fields =
        _FieldGenerator(clazz.isAbstract ? "T" : name, clazz.fields).generate();
    var methods = clazz.methods
        .map((e) => _MethodGenerator(name, e).generate())
        .join('\n');

    var isAbstract = clazz.isAbstract;
    var strNewInstance = isAbstract
        ? """
          @override
          T newInstance(
              {bool attachDb = false, id}) {
            throw UnimplementedError();
          }
          """
        : """
            @override
              $name newInstance(
                  {bool attachDb = false, id}) {
                var m = $name();
                m.id = id;
                initInstance(m);
                m._modelInspector.markAttached(m);
                return m;
              }
          """;

    /* var strNewQuery = clazz.isAbstract
        ? ""
        : """
          @override
            ${name}Query newQuery(Database db, String className) {
              return ${name}Query(db: db);
            }
          """; */

    var defClass = """
          class $inspectorClassName${isAbstract ? '<T extends $name>' : ''} extends ${superClassName == 'Model' ? 'ModelInspector' : '_${superClassName}ModelInspector'}<${isAbstract ? 'T' : name}>
          """;
    return '''
      $defClass {

          @override
          String get className => "$name";

          $strNewInstance

          $fields

          $methods
      }
      ''';
  }

  bool isOneToMany(FieldElement field) {
    return field.metadata
        .where((annot) => annot.name == 'OneToMany')
        .isNotEmpty;
  }

}

/// generator for fields meta info.
class _FieldGenerator {
  final String className;
  final List<FieldElement> fields;
  final List<String> names;
  _FieldGenerator(this.className, this.fields)
      : names = fields.map((f) => f.name.removePrefix()).toList();

  String generate() {
    return '''
      ${genGetFieldValue()}
      
      ${genSetFieldValue()}
      ''';
  }

  String genGetFieldValue() {
    var strCase =
        names.map((name) => 'case "$name": return model.$name;').join("\n");
    return """
        @override
        getFieldValue($className model, String fieldName) {
          switch (fieldName) {
            $strCase
            default:
              return super.getFieldValue(model, fieldName);
          }
        }
      """;
  }

  String genSetFieldValue() {
    var strCase = fields.map((f) {
      var name = f.name.removePrefix();
      var type = f.type;
      if (type.isDartCoreBool) {
        return 'case "$name":  model.$name = toBool(value); break;';
      } else {
        return 'case "$name":  model.$name = value; break;';
      }
    }).join("\n");

    return """
        @override
        void setFieldValue($className model, String fieldName, value,
            {errorOnNonExistField = false}) {
          switch (fieldName) {
            $strCase
            default:
              super.setFieldValue(model, fieldName, value,
                  errorOnNonExistField: errorOnNonExistField);
          }
        }
      """;
  }
}

/// generator for fields meta info.
class _MethodGenerator {
  static var supportedAnnots = [
    PrePersist,
    PostPersist,
    PreUpdate,
    PostUpdate,
    PreRemove,
    PostRemove,
    PreRemovePermanent,
    PostRemovePermanent,
    PostLoad,
  ];
  final MethodElement method;
  String className;
  String name;
  _MethodGenerator(this.className, this.method) : name = method.name;

  String generate() {
    var annots = method.metadata.ormTypes().map((annot) => annot.name).toList();

    // print('>> annots: $annots');

    var annots2 = annots
        .where((annotName) =>
            supportedAnnots.any((annot) => annot.toString() == annotName))
        .map((annotName) => methodName(annotName))
        .toList();

    var methods = annots2.map((methodName) => """
        @override
        void ${methodName}($className model) {
          model.${name}();
        }
        """).join('\n');
    return methods;
  }

  String methodName(String annotName) =>
      annotName[0].toLowerCase() + annotName.substring(1);
}
