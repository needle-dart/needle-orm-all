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

abstract class OrmAnnotation {
  const OrmAnnotation();
  bool isServerSide(ActionType actionType) => false;
  String serverSideExpr(ActionType actionType) => '';
}

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

/// [Entity] annotation marks a class as a Model.
class Entity extends OrmAnnotation {
  // final String? name;
  final String? db; // Database name

  const Entity({this.db = Database.defaultDbName});
}

/// [Table] annotation can be used to specify an alternative table name rather than the default one.
class Table extends OrmAnnotation {
  final String? name;
  final String? catalog;
  final String? schema;
  final List<Index> indexes;

  // uniqueConstraints

  const Table({this.name, this.catalog, this.schema, this.indexes = const []});
}

/// [ID] annotation marks a `single` property as Primary Key.
class ID extends OrmAnnotation {
  const ID();
}

/// [Column] annotation used to customize the column defination.
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

class Lob extends OrmAnnotation {
  const Lob();
}

class Version extends OrmAnnotation {
  const Version();
}

class Index extends OrmAnnotation {
  final String? name;
  final String? columnList;
  final bool unique;
  const Index({this.name, this.columnList, this.unique = false});
}

class ManyToOne extends OrmAnnotation {
  // cascade
  // fetch
  // optional
  const ManyToOne();
}

class OneToMany extends OrmAnnotation {
  // cascade
  // fetch
  // mappedBy
  // orphanRemoval
  final String? mappedBy;
  const OneToMany({this.mappedBy});
}

class OneToOne extends OrmAnnotation {
  // cascade
  // fetch
  // optional
  // mappedBy
  // orphanRemoval
  final String? mappedBy;
  const OneToOne({this.mappedBy});
}

class ManyToMany extends OrmAnnotation {
  const ManyToMany();
}

class OrderBy extends OrmAnnotation {
  final String value;
  // fetch
  // optional
  // mappedBy
  // orphanRemoval
  const OrderBy(this.value);
}

class PrePersist extends OrmAnnotation {
  const PrePersist();
}

class PreUpdate extends OrmAnnotation {
  const PreUpdate();
}

class PreRemove extends OrmAnnotation {
  const PreRemove();
}

class PreRemovePermanent extends OrmAnnotation {
  const PreRemovePermanent();
}

class PostPersist extends OrmAnnotation {
  const PostPersist();
}

class PostUpdate extends OrmAnnotation {
  const PostUpdate();
}

class PostRemove extends OrmAnnotation {
  const PostRemove();
}

class PostRemovePermanent extends OrmAnnotation {
  const PostRemovePermanent();
}

class PostLoad extends OrmAnnotation {
  const PostLoad();
}

class Transient extends OrmAnnotation {
  const Transient();
}

// io.ebean extension

class DbComment extends OrmAnnotation {
  final String comment;
  const DbComment(this.comment);
}

class SoftDelete extends OrmAnnotation {
  const SoftDelete();
}

class WhenCreated extends OrmAnnotation {
  const WhenCreated();

  @override
  bool isServerSide(ActionType actionType) =>
      actionType == ActionType.Insert ? true : false;
  @override
  String serverSideExpr(ActionType actionType) =>
      actionType == ActionType.Insert ? 'now()' : '';
}

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

class WhoCreated extends OrmAnnotation {
  const WhoCreated();
}

class WhoModified extends OrmAnnotation {
  const WhoModified();
}
