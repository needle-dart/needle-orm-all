import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_generator/src/common.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';

class NeedleOrmMetaInfoGenerator extends Generator {
  const NeedleOrmMetaInfoGenerator();

  TypeChecker get typeChecker => TypeChecker.fromRuntime(OrmAnnotation);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    final all = <String>{};

    var elements = library.annotatedWith(typeChecker);
    if (elements.isEmpty) {
      return '';
    }

    var classes =
        elements.map((e) => e.element).whereType<ClassElement>().toList();

    values.add(strModel);
    values.add(strModelCache);
    values.add(strFieldFilter);
    values.add(strBaseQuery);
    values.add(strModelInspector(classes
        .where((element) => !element.isAbstract)
        .map((e) => e.name.removePrefix())));

    for (var clz in classes) {
      var classGen = ClassMetaInfoGenerator(clz);
      values.add(classGen.generate());
      all.add('${classGen.metaClassName}()');
    }

    values.add('final _allOrmClasses = [${all.join(',')}];');

    return values.join('\n\n');
  }
}

/// generator for meta classes
class ClassMetaInfoGenerator {
  final ClassElement clazz;
  String name;
  String get metaClassName => 'OrmMetaInfo$name';
  bool isAbstract;
  String superClassName;

  ClassMetaInfoGenerator(this.clazz)
      : name = clazz.name.removePrefix(),
        isAbstract = clazz.isAbstract,
        superClassName = clazz.supertype?.element.name.removePrefix() ?? '';

  String generate() {
    var fields = clazz.fields
        .map((e) => FieldMetaInfoGenerator(e).generate() + ',')
        .join('\n');
    var annots = clazz.metadata
        .ormTypes()
        .map((e) => e.toSource().substring(1) + ',')
        .join('\n');
    return '''
      class $metaClassName extends OrmMetaClass {
        $metaClassName()
            : super('$name', _modelInspector,
                  isAbstract: $isAbstract,
                  superClassName: '$superClassName',
                  ormAnnotations: [
                    $annots
                  ],
                  fields: [
                    $fields
                  ]);
      }
      ''';
  }
}

/// generator for fields meta info.
class FieldMetaInfoGenerator {
  final FieldElement field;
  String name;
  String type;
  FieldMetaInfoGenerator(this.field)
      : name = field.name.removePrefix(),
        type = field.type.toString();

  String generate() {
    var annots = field.metadata
        .ormTypes()
        .map((e) => e.toSource().substring(1) + ',')
        .join('\n');
    return '''
      OrmMetaField('$name', '${type.removePrefix()}', ormAnnotations: [
                $annots
              ])
      ''';
  }
}
