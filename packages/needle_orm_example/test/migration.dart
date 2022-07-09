import 'package:angel3_migration_runner/angel3_migration_runner.dart';
import 'package:angel3_migration_runner/mariadb.dart';
import 'package:angel3_migration_runner/postgres.dart';
import 'package:logging/logging.dart';
import 'package:needle_orm_example/common.dart';

import 'package:needle_orm_example/domain.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });

  args = ['refresh'];

  {
    var migrationRunner =
        MariaDbMigrationRunner(await initMariaConnection(), migrations: [
      BookMigration(),
      UserMigration(),
    ]);
    await runMigrations(migrationRunner, args);
  }

  {
    var migrationRunner =
        PostgresMigrationRunner(await initPostgreSQLConnection(), migrations: [
      BookMigration(),
      UserMigration(),
    ]);
    await runMigrations(migrationRunner, args);
  }
}
