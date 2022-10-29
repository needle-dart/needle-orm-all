import 'dart:math';

import 'package:minerva/minerva.dart';

import './common.dart';
import './domain.dart';

import 'dart:async';

import 'package:needle_orm/needle_orm.dart';

var _inited = false;
final random = Random();

Future<void> initService(ServerContext context) async {
  if (_inited) return;
  context.logPipeline.info('init services ...');
  _inited = true;

  var configuration = ConfigurationManager();

  await configuration.load();
  Map<String, dynamic> dataSources = configuration['data-sources'];
  // initLogger();

  var dsName = dataSources['default'];
  var dsCfg = dataSources[dsName]!;

  if (dsCfg['type'] == 'postgresql') {
    Database.register(dsName, await initPostgreSQL(dsCfg));
  } else if (dsCfg['type'] == 'mariadb') {
    Database.register(dsName, await initMariaDb(dsCfg));
  }
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
