import 'dart:math';

import 'package:minerva/minerva.dart';

import './domain.dart';

import 'dart:async';

final random = Random();

Future<Book?> findOneBook(ServerContext context, MinervaRequest request) async {
  var q = BookQuery();
  q.maxRows = 1;

  var books = await q.findList();
  if (books.isNotEmpty) {
    return books[0];
  }
  return null;
}

Future<List<Book>> findSomeBooks(
    ServerContext context, MinervaRequest request) async {
  var q = BookQuery();
  q.maxRows = 5;

  return await q.findList()
    ..forEach((book) {
      book.extra = {"bbq": "bbqbbq"};
    });
}

Future<Book?> createOneBook(
    ServerContext context, MinervaRequest request) async {
  var book = Book();
  book.title = 'title ' * (random.nextInt(10) + 1);
  book.price = random.nextDouble();
  await book.save();
  return book;
}
