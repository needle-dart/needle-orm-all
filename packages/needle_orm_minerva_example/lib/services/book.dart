import 'dart:math';

import 'package:minerva/minerva.dart';

import '../common/ncontext.dart';
import './domain.dart';

import 'dart:async';

final random = Random();

Future<Book?> findOneBook(ServerContext context, MinervaRequest request) async {
  LogPipeline logger = NContext.current!.logger!;
  logger.info("username: ${NContext.current?.auth?.user?.loginName}");

  var q = BookQuery()..paging(0, 1);

  var books = await q.findList();
  if (books.isNotEmpty) {
    return books[0];
  }
  return null;
}

Future<List<Book>> findSomeBooks(
    ServerContext context, MinervaRequest request) async {
  var q = BookQuery()..paging(0, 5);

  return await q.findList()
    ..forEach((book) {
      book.extra = {"bbq": "bbqbbq"};
    });
}

Future<List<Map>> findSomeBooks2(
    ServerContext context, MinervaRequest request) async {
  var q = BookQuery()..paging(0, 5);

  var books = await q.findList();

  for (var book in books) {
    book.extra = {"bbq": "bbqbbq"};
    // await book.author?.load(batchSize: 1000);
  }
  return books
      .map((e) => e.toMap(fields: "id,title,price,author(id,address)"))
      .toList();
}

Future<Book?> createOneBook(
    ServerContext context, MinervaRequest request) async {
  var book = Book();
  book.title = 'title ' * (random.nextInt(10) + 1);
  book.price = random.nextDouble();
  await book.save();
  return book;
}
