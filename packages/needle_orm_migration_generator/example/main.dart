import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm_migration_runner/mariadb.dart';
import 'package:needle_orm_migration_runner/needle_orm_migration_runner.dart';

import 'src/domain.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });
  args = ['refresh'];
  var settings = new ConnectionSettings(
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
