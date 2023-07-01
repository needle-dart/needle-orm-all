import 'dart:collection';

import 'helper.dart';
import 'inspector.dart';
import 'meta.dart';
import 'sql.dart';

part 'api.query.part.dart';

/// Needle Api
class Needle {
  static void Function(String className, OrmMetaClass metaClass)
      registerMetaClass = ModelInspector.registerMetaClass;

  static void Function(List<OrmMetaClass> metaClasses) registerAllMetaClasses =
      ModelInspector.registerAllMetaClasses;

  static void Function(String className, ModelInspector inspector) register =
      ModelInspector.register;

  static void Function(List<ModelInspector> inspectors) registerAll =
      ModelInspector.registerAll;

  /// get current login user
  static dynamic Function()? currentUser;

  static ModelHelper helper(Model model) {
    return model._innerHelper;
  }
}

/// Base class for all Models with @ID
abstract class Model {
  @ID()
  dynamic id;

  late final ModelHelper _innerHelper;

  Model() {
    _innerHelper = ModelHelper(this, runtimeType.toString());
  }

  /// convert model to map, with specified [fields] (default:*).
  Map<String, dynamic> toMap(
      {String fields = '*',
      bool ignoreNull = true,
      Map<String, dynamic>? map}) {
    return _innerHelper.toMap(fields: fields, ignoreNull: ignoreNull, map: map);
  }

  /// load data from map
  void loadMap(Map<String, dynamic> m, {errorOnNonExistField = false}) {
    _innerHelper.loadMap(m, errorOnNonExistField: errorOnNonExistField);
  }

  /// insert Model to [db]
  Future<void> insert({Database? db}) {
    return _innerHelper.insert(db: db);
  }

  /// update Model to [db]
  Future<void> update({Database? db}) {
    return _innerHelper.update(db: db);
  }

  /// save Model to [db] : insert or update
  Future<void> save({Database? db}) {
    return _innerHelper.save(db: db);
  }

  /// delete Model from [db]
  Future<void> delete({Database? db}) {
    return _innerHelper.delete(db: db);
  }

  /// delete Model permanently from [db]
  Future<void> deletePermanent({Database? db}) {
    return _innerHelper.deletePermanent(db: db);
  }
}

/// Needle

/// Orm Base Annotation
abstract class OrmAnnotation {
  const OrmAnnotation();

  /// whether it's executed at the database side.
  bool isServerSide(ActionType actionType) => false;
}

/// ActionType: Insert, Update, Delete, Select
enum ActionType { insert, update, delete, select }

/// OrmClassAnnotation
abstract class OrmClassAnnotation {}

/// @MappedClass annotation marks a class as an abstract Model.
class MappedClass extends OrmAnnotation {
  const MappedClass();
}

/// @Entity annotation marks a class as a concreat Model.
class Entity extends OrmAnnotation {
  const Entity();
}

/// @Table annotation can be used to specify an alternative table name rather than the default one.
class Table extends OrmAnnotation {
  /// table name
  final String? name;

  /// table catalog
  final String? catalog;

  /// table schema
  final String? schema;

  /// table indexes
  final List<Index> indexes;

  // uniqueConstraints

  const Table({this.name, this.catalog, this.schema, this.indexes = const []});
}

/// @ID annotation marks a `single` property as Primary Key.
class ID extends OrmAnnotation {
  const ID();
}

/// @Column annotation used to customize the column defination.
class Column extends OrmAnnotation {
  final String? name;
  final int length;
  final int precision;
  final int scale;
  final bool unique;
  final bool nullable;
  final bool insertable;
  final bool updatable;
  final String? columnDefinition;
  final String? table;

  const Column(
      {this.name,
      this.length = 255,
      this.precision = 0,
      this.scale = 0,
      this.unique = false,
      this.nullable = true,
      this.insertable = true,
      this.updatable = true,
      this.columnDefinition,
      this.table});
}

/// @Lob
class Lob extends OrmAnnotation {
  const Lob();
}

/// @Version
class Version extends OrmAnnotation {
  const Version();
}

/// @Index , NOT implemented yet!
class Index extends OrmAnnotation {
  final String? name;
  final String? columnList;
  final bool unique;
  const Index({this.name, this.columnList, this.unique = false});
}

/// @ManyToOne
class ManyToOne extends OrmAnnotation {
  // cascade
  // fetch
  // optional
  const ManyToOne();
}

/// @OneToMany
class OneToMany extends OrmAnnotation {
  // cascade
  // fetch
  // mappedBy
  // orphanRemoval
  final String? mappedBy;
  const OneToMany({this.mappedBy});
}

/// @OneToOne
class OneToOne extends OrmAnnotation {
  // cascade
  // fetch
  // optional
  // mappedBy
  // orphanRemoval
  final String? mappedBy;
  const OneToOne({this.mappedBy});
}

/// @ManyToMany , NOT implemented yet!
class ManyToMany extends OrmAnnotation {
  const ManyToMany();
}

/// @OrderBy , NOT implemented yet!
class OrderBy extends OrmAnnotation {
  final String value;
  // fetch
  // optional
  // mappedBy
  // orphanRemoval
  const OrderBy(this.value);
}

/// @PrePersist
class PrePersist extends OrmAnnotation {
  const PrePersist();
}

//// @PreUpdate
class PreUpdate extends OrmAnnotation {
  const PreUpdate();
}

/// @PreRemove , executed before logic remove.
class PreRemove extends OrmAnnotation {
  const PreRemove();
}

/// @PreRemovePermanent , executed before permanent remove.
class PreRemovePermanent extends OrmAnnotation {
  const PreRemovePermanent();
}

/// @PostPersist
class PostPersist extends OrmAnnotation {
  const PostPersist();
}

/// @PostUpdate
class PostUpdate extends OrmAnnotation {
  const PostUpdate();
}

/// @PostRemove
class PostRemove extends OrmAnnotation {
  const PostRemove();
}

/// @PostRemovePermanent
class PostRemovePermanent extends OrmAnnotation {
  const PostRemovePermanent();
}

/// @PostLoad
class PostLoad extends OrmAnnotation {
  const PostLoad();
}

/// @Transient
class Transient extends OrmAnnotation {
  const Transient();
}

/// @Comment
// io.ebean extension: @DbComment
class Comment extends OrmAnnotation {
  final String comment;
  const Comment(this.comment);
}

/// @SoftDelete
// io.ebean extension
class SoftDelete extends OrmAnnotation {
  const SoftDelete();
}

/// @WhenCreated
// io.ebean extension
class WhenCreated extends OrmAnnotation {
  const WhenCreated();

  @override
  bool isServerSide(ActionType actionType) =>
      actionType == ActionType.insert ? true : false;
}

/// @WhenModified
// io.ebean extension
class WhenModified extends OrmAnnotation {
  const WhenModified();
  @override
  bool isServerSide(ActionType actionType) =>
      actionType == ActionType.update || actionType == ActionType.insert
          ? true
          : false;
}

/// @WhoCreated
/// seealso: [Needle.currentUser]
/// io.ebean extension
class WhoCreated extends OrmAnnotation {
  const WhoCreated();
}

/// @WhoModified
/// seealso: [Needle.currentUser]
/// io.ebean extension
class WhoModified extends OrmAnnotation {
  const WhoModified();
}
