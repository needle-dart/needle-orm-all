import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';
import 'package:needle_orm_postgres/needle_orm_postgres.dart';
import 'package:postgres_pool/postgres_pool.dart';

final logPrefix = 'MainTest';
final log = Logger(logPrefix);
late Database globalDb;

Future<Database> initMariaDb() async {
  Logger.root.level = Level.CONFIG; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    if (record.stackTrace != null) {
      stderr.writeln(
          '${record.level.name}: ${record.time.toString().padRight(24, '0').substring(0, 24)} ${record.loggerName}: ${record.message}: ${record.error ?? ''} \n${record.stackTrace}');
    } else {
      print(
          '${record.level.name}: ${record.time.toString().padRight(24, '0').substring(0, 24)} ${record.loggerName}: ${record.message}: ${record.error ?? ''}');
    }
  });

  var settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'needle',
      password: 'needle',
      db: 'needle');
  var conn = await MySqlConnection.connect(settings);

  return MariaDbDatabase(conn); // used in domain.dart
}

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
