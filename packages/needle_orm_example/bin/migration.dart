import 'package:angel3_migration_runner/angel3_migration_runner.dart';
import 'package:angel3_migration_runner/mariadb.dart';
import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';

import 'package:needle_orm_example/domain.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });

  args = ['refresh'];
  var settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'needle',
      password: 'needle',
      db: 'needle');
  var conn = await MySqlConnection.connect(settings);

  var migrationRunner = MariaDbMigrationRunner(conn, migrations: [
    BookMigration(),
    UserMigration(),
  ]);
  await runMigrations(migrationRunner, args);
}
