// ignore_for_file: unused_field, unused_element

import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_migration/needle_orm_migration.dart';

part 'domain.g.dart'; // auto generated code

// all Class names and Field names must start with '_'
// all business logic must be defined in file : 'domain.part.dart'

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

@Entity(db: "mysql_example_db")
class _Book extends _BaseModel {
  @Column()
  String? _title;

  @Column()
  double? _price;

  @ManyToOne()
  _User? _author;

  @Lob()
  List<int>? _image;

  @Column()
  String? _jsonb;

  _Book();
}

@Entity(db: Database.defaultDbName)
class _User extends _BaseModel {
  @Column()
  String? _name;

  @Column()
  String? _loginName;

  @Column()
  String? _address;

  @Column()
  int? _age;

  @OneToMany()
  List<_Book>? books;

  _User();
}

@Entity()
class _Job extends _BaseModel {
  @Column()
  String? _name;

  _Job();
}
