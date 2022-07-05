// ignore_for_file: unused_field, unused_element

import 'package:angel3_migration/angel3_migration.dart' hide Table;
import 'package:logging/logging.dart';
import 'package:needle_orm/needle_orm.dart';
import '../common.dart';

part 'domain.g.dart'; // auto generated code
part 'domain.part.dart'; // business logic code

// all Class names and Field names must start with '_'
// all business logic must be defined in file : 'domain.part.dart'

var _globalDb = globalDb; // refer to main.dart

@Entity()
abstract class _BaseModel {
  @ID()
  int? _id;

  @Version()
  int? _version;

  @SoftDelete()
  bool? _deleted;

  @WhenCreated()
  DateTime? _createdAt;

  @WhenModified()
  DateTime? _updatedAt;

  @WhoCreated()
  String? _createdBy; // user login name

  @WhoModified()
  String? _lastUpdatedBy; // user login name

  @Column()
  String? _remark;

  _BaseModel();
}

@Table()
@Entity(ds: "mysql_example_db")
class _Book extends _BaseModel {
  @Column()
  String? _title;

  @Column()
  double? _price;

  @ManyToOne()
  _User? _author;

  _Book();
}

@Table(name: 'users')
@Entity(ds: Entity.DEFAULT_DB)
class _User extends _BaseModel {
  @Column()
  String? _name;

  @Column()
  String? _loginName;

  @Column()
  String? _address;

  @Column()
  int? _age;

  @OneToMany(mappedBy: "_author")
  List<_Book>? books;

  _User();

  // need to implement beforeInsert() for User in domain.part.dart
  @PrePersist()
  void beforeInsert() {}

  @PostPersist()
  void afterInsert() {}

  @PreRemove()
  void beforeRemove() {}

  @PreRemovePermanent()
  void beforeRemovePermanent() {}

  @PreUpdate()
  void beforeUpdate() {}

  @PostLoad()
  void afterLoad() {}

  @PostUpdate()
  void afterUpdate() {}

  @PostRemove()
  void afterRemove() {}

  @PostRemovePermanent()
  void afterRemovePermanent() {}
}

@Entity()
class _Job extends _BaseModel {
  @Column()
  String? _name;

  _Job();
}
