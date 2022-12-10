import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';

class NeedleOrmImplGenerator extends Generator {
  const NeedleOrmImplGenerator();

  TypeChecker get typeChecker => TypeChecker.fromRuntime(OrmAnnotation);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    var elements = library.annotatedWith(typeChecker);
    if (elements.isEmpty) {
      return '';
    }

    var classes =
        elements.map((e) => e.element).whereType<ClassElement>().toList();

    return classes.map((clz) => _ImplGenerator(clz).generate()).join('\n\n');
  }
}

/// generator for meta classes
class _ImplGenerator {
  final ClassElement clazz;
  String name;

  _ImplGenerator(this.clazz) : name = clazz.name.removePrefix();

  String generate() {
    var fields = _FieldGenerator(clazz.fields).generate();

    return '''
      extension ${name}Impl on $name {

        ModelInspector<${name}> get _modelInspector => ModelInspector.lookup("${name}");

        $fields
      }
      ''';
  }
}

/// generator for fields meta info.
class _FieldGenerator {
  final List<FieldElement> fields;
  final List<String> names;
  _FieldGenerator(this.fields)
      : names = fields.map((f) => f.name.removePrefix()).toList();

  String generate() {
    return fields.map((f) {
      var name = f.name.removePrefix();
      var type = f.type.toString();

      return genGet(name, type) + genSet(name, type);
    }).join();
  }

  String genGet(String name, String type) {
    return """
        $type get $name {
          _modelInspector.ensureLoaded(this);
          return _$name;
        }
      """;
  }

  String genSet(String name, String type) {
    return """
        set $name($type v) {
          _modelInspector.markDirty(this, '$name', _$name, v);
          _$name = v;
        }
      """;
  }
}
