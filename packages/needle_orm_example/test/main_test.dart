import 'package:needle_orm_example/common.dart';
import 'package:needle_orm_example/domain.dart';

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:needle_orm/api.dart';
import 'package:test/test.dart';

const dbMariadb = "mariadb";
const dbPostgres = "postgres";
void main() async {
  initNeedle();

  Needle.currentUser = () {
    return User()..id = 0;
  };

  setUp(() async {
    initLogger();

    // the first db will be the default one as well
    Database.register(dbPostgres, await initPostgreSQL());
    Database.register(dbMariadb, await initMariaDb());
    // await clean();
  });

  tearDown(() async {
    // await Database.closeAll();
  });

  test('testQueryCondition', () {
    var q = UserQuery();
    // test 1
    q.where([
      q.age.between(22, 33),
      q.name.startsWith('inner_'),
      q.books.createdBy.name.startsWith('root'),
      q.books.price.ge(20.0),
      q.not(q.and([
        q.createdBy.name.startsWith('root'),
        q.or([
          q.books.lastUpdatedBy.name.endsWith('_user'),
          q.lastUpdatedBy.name.endsWith('_guest')
        ])
      ])),
    ]);

    // test 2
    /* q.where([
      q.age.gt(18),
      q.books.lastUpdatedBy.name.endsWith('_user'),
    ]); */

    /* q.books.createdBy.name.startsWith('root');
    q.lastUpdatedBy.name.endsWith('_user');
    q.books.isNotEmpty();
    q.createdBy.name.startsWith('root');
    q.not(q.createdBy.name.startsWith('root'));
    q.and([
      q.createdBy.name.startsWith('root'),
      q.lastUpdatedBy.name.endsWith('_user')
    ]);
    q.and([
      q.createdBy.name.startsWith('root'),
      q.or([
        q.lastUpdatedBy.name.endsWith('_user'),
        q.lastUpdatedBy.name.endsWith('_guest')
      ])
    ]);
    q.or([
      q.createdBy.name.startsWith('root'),
      q.lastUpdatedBy.name.endsWith('_user')
    ]); */
    q.orders = [q.age.asc(), q.id.desc()];
    q.maxRows = 10;
    q.offset = 20;
    q.debugQuery();
  });

  test('testCount', testCount);
  test('testInsert', testInsert);
  test('testUpdate', testUpdate);
  test('testVersion', testVersion);
  test('testFindByIds', testFindByIds);
  test('testFindBy', testFindBy);
  test('testFindListBySql', testFindListBySql);
  test('testCache', testCache);
  test('testInsertBatch', testInsertBatch);
  test('testLoadNestedFields', testLoadNestedFields);
  test('testPaging', testPaging);
  test('testSoftDelete', testSoftDelete);
  test('testPermanentDelete', testPermanentDelete);
  test('testMultipleDatabases', testMultipleDatabases);
  test('testOneToMany', testOneToMany);

  // test('testTransactionMariaDb', testTransactionMariaDb,
  //     timeout: Timeout.factor(2));
  test('testTransactionMariaDbRaw', testTransactionMariaDbRaw);
  test('testTransactionPg', testTransactionPg);
  test('testTransactionPgRaw', testTransactionPgRaw);

  // exit(0);
}

Future<void> testTransactionMariaDb() async {
  try {
    await testMariaDbTransaction();
  } catch (e, s) {
    logger.severe('testMariaDbTransaction failed as expected', e, s);
  }
}

Future<void> testTransactionMariaDbRaw() async {
  try {
    await testMariaDbTransaction2();
  } catch (e, s) {
    logger.severe('testMariaDbTransactionRaw failed as expected', e, s);
  }
}

Future<void> testTransactionPg() async {
  try {
    await testPgTransaction();
  } catch (e, s) {
    logger.severe('testTransactionPg failed as expected', e, s);
  }
}

Future<void> testTransactionPgRaw() async {
  try {
    await testPgTransaction2();
  } catch (e, s) {
    logger.severe('testTransactionPgRaw failed as expected', e, s);
  }
}

/// remove all rows from database.
Future<void> clean() async {
  for (var db in [Database.lookup(dbPostgres), Database.lookup(dbMariadb)]) {
    await BookQuery(db: db).deleteAllPermanent();
    await UserQuery(db: db).deleteAllPermanent();
  }
}

Future<void> testFindByIds() async {
  var log = Logger('$logPrefix testFindByIds');

  var existBooks = [Book()..id = 4660];
  var books = await BookQuery()
      .findByIds([1, 15, 16, 4660, 4674], existModeList: existBooks);
  log.info('books list: $books');
  bool reused = books.any((book1) => existBooks.any((book2) => book1 == book2));
  log.info('reused: $reused');
  // load properties before calling toMap(author(...))
  for (var book in books) {
    await book.author?.load();
  }
  log.info(
      'books: ${books.map((e) => e.toMap(fields: '*,author(id,name,loginName)')).toList()}');
}

Future<void> testFindBy() async {
  /* var log = Logger('$logPrefix testFindBy');

  var authorId = await testInsert();

  var books = await BookQuery()
      .findBy({"author": authorId}); // can use model.id as value
  log.info('books list: $books');
  // load properties before calling toMap(author(...))
  for (var book in books) {
    await book.author?.load();
  }
  log.info(
      'books: ${books.map((e) => e.toMap(fields: '*,author(id,name,loginName)')).toList()}');

  var users = await UserQuery().findList();
  log.info('users: $users');

  for (var user in users) {
    await user.books?.load();
  }
  log.info('user.toMap() : ${users[0].toMap(fields: '*,books(id,title)')}');
 */
  {
    var query = UserQuery();
    query.createdBy.id.eq(1);
    query.lastUpdatedBy.id.between(0, 2);
    var list = await query.findList();
    print('user list: $list');
  }
}

Future<void> testFindListBySql() async {
  var log = Logger('$logPrefix testFindBy');

  await testInsert();
  //postgresql supports:  select distinct(t.*) from books t limit 3
  //mariadb doesn't support!
  var books = await BookQuery()
      .findListBySql('select distinct(t.id) from books t limit 3');
  log.info('books list: $books');
  for (var book in books) {
    await book.author?.load();
  }
  log.info(
      'books: ${books.map((e) => e.toMap(fields: '*,author(id,name,loginName)')).toList()}');
}

Future<void> testCount() async {
  var log = Logger('$logPrefix testCount');
  log.info(await BookQuery().count());
}

Future<int> testInsert() async {
  var log = Logger('$logPrefix testInsert');

  log.info('count before insert : ${await BookQuery().count()}');
  var lastUserId = 0;
  var n = 5;
  for (int i = 0; i < n; i++) {
    var user = User()
      ..name = 'name_$i'
      ..loginName = 'name_$i'
      ..address = 'China Shanghai street_$i'
      ..age = (n * 0.1).toInt();
    user.resetPassword('newPassw0rd');
    await user.save();

    expect(user.verifyPassword('newPassw0rd'), true);

    lastUserId = user.id;
    log.info('\t used saved with id: ${user.id}');

    var book = Book()
      ..author = user
      ..price = n * 0.3
      ..title = 'Dart$i';
    await book.insert();
    log.info('\t book saved with id: ${book.id}');
  }
  log.info('count after insert : ${await BookQuery().count()}');
  return lastUserId;
}

Future<void> testInsertBatch() async {
  var log = Logger('$logPrefix testInsertBatch');

  var n = 10;
  var users = <User>[];
  var books = <Book>[];
  for (int i = 0; i < n; i++) {
    var user = User()
      ..name = 'name_$i'
      ..address = 'China Shanghai street_$i'
      ..age = (n * 0.1).toInt();
    users.add(user);

    var book = Book()
      ..author = user
      ..price = n * 0.3
      ..title = 'Dart$i';
    books.add(book);
  }
  log.info('users created');
  await UserQuery().insertBatch(users, batchSize: 5);
  log.info('users saved');
  var idList = users.map((e) => e.id).toList();
  log.info('ids: $idList');
}

Future<void> testPaging() async {
  var log = Logger('$logPrefix paging');
  var q = BookQuery()
    ..title.startsWith('Dart')
    ..price.between(10.0, 20)
    ..author.apply((author) {
      author
        ..age.ge(18)
        ..address.startsWith('China Shanghai');
    });

  q.orders = [BookQuery().id.desc()];

  {
    q.paging(0, 3);
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
  {
    q.paging(1, 3);
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
  {
    // prevent paging
    q.paging(0, 0);
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
}

Future<void> testUpdate() async {
  var log = Logger('$logPrefix testUpdate');

  var user = User();

  user
    ..name = 'administrator'
    ..address = 'China Shanghai Pudong'
    ..age = 23;

  await user.save(); // insert

  log.info('== 1: admin saved , id: ${user.id}');

  // call business method
  log.info('is admin? ${user.isAdmin()}');
  log.info('user.toMap() : ${user.toMap()}');

  // load data from a map
  user.loadMap({"name": 'admin123', "xxxx": 'xxxx'});
  await user.save(); // update
  await user.save(); // should NOT update again.
  user.name = 'admin123';
  await user.save(); // nothing should be updated
  log.info('== 2: admin updated, id: ${user.id}');

  var book = Book()
    ..author = user
    ..price = 11.4
    ..title = 'Dart admin';
  await book.insert();
  log.info('== 3: book saved , id: ${book.id}');
}

Future<void> testVersion() async {
  var log = Logger('$logPrefix testVersion');

  var user = User();

  user
    ..name = 'administrator'
    ..address = 'China Shanghai Pudong'
    ..age = 23;

  await user.save(); // insert

  var user2 = User()
    ..id = user.id
    ..version = user.version
    ..name = 'changed';

  await user2.save(); // updated

  try {
    user.name = 'change again';
    await user.save(); // optimistic lock failure expected!
  } catch (e, st) {
    log.severe('user update failed as expected', e, st);
  }
}

Future<void> testLoadNestedFields() async {
  var log = Logger('$logPrefix testLoadNestedFields');

  await testInsert();

  var q = BookQuery()
    ..orders = [BookQuery().title.asc()]
    ..maxRows = 20;
  var books = await q.findList();
  var total = await q.count();

  log.info(
      'found books: ${books.length}, total: $total , ${books.map((e) => "book.id:${e.id} & author.id:${e.author?.id}").toList()}');

  // should load nested property: author first
  for (Book book in books) {
    await book.author?.load();
    // await book.author?.load(batchSize: 3); // can fetch 3 authors from database every time
  }
  books
      .map((e) => e.toMap(fields: 'id,title,price,author(id,address)'))
      .forEach(log.info);
}

Future<void> testSoftDelete() async {
  var log = Logger('$logPrefix testSoftDelete');

  var n = 5;
  for (int i = 0; i < n; i++) {
    var book = Book()
      ..price = 18 + i * 0.1
      ..title = 'Dart $i test';
    await book.insert();
    log.info('\t book saved with id: ${book.id}');
  }

  var q = BookQuery()
    ..price.between(18, 19)
    ..title.endsWith('test');
  var total = await q.count();
  var totalWithDeleted = await q.count(includeSoftDeleted: true);
  log.info('found books , total: $total, totalWithDeleted: $totalWithDeleted');

  int deletedCount = await q.deleteAll();
  log.info('soft deleted books: $deletedCount');

  total = await q.count();
  totalWithDeleted = await q.count(includeSoftDeleted: true);
  log.info(
      'found books again, total: $total, totalWithDeleted: $totalWithDeleted');
}

Future<void> testPermanentDelete() async {
  var log = Logger('$logPrefix testPermanentDelete');

  var n = 5;
  for (int i = 0; i < n; i++) {
    var book = Book()
      ..price = 38 + i * 0.1
      ..title = 'Dart $i permanent';
    await book.insert();
    log.info('\t book saved with id: ${book.id}');
  }

  var q = BookQuery()
    ..price.between(38, 39)
    ..title.endsWith('permanent');
  var total = await q.count();

  log.info('found permanent books, total: $total');

  int deletedCount = await q.deleteAllPermanent();
  log.info('permanent deleted books: $deletedCount');
}

Future<void> testMultipleDatabases() async {
  var log = Logger('$logPrefix testMultipleDatabases');

  {
    var n = 5;
    for (int i = 0; i < n; i++) {
      var book = Book()
        ..price = 18 + i * 0.1
        ..title = 'Dart $i test';
      await book.insert(db: Database.lookup(dbMariadb));
      log.info('\t book saved with id: ${book.id}');
    }

    var q = BookQuery(db: Database.lookup(dbMariadb))
      ..price.between(18, 19)
      ..title.endsWith('test');
    var total = await q.count();
    var totalWithDeleted = await q.count(includeSoftDeleted: true);
    log.info(
        'found books[mariadb] , total: $total, totalWithDeleted: $totalWithDeleted');
  }

  {
    var n = 5;
    for (int i = 0; i < n; i++) {
      var book = Book()
        ..price = 18 + i * 0.1
        ..title = 'Dart $i test';
      await book.insert(db: Database.lookup(dbPostgres));
      log.info('\t book saved with id: ${book.id}');
    }

    var q = BookQuery(db: Database.lookup(dbPostgres))
      ..price.between(18, 19)
      ..title.endsWith('test');
    var total = await q.count();
    var totalWithDeleted = await q.count(includeSoftDeleted: true);
    log.info(
        'found books[postgresql] , total: $total, totalWithDeleted: $totalWithDeleted');
  }
}

Future<void> testOneToMany() async {
  var log = Logger('$logPrefix testOneToMany');

  var q = UserQuery()
    ..id.gt(18)
    ..id.lt(23)
    ..maxRows = 20;
  var users = await q.findList();
  for (User user in users) {
    var books = user.books;
    await books?.load();
    log.info(books?.length);
    if ((books?.length ?? 0) > 0) {
      log.info(
          'user: ${user.toMap(fields: "id,name,address,books(id,title,price)")}');
    }
  }
}

Future<void> testCache() async {
  var log = Logger('$logPrefix testCache');
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

  var q = BookQuery()..id.IN([book1.id!, book2.id!]);
  var books = await q.findList();
  // books[0].author should equals books[1].author
  log.info('used cache? ${books[0].author == books[1].author}');
}

// Failed for now!
Future<void> testMariaDbTransaction() async {
  var log = Logger('$logPrefix testMariaDbTransaction');
  var q = UserQuery();
  log.info('count before insert : ${await q.count()}');
  var db2 = await initMariaDb();
  await db2.transaction((db) async {
    // var query = UserQuery(db: db);
    var n = 50;
    for (int i = 1; i < n; i++) {
      var user = User()
        ..name = 'tx_name_$i'
        ..address = 'China Shanghai street_$i ' * (i * 2 + 2)
        ..age = n;
      try {
        // log.info('using global db? ${globalDb == db}, using db2? ${db2 == db}');
        await user.save(db: db);
        // unfortunately, it get blocked here, DO NOT know why for now!
        //TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
        // dart:isolate  _RawReceivePortImpl._handleMessage
      } catch (e, s) {
        log.severe('save error', e, s);
        rethrow;
      } finally {
        log.info('saved ....');
      }

      log.info('\t used saved with id: ${user.id}');
    }
  });

  log.info('count after insert : ${await q.count()}');
}

Future<void> testMariaDbTransaction2() async {
  var logger = Logger('testMariaDbTransaction2');
  var db = await initMariaDb();

  try {
    var s = await db.transaction((db) async {
      var n = 50;
      for (int i = 1; i < n; i++) {
        await db.query(
            "insert into users(name,address) values(@name, @address)", {
          'name': 'name ' * i,
          'address': 'China shanghai pudong new district ' * i
        });
        print('inserted: $i');
      }
    });
    // it's ok transaction will be rollback because of the over-long address
    print('okok: $s');
  } catch (e, s) {
    logger.severe('test error', e, s);
  } finally {
    logger.info('test end');
  }
}

Future<void> testPgTransaction() async {
  var log = Logger('$logPrefix testPgTransaction');
  var q = UserQuery();
  log.info('count before insert : ${await q.count()}');
  var db2 = await initPostgreSQL();
  globalDb = db2;
  await db2.transaction((db) async {
    // var query = UserQuery(db: db);
    var n = 50;
    for (int i = 1; i < n; i++) {
      var user = User()
        ..name = 'tx_name_$i'
        ..address = 'China Shanghai street_$i ' * (i + 2)
        ..age = n;
      try {
        log.info('using global db? ${globalDb == db}, using db2? ${db2 == db}');
        await user.save(db: db);
      } catch (e, s) {
        log.severe('save error', e, s);
        rethrow;
      } finally {
        log.info('saved ....');
      }

      log.info('\t used saved with id: ${user.id}');
    }
  });

  log.info('count after insert : ${await q.count()}');
}

Future<void> testPgTransaction2() async {
  var logger = Logger('testPgTransaction2');
  var db = await initPostgreSQL();

  try {
    var s = await db.transaction((db) async {
      var n = 50;
      for (int i = 1; i < n; i++) {
        await db.query(
            "insert into users(name,address) values(@name, @address)", {
          'name': 'name ' * i,
          'address': 'China shanghai pudong new district ' * i
        });
        print('inserted: $i');
      }
    });
    // it's ok transaction will be rollback because of the over-long address
    print('okok: $s');
  } catch (e, s) {
    logger.severe('test error', e, s);
  } finally {
    logger.info('test end');
  }
}
