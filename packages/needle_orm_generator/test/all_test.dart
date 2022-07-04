import 'dart:async';

import 'package:logging/logging.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:test/test.dart';
import 'src/domain.dart';
import 'common.dart';

late Database dbMariadb;
late Database dbPostgres;

void main() async {
  setUp(() async {
    dbMariadb = await initMariaDb();
    dbPostgres = await initPostgreSQL();
    globalDb = dbPostgres;
  });

  tearDown(() async {
    // await globalDs.close();
  });

  test('testCount', testCount);
  test('testInsert', testInsert);
  test('testUpdate', testUpdate);
  test('testFindByIds', testFindByIds);
  test('testFindBy', testFindBy);
  test('testInsertBatch', testInsertBatch);
  test('testLoadNestedFields', testLoadNestedFields);
  test('testPaging', testPaging);
  test('testSoftDelete', testSoftDelete);
  test('testPermanentDelete', testPermanentDelete);
  test('testMultipleDatabases', testMultipleDatabases);
  test('testOneToMany', testOneToMany);
  test('testMariaDbTransaction', testMariaDbTransaction);
  test('testMariaDbTransaction2', testMariaDbTransaction2);
  test('testPgTransaction', testPgTransaction);
  test('testPgTransaction2', testPgTransaction2);

  // new Timer(const Duration(seconds: 10), () => exit(0));
}

Future<void> testFindByIds() async {
  var log = Logger('$logPrefix testFindByIds');

  var existBooks = [Book()..id = 4660];
  var books = await Book.query()
      .findByIds([1, 15, 16, 4660, 4674], existModeList: existBooks);
  log.info('books list: $books');
  bool reused = books.any((book1) => existBooks.any((book2) => book1 == book2));
  log.info('reused: $reused');
  log.info(
      'books: ${books.map((e) => e.toMap(fields: '*,author(id,name,loginName)')).toList()}');
}

Future<void> testFindBy() async {
  var log = Logger('$logPrefix testFindBy');

  var books =
      await Book.query().findBy({"author": 5100}); // can use model.id as value
  log.info('books list: $books');
  log.info(
      'books: ${books.map((e) => e.toMap(fields: '*,author(id,name,loginName)')).toList()}');
}

Future<void> testCount() async {
  var log = Logger('$logPrefix testCount');
  log.info(await Book.query().count());
}

Future<void> testInsert() async {
  var log = Logger('$logPrefix testInsert');

  log.info('count before insert : ${await Book.query().count()}');
  var n = 5;
  for (int i = 0; i < n; i++) {
    var user = User()
      ..name = 'name_$i'
      ..address = 'China Shanghai street_$i'
      ..age = (n * 0.1).toInt();
    await user.save();
    log.info('\t used saved with id: ${user.id}');

    var book = Book()
      ..author = user
      ..price = n * 0.3
      ..title = 'Dart$i';
    await book.insert();
    log.info('\t book saved with id: ${book.id}');
  }
  log.info('count after insert : ${await Book.query().count()}');
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
  await User.query().insertBatch(users, batchSize: 5);
  log.info('users saved');
  var idList = users.map((e) => e.id).toList();
  log.info('ids: $idList');
}

Future<void> testPaging() async {
  var log = Logger('$logPrefix paging');
  var q = Book.query()
    ..title.startsWith('Dart')
    ..price.between(10.0, 20)
    ..author.apply((author) {
      author
        ..age.ge(18)
        ..address.startsWith('China Shanghai');
    });

  q.orders = [Book.query().id.desc()];

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
  user.save(); // update
  log.info('== 2: admin updated, id: ${user.id}');

  var book = Book()
    ..author = user
    ..price = 11.4
    ..title = 'Dart admin';
  await book.insert();
  log.info('== 3: book saved , id: ${book.id}');
}

Future<void> testLoadNestedFields() async {
  var log = Logger('$logPrefix testLoadNestedFields');

  var q = Book.query()
    ..orders = [Book.query().title.asc()]
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

  var q = Book.query()
    ..price.between(18, 19)
    ..title.endsWith('test');
  var total = await q.count();
  var totalWithDeleted = await q.count(includeSoftDeleted: true);
  log.info('found books , total: $total, totalWithDeleted: $totalWithDeleted');

  int deletedCount = await q.delete();
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

  var q = Book.query()
    ..price.between(38, 39)
    ..title.endsWith('permanent');
  var total = await q.count();

  log.info('found permanent books, total: $total');

  int deletedCount = await q.deletePermanent();
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
      await book.insert(db: dbMariadb);
      log.info('\t book saved with id: ${book.id}');
    }

    var q = Book.query(db: dbMariadb)
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
      await book.insert(db: dbPostgres);
      log.info('\t book saved with id: ${book.id}');
    }

    var q = Book.query(db: dbPostgres)
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

  var q = User.query()
    ..id.gt(18)
    ..id.lt(23)
    ..maxRows = 20;
  var users = await q.findList();
  for (User user in users) {
    var books = user.books;
    if (books != null && books is LazyOneToManyList) {
      await (books as LazyOneToManyList).load();
    }
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
  var q = User.query();
  log.info('count before insert : ${await q.count()}');
  var db2 = await initMariaDb();
  await db2.transaction((db) async {
    // var query = User.query(db: db);
    var n = 50;
    for (int i = 1; i < n; i++) {
      var user = User()
        ..name = 'tx_name_$i'
        ..address = 'China Shanghai street_$i ' * (i + 2)
        ..age = n;
      try {
        log.info('using global db? ${globalDb == db}, using db2? ${db2 == db}');
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
  var q = User.query();
  log.info('count before insert : ${await q.count()}');
  var db2 = await initPostgreSQL();
  await db2.transaction((db) async {
    // var query = User.query(db: db);
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
