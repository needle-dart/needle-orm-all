import 'package:minerva/minerva.dart';
import 'package:needle_orm/api.dart';
import 'package:needle_orm_minerva_example/common/common.dart';

import 'package:needle_orm_minerva_example/services/domain.mig.dart';
import 'package:needle_orm_migration_runner/mariadb.dart';
import 'package:needle_orm_migration_runner/needle_orm_migration_runner.dart';
import 'package:needle_orm_migration_runner/postgres.dart';
import 'package:needle_orm_migration_runner/sqlite.dart';

void main(List<String> args) async {
  args = ['refresh'];

  var configuration = ConfigurationManager();

  await configuration.load();
  Map<String, dynamic> dataSources = configuration['data-sources'];
  // initLogger();

  var dsName = dataSources['default'];
  var dsCfg = dataSources[dsName]!;

  if (dsCfg['type'] == 'postgresql') {
    Database.register(dsName, await initPostgreSQL(dsCfg));
    var migrationRunner = PostgresMigrationRunner(
        await initPostgreSQLConnection(dsCfg),
        migrations: allMigrations);
    await runMigrations(migrationRunner, args);
  } else if (dsCfg['type'] == 'mariadb') {
    Database.register(dsName, await initMariaDb(dsCfg));
    var migrationRunner = MariaDbMigrationRunner(
        await initMariaConnection(dsCfg),
        migrations: allMigrations);
    await runMigrations(migrationRunner, args);
  } else if (dsCfg['type'] == 'sqlite') {
    Database.register(dsName, await initSqlite(dsCfg));
    var migrationRunner =
        SqliteMigrationRunner(dsCfg['path'], migrations: allMigrations);
    await runMigrations(migrationRunner, args);
  }
}
