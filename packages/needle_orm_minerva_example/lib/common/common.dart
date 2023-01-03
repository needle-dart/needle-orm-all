import 'dart:async';

import 'package:logging/logging.dart';
import 'package:minerva/minerva.dart' hide Logger;
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';
import 'package:needle_orm_postgres/needle_orm_postgres.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:stack_trace/stack_trace.dart';

Future<MySqlConnection> initMariaConnection(Map<String, dynamic> params) async {
  var settings = ConnectionSettings(
    host: params['host'],
    port: params['port'],
    db: params['database'],
    user: params['username'],
    password: params['password'],
  );
  return await MySqlConnection.connect(settings);
}

Future<Database> initMariaDb(Map<String, dynamic> params) async {
  return MariaDbDatabase(
      await initMariaConnection(params)); // used in domain.dart
}

Future<PgPool> initPgPool(Map<String, dynamic> params) async {
  return PgPool(
    PgEndpoint(
      host: params['host'],
      port: params['port'],
      database: params['database'],
      username: params['username'],
      password: params['password'],
    ),
    settings: PgPoolSettings()
      ..maxConnectionAge = Duration(hours: 1)
      ..concurrency = params['pool-size'] ?? 5,
  );
}

Future<PostgreSQLConnection> initPostgreSQLConnection(
    Map<String, dynamic> params) async {
  return PostgreSQLConnection(
    params['host'],
    params['port'],
    params['database'],
    username: params['username'],
    password: params['password'],
  );
}

Future<Database> initPostgreSQL(Map<String, dynamic> params) async {
  return PostgreSqlPoolDatabase(await initPgPool(params));
}

/// forward inner Logger to LogPipeline
void initLogger(LogPipeline logPipeline) {
  Logger.root.level = Level.CONFIG; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    var trace = Trace.current().terse;
    var frame = trace.frames
        .skip(2)
        .where((element) => element.member != null)
        .firstWhere((element) => !element.member!.startsWith("Logger"));
    var frameInfo = "(${frame.location})";

    Future<void> Function(dynamic) fun;
    if (record.level == Level.INFO) {
      fun = logPipeline.info;
    } else if (record.level == Level.WARNING) {
      fun = logPipeline.warning;
    } else if (record.level == Level.SEVERE) {
      fun = logPipeline.error;
    } else if (record.level == Level.SHOUT) {
      fun = logPipeline.critical;
    } else if (record.level == Level.CONFIG) {
      fun = logPipeline.debug;
    } else {
      fun = logPipeline.debug;
    }

    if (record.stackTrace != null) {
      fun('${record.loggerName} $frameInfo: ${record.message}: ${record.error ?? ''} \n${record.stackTrace}');
    } else {
      fun('${record.loggerName} $frameInfo: ${record.message}: ${record.error ?? ''}');
    }
  });
}
