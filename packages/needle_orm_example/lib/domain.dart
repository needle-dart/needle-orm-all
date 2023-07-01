// ignore_for_file: unused_field, unused_element

import 'package:logging/logging.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm/impl.dart';
import 'package:crypt/crypt.dart';

part 'domain.g.dart'; // auto generated code
part 'domain.biz.dart';

// all Field names must start with '_'
// all business logic must be defined in file : 'domain.part.dart'

final Logger _logger = Logger('EXAMPLE');

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
  @ManyToOne()
  User? _createdBy; // user login name

  @WhoModified()
  @ManyToOne()
  User? _lastUpdatedBy; // user login name

  @Column()
  String? _remark;

  Basic();
}

@Table(name: 'my_books')
@Comment('My Books')
@Entity()
class Book extends Basic {
  @Comment('book title')
  @Column()
  String? _title;

  @Comment('book price')
  @Column()
  double? _price;

  @Comment('book author')
  @ManyToOne()
  User? _author;

  // blob
  @Lob()
  List<int>? _image;

  // clob
  @Comment('book content')
  @Lob()
  String? _content;

  Book();
}

@Table(name: 'users')
@Entity()
class User extends Basic {
  @Comment('user name')
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

  @OneToMany(mappedBy: "author")
  List<Book>? _books;

  User();

  void resetPassword(String newPassword) {
    password = Crypt.sha512(newPassword).toString();
  }

  bool verifyPassword(String tryPassword) {
    return Crypt(_password!).match(tryPassword);
  }

  @PrePersist()
  void beforeInsert() {
    _logger.info('going to create user !!!');
  }

  @PostPersist()
  void afterInsert() {
    _logger.info('user created!!!');
  }

  @PreRemove()
  void beforeRemove() {}

  @PreRemovePermanent()
  void beforeRemovePermanent() {}

  @PreUpdate()
  void beforeUpdate() {}

  @PostLoad()
  void afterLoad() {
    _logger.info('user loaded!!!');
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
  @Column()
  String? _name;

  @Column()
  String? _address;

  @PrePersist()
  void beforeInsert() {}

  @PostPersist()
  void afterInsert() {}
}
