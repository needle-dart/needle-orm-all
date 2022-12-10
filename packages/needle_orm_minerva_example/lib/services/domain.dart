// ignore_for_file: unused_field, unused_element

import 'package:logging/logging.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_migration/needle_orm_migration.dart';

part 'domain.g.dart'; // auto generated code
part 'domain.part.dart'; // business logic code

// all Class names and Field names must start with '_'
// all business logic must be defined in file : 'domain.part.dart'

@Entity()
abstract class Basic extends Model {
  @ID()
  int? _id;

  @Version()
  int? _version;

  @SoftDelete()
  bool? _softDeleted;

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

  @Transient()
  Map<String, dynamic>? _extra;

  Basic();
}

@Table()
@Entity()
class Book extends Basic {
  @Column()
  String? _title;

  @Column()
  double? _price;

  @ManyToOne()
  User? _author;

  // blob
  @Lob()
  List<int>? _image;

  // clob
  @Lob()
  String? _content;

  Book();
}

@Table(name: 'users')
@Entity()
class User extends Basic {
  @Column()
  String? _name;

  @Column()
  String? _loginName;

  @Column()
  String? _address;

  @Column()
  int? _age;

  @OneToMany(mappedBy: "_author")
  List<Book>? _books;

  User();

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
class Job extends Basic {
  @Column()
  String? _name;

  Job();
}
