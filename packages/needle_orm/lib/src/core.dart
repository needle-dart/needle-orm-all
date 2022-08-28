// ignore_for_file: constant_identifier_names
// see javax.persistence.*

import 'package:needle_orm/needle_orm.dart';

/// Base class for all Models
abstract class Model {
  /// convert model to map, with specified [fields] (default:*).
  Map<String, dynamic> toMap({String fields = '*', bool ignoreNull = true});

  /// load data from database. Model instancce should have an ID at least.
  Future<void> load({int batchSize = 1});
}

/// Orm Base Annotation
abstract class OrmAnnotation {
  const OrmAnnotation();

  /// whether it's executed at the database side.
  bool isServerSide(ActionType actionType) => false;

  /// expression which will be executed at the database side.
  String serverSideExpr(ActionType actionType) => '';
}

/// ActionType: Insert, Update, Delete, Select
enum ActionType { Insert, Update, Delete, Select }

/// Query for a Model
abstract class AbstractModelQuery<M, ID> {
  AbstractModelQuery();

  /// find single model by [id]
  /// if [existModel] is given, [existModel] will be filled and returned, otherwise a new model will be returned.
  Future<M?> findById(ID id, {M? existModel, bool includeSoftDeleted = false});

  /// find models by [idList]
  Future<List<M>> findByIds(List idList,
      {List<Model>? existModeList, bool includeSoftDeleted = false});

  /// find models by params
  Future<List<M>> findBy(Map<String, dynamic> params,
      {List<Model>? existModeList, bool includeSoftDeleted = false});

  /// find list
  Future<List<M>> findList({bool includeSoftDeleted = false});

  /// return how many rows affected!
  Future<int> delete();

  /// return how many rows affected!
  Future<int> deletePermanent();

  /// return count of this query.
  Future<int> count();

  /// select with raw sql.
  /// example: findListBySql(' select distinct(t.*) from table t, another_table t2 where t.column_name=t2.id and t.column_name2=@param1 and t2.column_name3=@param2 order by t.id, limit 10 offset 10 ', {'param1':100,'param2':'hello'})
  Future<List<M>> findListBySql(String rawSql,
      [Map<String, dynamic> params = const {}]);
}

abstract class OrmClassAnnotation {}

/// @Entity annotation marks a class as a Model.
class Entity extends OrmAnnotation {
  // final String? name;
  final String? db; // Database name

  const Entity({this.db = Database.defaultDbName});
}

/// @Table annotation can be used to specify an alternative table name rather than the default one.
class Table extends OrmAnnotation {
  final String? name;
  final String? catalog;
  final String? schema;
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

/// @Lob , NOT implemented yet!
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

/// @DbComment , NOT implemented yet!
// io.ebean extension
class DbComment extends OrmAnnotation {
  final String comment;
  const DbComment(this.comment);
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
      actionType == ActionType.Insert ? true : false;
  @override
  String serverSideExpr(ActionType actionType) =>
      actionType == ActionType.Insert ? 'now()' : '';
}

/// @WhenModified
// io.ebean extension
class WhenModified extends OrmAnnotation {
  const WhenModified();
  @override
  bool isServerSide(ActionType actionType) =>
      actionType == ActionType.Update || actionType == ActionType.Insert
          ? true
          : false;
  @override
  String serverSideExpr(ActionType actionType) =>
      actionType == ActionType.Update || actionType == ActionType.Insert
          ? 'now()'
          : '';
}

/// @WhoCreated , NOT implemented yet!
// io.ebean extension
class WhoCreated extends OrmAnnotation {
  const WhoCreated();
}

/// @WhoModified , NOT implemented yet!
// io.ebean extension
class WhoModified extends OrmAnnotation {
  const WhoModified();
}
