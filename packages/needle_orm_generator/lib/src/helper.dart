import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:needle_orm/api.dart';
import 'package:source_gen/source_gen.dart';

extension StringUtil on String {
  String removePrefix([String prefix = '_']) {
    if (this.startsWith(prefix)) {
      return this.substring(prefix.length);
    }
    return this;
  }

  String genericListType() {
    int i = indexOf('<');
    int j = indexOf('>');
    if (i >= 0 && j > i) {
      var t = substring(i + 1, j);
      if (t.endsWith('?')) {
        return t.substring(0, t.length - 1);
      } else {
        return t;
      }
    }
    return this;
  }
}

TypeChecker get typeChecker => TypeChecker.fromRuntime(OrmAnnotation);

extension OrmFilter on List<ElementAnnotation> {
  Iterable<OrmAnnotation> ormAnnotations() sync* {
    for (ElementAnnotation elmAnnot in this) {
      if (typeChecker.isSuperOf(elmAnnot.element!.enclosingElement!)) {
        yield elmAnnot.ormAnnotation();
      }
    }
  }

  Iterable<ElementAnnotation> ormTypes() sync* {
    for (ElementAnnotation elmAnnot in this) {
      if (typeChecker.isSuperOf(elmAnnot.element!.enclosingElement!)) {
        yield elmAnnot;
      }
    }
  }
}

extension OrmAnnotationConverter on ElementAnnotation {
  String get name => element!.enclosingElement!.name!;
  DartObject get value => computeConstantValue()!;

  String? stringValue(String name) => value.getField(name)?.toStringValue();
  int? intValue(String name) => value.getField(name)?.toIntValue();
  double? doubleValue(String name) => value.getField(name)?.toDoubleValue();
  bool? boolValue(String name) => value.getField(name)?.toBoolValue();

  OrmAnnotation ormAnnotation() {
    // print('************ ${this.toSource()} ');

    switch (name) {
      case 'Comment':
        return toComment();
      case 'Entity':
        return toEntity();
      case 'Table':
        return toTable();
      case 'Column':
        return toColumn();
      case 'ID':
        return ID();
      case 'Lob':
        return Lob();
      case 'Version':
        return Version();
      case 'SoftDelete':
        return SoftDelete();
      case 'WhenCreated':
        return WhenCreated();
      case 'WhenModified':
        return WhenModified();
      case 'WhoCreated':
        return WhoCreated();
      case 'WhoModified':
        return WhoModified();
      case 'OneToOne':
        return toOneToOne();
      case 'OneToMany':
        return toOneToMany();
      case 'ManyToOne':
        return ManyToOne();
      case 'ManyToMany':
        return ManyToMany();
      case 'PrePersist':
        return PrePersist();
      case 'PreUpdate':
        return PreUpdate();
      case 'PreRemove':
        return PreRemove();
      case 'PreRemovePermanent':
        return PreRemovePermanent();
      case 'PostPersist':
        return PostPersist();
      case 'PostUpdate':
        return PostUpdate();
      case 'PostRemove':
        return PostRemove();
      case 'PostRemovePermanent':
        return PostRemovePermanent();
      case 'PostLoad':
        return PostLoad();
      case 'Transient':
        return Transient();
      default:
        throw 'Unsupported OrmAnnotation: $name';
    }
  }

  Entity toEntity() {
    assert(name == 'Entity');
    return Entity();
  }

  Column toColumn() {
    assert(name == 'Column');
    return Column(
      name: stringValue('name'),
      length: intValue('length')!,
      precision: intValue('precision')!,
      scale: intValue('scale')!,
      unique: boolValue('unique')!,
      nullable: boolValue('nullable')!,
      insertable: boolValue('insertable')!,
      updatable: boolValue('updatable')!,
      columnDefinition: stringValue('columnDefinition'),
      table: stringValue('table'),
    );
  }

  Comment toComment() {
    assert(name == 'Comment');
    return Comment(stringValue('comment')!);
  }

  Table toTable() {
    assert(name == 'Table');
    return Table(name: stringValue('name'));
  }

  OneToMany toOneToMany() {
    assert(name == 'OneToMany');
    return OneToMany(mappedBy: stringValue('mappedBy'));
  }

  OneToOne toOneToOne() {
    assert(name == 'OneToOne');
    return OneToOne(mappedBy: stringValue('mappedBy'));
  }
}
