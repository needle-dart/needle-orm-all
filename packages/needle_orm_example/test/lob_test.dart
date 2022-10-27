import 'dart:typed_data';

import 'package:needle_orm_example/common.dart';
import 'package:needle_orm_example/domain.dart';

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:test/test.dart';

const dbMariadb = "mariadb";
const dbPostgres = "postgres";
void main() async {
  setUp(() async {
    initLogger();

    // the first db will be the default one as well
    Database.register(dbMariadb, await initMariaDb());
    Database.register(dbPostgres, await initPostgreSQL());
  });

  tearDown(() async {
    // await Database.closeAll();
  });
  test('testLob', testLob);

  // exit(0);
}

Future<void> testLob() async {
  var log = Logger('$logPrefix testLob');

  var book = Book()
    ..price = 0.3
    ..title = 'Dart'
    ..content = 'Long Long Text here' * 1000
    ..image = Uint8List.fromList(List.filled(300, 5));
  await book.insert();

  log.info('\t book saved with id: ${book.id}');

  var books = await Book.query().findList();
  log.info('books list: $books');
  for (var book in books) {
    log.info('book image : ${book.image}, content: ${book.content}');
  }
}
