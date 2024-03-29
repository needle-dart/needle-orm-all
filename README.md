Needle ORM for dart.

## Databases supported

- [x] PostgreSQL
- [x] SQLite
- [x] MariaDB (except that transaction is still not working )

Try to be a familar ORM framework to java programmers, so it will obey javax.persistence spec.

## Annotations supported

- [x] @Entity
- [x] @Column
- [x] @Transient
- [x] @Table
- [x] @ID
- [x] @Lob
- [x] @OneToOne
- [x] @OneToMany
- [x] @ManyToOne
- [ ] @ManyToMany
- [ ] @Index
- [ ] @OrderBy
- [x] @Version

some other useful annotations , just like [Ebean ORM for Java/Kotlin](https://ebean.io), are supported as well :

- [x] @SoftDelete
- [x] @WhenCreated
- [x] @WhenModified
- [x] @WhoCreated
- [x] @WhoModified
- [x] @PreInsert
- [x] @PreUpdate
- [x] @PreRemove
- [x] @PreRemovePermanent
- [x] @PostInsert
- [x] @PostUpdate
- [x] @PostRemove
- [x] @PostRemovePermanent
- [x] @PostLoad

## Define Model

```dart
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

@Table(name: 'tbl_user')
@Entity()
class _User extends _BaseModel {
  @Column()
  String? _name;

  @Column()
  String? _loginName;

  @Column()
  String? _address;

  @Column()
  int? _age;

  @OneToMany(mappedBy: "author")
  List<_Book>? books;

  _User();
}


@Table()
@Entity()
class _Book extends _BaseModel {
  @Column()
  String? _title;

  @Column()
  double? _price;

  @ManyToOne()
  _User? _author;

  // blob
  @Lob()
  List<int>? _image;

  // clob
  @Lob()
  String? _content;

  _Book();
}

```

## Enhance business logic

```dart
extension Biz_User on User {
  bool isAdmin() {
    return name!.startsWith('admin');
  }

  void beforeInsert() {
    print('before insert user ....');
  }

  void afterInsert() {
    print('after insert user ....');
  }
}
```

## Usage

```dart

Future<Database> initPostgreSQL() async {
  return PostgreSqlPoolDatabase(PgPool(
    PgEndpoint(
      host: 'localhost',
      port: 5432,
      database: 'appdb',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: PgPoolSettings()
      ..maxConnectionAge = Duration(hours: 1)
      ..concurrency = 5,
  ));
}

void main() async {
  Database.register("dbPostgres", await initPostgreSQL());

  // Create or update :
  {
    var user = User();
    user
      ..name = 'administrator'
      ..address = 'abc'
      ..age = 23
      ..save(); // or insert()

    print('user saved, id= ${user.id}');

    user
      ..name = 'another name'
      ..save(); // or update()

    // call business method
    print('is admin? ${user.isAdmin()}');

    // toMap, can also be used to generate json
    var valueMap = user.toMap();
    // or only output some fields
    valueMap = user.toMap(fields:'id,name');

    // load from a map
    user.loadMap({"name": 'admin123', "xxxx": 'xxxx'});

    var book = Book();
    book
      ..author = user
      ..title = 'Dart'
      ..price = 14.99
      ..insert();

    // toMap supports nested fields: 'author(id,name)'
    valueMap = book.toMap(fields:'id,title,price,author(id,name)');
  }

  // Typed-Query:
  {
    Book.query()
      ..title.startsWith('dart')
      ..price.between(10.0, 20.0)
      ..author.apply((author) {
        author
          ..age.ge(18)
          ..address.startsWith('China Shanghai');
      })
      ..orders = [Book.query().price.desc()]
      ..offset = 10
      ..maxRows = 20  // limit
      ..findList();
  }

  // Soft Delete:
  {
    var q = Book.query()
      ..price.between(18, 19)
      ..title.endsWith('test');
    var total = await q.count();  // without deleted records
    var totalWithDeleted = await q.count(includeSoftDeleted: true);
    print('found books , total: $total, totalWithDeleted: $totalWithDeleted');

    int deletedCount = await q.delete();
    print('soft deleted books: $deletedCount');

    total = await q.count();
    totalWithDeleted = await q.count(includeSoftDeleted: true);
    print('found books after soft delete , total: $total, totalWithDeleted: $totalWithDeleted');
  }

  // Permanent delete
  {
    var q = Book.query()
    ..price.between(100, 1000);
    var total = await q.count();

    print('found expensive books, total count: $total');

    int deletedCount = await q.deletePermanent();
    print('permanent deleted books : $deletedCount');
  }

  // batch insert
  {
    var n = 10;
    var users = <User>[];
    for (int i = 0; i < n; i++) {
      var user = User()
        ..name = 'name_$i'
        ..address = 'China Shanghai street_$i'
        ..age = (n * 0.1).toInt();
      users.add(user);
    }
    print('users created');
    await User.query().insertBatch(users, batchSize: 5);
    print('users saved');
    var idList = users.map((e) => e.id).toList();
    print('ids: $idList');
  }

  // model cache in the same Query.
  {
    var user = User()..name = 'cach_name';
    await user.save();

    var book1 = Book()
      ..author = user
      ..title = 'book title1';
    var book2 = Book()
      ..author = user
      ..title = 'book title2';
    await book1.save();
    await book2.save();

    var q = Book.query()..id.IN([book1.id!, book2.id!]);
    var books = await q.findList();
    // books[0].author should be as same as books[1].author
    print('used cache? ${books[0].author == books[1].author}');
  }

  // Transaction : only works on PostgreSQL, there're still some problems on MariaDB
  {
    var q = User.query();
    print('count before insert : ${await q.count()}');
    var db2 = await initPostgreSQL();
    await db2.transaction((db) async {
      // var query = User.query(db: db);
      var n = 50;
      for (int i = 1; i < n; i++) {
        var user = User()
          ..name = 'tx_name_$i'
          ..address = 'China Shanghai street_$i ' * i
          ..age = n;
        await user.save(db: db); // throw rollback exception at the 10th loop because address is too long
        print('\t used saved with id: ${user.id}');
      }
    });

    // the next line will never be executed because of the rollback exception.
    // print('count after insert : ${await q.count()}');
  }
}

```

## Example

Example project can be found here: [needle_orm_example](https://github.com/needle-dart/needle-orm-all/blob/main/packages/needle_orm_example/test/main_test.dart) .
