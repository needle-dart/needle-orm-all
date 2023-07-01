import 'package:needle_orm_example/common.dart';
import 'package:needle_orm_example/domain.dart';

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:needle_orm/api.dart';
import 'package:test/test.dart';

const dbMariadb = "mariadb";
const dbPostgres = "postgres";
const dbSqlite = "sqlite";

void main() async {
  initNeedle();

  Needle.currentUser = () {
    return User()..id = 0;
  };

  setUp(() async {
    initLogger();

    // the first db will be the default one as well : Database.defaultDb
    Database.register(dbSqlite, await initSqlite());
    Database.register(dbPostgres, await initPostgreSQL());
    Database.register(dbMariadb, await initMariaDb());
    await clean();
  });

  tearDown(() async {
    // await Database.closeAll();
  });

  test('testQueryCondition', testQueryCondition);
  test('testCount', testCount);
  test('testInsert', testInsert);
  test('testUpdate', testUpdate);
  test('testVersion', testVersion);
  test('testFindByIds', testFindByIds);
  test('testFindListBySql', testFindListBySql);
  test('testPaging', testPaging);
  test('testSoftDelete', testSoftDelete);
  test('testMultipleDatabases', testMultipleDatabases);
  test('testOneToMany', testOneToMany);
  test('testAllDb', testAllDb);

  // test('testTransactionMariaDb', testTransactionMariaDb,
  //     timeout: Timeout.factor(2));
  // test('testTransactionMariaDbRaw', testTransactionMariaDbRaw);
  // test('testTransactionPg', testTransactionPg);
  // test('testTransactionPgRaw', testTransactionPgRaw);

  // exit(0);
}

Future<void> testAllDb() async {
  for (var db in [
    Database.lookup(dbPostgres)!,
    Database.lookup(dbMariadb)!,
    Database.lookup(dbSqlite)!
  ]) {
    //
    Database.defaultDb = db;
    await testQueryCondition();
    await testCount();
    await testInsert();
    await testUpdate();
    await testVersion();
    await testFindByIds();
    await testFindListBySql();
    await testPaging();
    await testSoftDelete();
    await testOneToMany();
  }
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
  for (var db in [
    Database.lookup(dbPostgres)!,
    Database.lookup(dbMariadb)!,
    Database.lookup(dbSqlite)!
  ]) {
    db.truncate("users");
    db.truncate("books");
    db.truncate("devices");
  }
}

Future<void> testQueryCondition() async {
  var q = UserQuery();
  // test 1
  q.where([
    q.age.between(12, 33), // disable between for the time being
    q.name.startsWith('inner_'),
    q.age.IN([5, 10, 20, 30]),
    // q.books.createdBy.name.startsWith('root'),
    q.books.price.ge(20.0),
    // q.not(q.age.lt(25)),
    // q.not(q.and([
    //   q.createdBy.name.startsWith('root'),
    //   q.or([
    //     q.books.lastUpdatedBy.name.endsWith('_user'),
    //     q.lastUpdatedBy.name.endsWith('_guest')
    //   ])
    // ])),
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
  q.paging(1, 10);
  q.debugQuery();
  var list = await q.findList();
  // print(list);
  print(list.map((e) => e.toMap()));
}

Future<void> testFindByIds() async {
  var log = Logger('$logPrefix testFindByIds');

  var bookQuery = BookQuery()..id.IN([1, 2, 19, 21]);
  var books = await bookQuery.findList();
  log.info('books: ${books.map((e) => e.toMap()).toList()}');
}

Future<void> testFindListBySql() async {
  var log = Logger('$logPrefix testFindBy');
  var books = await BookQuery().findListBySql(
      ',users t1 where t0.author_id=t1.id and t1.age>@age limit 3',
      {'age': 10});
  log.info('books list: $books');
  log.info('books: ${books.map((e) => e.toMap()).toList()}');
}

Future<void> testCount() async {
  var log = Logger('$logPrefix testCount');
  var q = BookQuery();
  q.where([q.price.gt(10)]);
  log.info(await q.count());
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
    q.noPaging();
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
}

Future<void> testUpdate() async {
  var log = Logger('$logPrefix testUpdate');

  {
    var q = UserQuery();
    q.paging(0, 1);
    var u = await q.findUnique();
    Needle.currentUser = () => u;
  }

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
  await user.save(); // nothing happened

  var user2 = User()
    ..id = user.id
    ..version = user.version
    ..name = 'update1';

  await user2.save(); // updated

  var user3 = User()
    ..id = user.id
    ..version = user2.version
    ..name = 'update2';

  await user3.save(); // updated

  try {
    user.name = 'change again';
    user.version = user2.version;
    await user.save(); // optimistic lock failure expected!
  } catch (e, st) {
    log.info('user update failed as expected', e, st);
  }

  log.info('== testVersion end');
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

  var q = BookQuery();
  q.where([
    q.price.between(18, 19),
    q.title.endsWith('test'),
  ]);
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
      await book.insert();
      log.info('\t book saved with id: ${book.id}');
    }

    var q = BookQuery()
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
    ..paging(1, 3);
  var users = await q.findList();
  for (User user in users) {
    var books = user.books;
    log.info(books?.length);
    if ((books?.length ?? 0) > 0) {
      log.info(
          'user: ${user.toMap(fields: "id,name,address,books(id,title,price)")}');
    }
  }
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
