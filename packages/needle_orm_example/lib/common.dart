import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';
import 'package:needle_orm_postgres/needle_orm_postgres.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:stack_trace/stack_trace.dart';

const logPrefix = 'NeedleOrmExample';
final logger = Logger(logPrefix);
late Database globalDb;

Future<MySqlConnection> initMariaConnection() async {
  var settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'needle',
      password: 'needle',
      db: 'needle');
  return await MySqlConnection.connect(settings);
}

Future<Database> initMariaDb() async {
  return MariaDbDatabase(await initMariaConnection()); // used in domain.dart
}

Future<PgPool> initPgPool() async {
  return PgPool(
    PgEndpoint(
      host: 'localhost',
      port: 5432,
      database: 'needle',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: PgPoolSettings()
      ..maxConnectionAge = Duration(hours: 1)
      ..concurrency = 5,
  );
}

Future<PostgreSQLConnection> initPostgreSQLConnection() async {
  return PostgreSQLConnection(
    'localhost',
    5432,
    'needle',
    username: 'postgres',
    password: 'postgres',
  );
}

Future<Database> initPostgreSQL() async {
  return PostgreSqlPoolDatabase(await initPgPool());
}

void initLogger() {
  Logger.root.level = Level.CONFIG; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    var trace = Trace.current().terse;
    var frame = trace.frames
        .skip(2)
        .where((element) => element.member != null)
        .firstWhere((element) => !element.member!.startsWith("Logger"));
    var frameInfo = "(${frame.location})";
    if (record.stackTrace != null) {
      stderr.writeln(
          '${record.level.name}: ${record.time.toString().padRight(24, '0').substring(0, 24)} ${record.loggerName} $frameInfo: ${record.message}: ${record.error ?? ''} \n${record.stackTrace}');
    } else {
      print(
          '${record.level.name}: ${record.time.toString().padRight(24, '0').substring(0, 24)} ${record.loggerName} $frameInfo: ${record.message}: ${record.error ?? ''}');
    }
  });
}
