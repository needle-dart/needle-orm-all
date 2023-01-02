import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:inflection3/inflection3.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm_migration/needle_orm_migration.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';

class NeedleOrmMigrationGenerator extends Generator {
  const NeedleOrmMigrationGenerator();

  TypeChecker get typeChecker => TypeChecker.fromRuntime(OrmAnnotation);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>[];

    var elements = library.annotatedWith(typeChecker);
    if (elements.isEmpty) {
      return '';
    }

    var classes = elements.map((e) => e.element).whereType<ClassElement>();
    final allMigrations = <String>[];
    for (var clz in classes) {
      if (clz.isAbstract) {
        continue;
      }
      var classGen = ClassMigrationGenerator(clz, classes);
      values.add(classGen.generate());
      allMigrations.add(classGen.migrationInstance);
    }

    if (allMigrations.isNotEmpty) {
      values.add(
          'final allMigrations = <Migration>[${allMigrations.join(',')}];');
    }

    return values.join('\n\n');
  }
}

String getTableName(String className) {
  return pluralize(ReCase(className).snakeCase);
}

String getColumnName(String fieldName) {
  return ReCase(fieldName).snakeCase;
}

TypeChecker get idTypeChecker => TypeChecker.fromRuntime(ID);

extension IDChecker on FieldElement {
  bool isID() {
    return this.metadata.any((annot) =>
        idTypeChecker.isAssignableFrom(annot.element!.enclosingElement!));
  }
}

class ClassMigrationGenerator {
  final ClassElement clazz;
  final Iterable<ClassElement> allClasses;
  String name;

  ClassMigrationGenerator(this.clazz, this.allClasses)
      : name = clazz.name.removePrefix();

  List<FieldElement> getAllFields(ClassElement clz) {
    var superClass = clz.supertype?.element as ClassElement?;
    if (superClass != null && allClasses.contains(superClass)) {
      return [...clz.fields, ...getAllFields(superClass)];
    } else {
      return clz.fields;
    }
  }

  String get migrationInstance => '_${name}Migration()';

  String generate() {
    var tableName = getTableName(name);

    var allFields = getAllFields(clazz);

    var fields = allFields.map((e) => ColumnGenerator(e).generate()).join('\n');

    return '''
      class _${name}Migration extends Migration {
        @override
        void up(Schema schema) {
          schema.create('$tableName', (table) {
            table.serial('id');
            
            $fields
          });
        }

        @override
        void down(Schema schema) {
          schema.drop('$tableName');
        }
      }
      ''';
  }
}

class ColumnGenerator {
  final FieldElement field;
  String name;
  ColumnGenerator(this.field) : name = field.name.removePrefix();

  String generate() {
    if (shouldIgnore(field)) {
      return '';
    }
    var columnType = inferColumnType(field);
    var columnName = getColumnName(name);
    if (isModel(field)) {
      columnName += '_id';
      columnType = ColumnType.bigInt;
    }
    var columnMethodName = field.isID() ? 'serial' : methodName(columnType);
    var lengthParam = columnMethodName == 'varChar' && columnLength() > 0
        ? ', length: ${columnLength()}'
        : '';
    return '''
      table.$columnMethodName('$columnName'$lengthParam);
      ''';
  }

  bool isModel(FieldElement field) {
    return field.metadata.ormAnnotations().whereType<ManyToOne>().isNotEmpty ||
        field.metadata.ormAnnotations().whereType<OneToOne>().isNotEmpty;
  }

  bool shouldIgnore(FieldElement field) {
    return field.metadata.ormAnnotations().whereType<ManyToMany>().isNotEmpty ||
        field.metadata.ormAnnotations().whereType<OneToMany>().isNotEmpty ||
        field.metadata.ormAnnotations().whereType<Transient>().isNotEmpty;
  }

  int columnLength() {
    var columns = field.metadata.ormAnnotations().whereType<Column>().toList();
    if (columns.isEmpty) {
      return 0;
    }
    return columns[0].length;
  }

  String methodName(ColumnType type) {
    var methodName;
    switch (type) {
      case ColumnType.varChar:
        methodName = 'varChar';
        // named['length'] = literal(col.length);
        break;
      case ColumnType.serial:
        methodName = 'serial';
        break;
      case ColumnType.bigInt:
        methodName = 'integer';
        break;
      case ColumnType.int:
        methodName = 'integer';
        break;
      case ColumnType.float:
        methodName = 'float';
        break;
      case ColumnType.double:
        methodName = 'float';
        break;
      case ColumnType.decimal:
        methodName = 'float';
        break;
      case ColumnType.numeric:
        methodName = 'numeric';
        break;
      case ColumnType.boolean:
        methodName = 'boolean';
        break;
      case ColumnType.date:
        methodName = 'date';
        break;
      case ColumnType.dateTime:
        methodName = 'dateTime';
        break;
      case ColumnType.timeStamp:
        methodName = 'timeStamp';
        break;
      case ColumnType.binary:
        methodName = 'binary';
        break;
      case ColumnType.blob:
        methodName = 'blob';
        break;
      case ColumnType.clob:
        methodName = 'clob';
        break;
      default:
        methodName = 'varChar';
        break;
    }
    return methodName;
  }
}
