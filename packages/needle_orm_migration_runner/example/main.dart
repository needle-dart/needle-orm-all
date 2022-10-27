import 'package:needle_orm_migration/needle_orm_migration.dart';
import 'package:needle_orm_migration_runner/mysql.dart';
import 'package:needle_orm_migration_runner/needle_orm_migration_runner.dart';
import 'package:needle_orm_migration_runner/postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:mysql_client/mysql_client.dart';

import 'todo.dart';

void main(List<String> args) async {
  var postgresqlMigrationRunner = PostgresMigrationRunner(
    PostgreSQLConnection('localhost', 5432, 'demo',
        username: 'demouser', password: 'demo123'),
    migrations: [
      UserMigration(),
      TodoMigration(),
      FooMigration(),
    ],
  );

  var mySQLConn = await MySQLConnection.createConnection(
      host: "localhost",
      port: 3306,
      databaseName: "orm_test",
      userName: "test",
      password: "Test123*",
      secure: false);

  var mysqlMigrationRunner = MySqlMigrationRunner(
    mySQLConn,
    migrations: [
      UserMigration(),
      TodoMigration(),
      FooMigration(),
    ],
  );

  runMigrations(postgresqlMigrationRunner, args);
  runMigrations(mysqlMigrationRunner, args);
}

class FooMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('foos', (table) {
      table
        ..serial('id').primaryKey()
        ..varChar('bar', length: 64)
        ..timeStamp('created_at').defaultsTo(currentTimestamp);
    });
  }

  @override
  void down(Schema schema) => schema.drop('foos');
}
