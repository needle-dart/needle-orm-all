// ignore_for_file: unused_field, unused_element

import 'package:logging/logging.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_migration/needle_orm_migration.dart';

part 'domain.g.dart'; // auto generated code
part 'domain.biz.dart';

// all Field names must start with '_'
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

  @PrePersist()
  void beforeInsert() {
    print('going to create user !!!');
  }

  @PostPersist()
  void afterInsert() {
    print('user created!!!');
  }

  @PreRemove()
  void beforeRemove() {}

  @PreRemovePermanent()
  void beforeRemovePermanent() {}

  @PreUpdate()
  void beforeUpdate() {}

  @PostLoad()
  void afterLoad() {
    print('user loaded!!!');
  }

  @PostUpdate()
  void afterUpdate() {}

  @PostRemove()
  void afterRemove() {}

  @PostRemovePermanent()
  void afterRemovePermanent() {}
}

@Table()
@Entity()
class Device extends Model {
  @ID()
  int? _id;

  @Column()
  String? _name;

  @Column()
  String? _address;

  @PrePersist()
  void beforeInsert() {}

  @PostPersist()
  void afterInsert() {}
}
