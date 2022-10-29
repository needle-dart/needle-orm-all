import 'dart:math';

import 'package:minerva/minerva.dart';

import './common.dart';
import './domain.dart';

import 'dart:async';

import 'package:needle_orm/needle_orm.dart';

const dbMariadb = "mariadb";
const dbPostgres = "postgres";

var _inited = false;
final random = Random();

Future<void> initService(ServerContext context) async {
  if (_inited) return;
  context.logPipeline.info('do service init ');
  _inited = true;
  // initLogger();

  // the first db will be the default one as well
  Database.register(dbPostgres, await initPostgreSQL());
  // Database.register(dbMariadb, await initMariaDb());
}

Future<Book?> findOneBook(ServerContext context, MinervaRequest request) async {
  await initService(context);
  var q = Book.query();
  q.maxRows = 1;

  var books = await q.findList();
  if (books.isNotEmpty) {
    return books[0];
  }
  return null;
}

Future<List<Book>> findSomeBooks(
    ServerContext context, MinervaRequest request) async {
  await initService(context);
  var q = Book.query();
  q.maxRows = 5;

  return await q.findList();
}

Future<Book?> createOneBook(
    ServerContext context, MinervaRequest request) async {
  await initService(context);
  var book = Book();
  book.title = 'title ' * (random.nextInt(10) + 1);
  book.price = random.nextDouble();
  await book.save();
  return book;
}
