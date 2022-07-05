import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';
import 'package:test/test.dart';

void main() {
  Logger.root.level = Level.CONFIG;
  Logger.root.onRecord.listen((record) {
    if (record.stackTrace != null) {
      stderr.writeln(
          '${record.level.name}: ${record.time.toString().padRight(24, '0').substring(0, 24)} ${record.loggerName}: ${record.message}: ${record.stackTrace}');
    } else {
      print(
          '${record.level.name}: ${record.time.toString().padRight(24, '0').substring(0, 24)} ${record.loggerName}: ${record.message}');
    }
  });

  test('test IN', () async {
    var settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'needle',
        password: 'needle',
        db: 'needle');
    var conn = await MySqlConnection.connect(settings);
    var ds = MariaDbDatabase(conn);

    var list = await ds.query("select * from books where id in @idList", {
      'idList': [1, 16]
    });
    for (var book in list) {
      print(book);
    }
  });

  test('test transaction', () async {
    var settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'needle',
        password: 'needle',
        db: 'needle');
    var conn = await MySqlConnection.connect(settings);

    await conn.transaction((ctx) async {
      var n = 50;
      for (int i = 1; i < n; i++) {
        await ctx.query("insert into users(name,address) values(?, ?)",
            ['name ' * i, 'China shanghai pudong new district ' * i]);
        print('inserted: $i');
      }
    });
  });
  test('test transaction2', () async {
    var logger = Logger('testTransaction2');
    var settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'needle',
        password: 'needle',
        db: 'needle');
    var conn = await MySqlConnection.connect(settings);
    var db = MariaDbDatabase(conn);

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
      print('okok: $s');
    } catch (e, s) {
      logger.severe('test error', e, s);
    } finally {
      logger.info('test end');
    }
  });
}
