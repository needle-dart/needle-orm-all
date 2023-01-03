// ignore_for_file: unused_field, unused_element

import 'package:logging/logging.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm/impl.dart';
part 'domain.g.dart'; // auto generated code
// part 'domain.part.dart'; // business logic code

// all Field names must start with '_'

@Entity()
abstract class Basic extends Model {
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
  String? _password;

  @Column()
  String? _address;

  @Column()
  int? _age;

  @OneToMany(mappedBy: "_author")
  List<Book>? _books;

  User();

  @PrePersist()
  void _beforeInsert() {
    print('--> before insert user: $_name');
  }

  @PostPersist()
  void _afterInsert() {}

  @PreRemove()
  void _beforeRemove() {}

  @PreRemovePermanent()
  void _beforeRemovePermanent() {}

  @PreUpdate()
  void _beforeUpdate() {}

  @PostLoad()
  void _afterLoad() {}

  @PostUpdate()
  void _afterUpdate() {}

  @PostRemove()
  void _afterRemove() {}

  @PostRemovePermanent()
  void _afterRemovePermanent() {}
}

@Entity()
class Job extends Basic {
  @Column()
  String? _name;

  Job();
}
