import 'table.dart';

abstract class Schema {
  void drop(String tableName, {bool cascade = false});

  void dropAll(Iterable<String> tableNames, {bool cascade = false}) {
    for (var n in tableNames) {
      drop(n, cascade: cascade);
    }
  }

  void create(String tableName, void Function(MigrationTable table) callback,
      {String? comment});

  void createIfNotExists(
      String tableName, void Function(MigrationTable table) callback,
      {String? comment});

  void alter(String tableName, void Function(MutableTable table) callback);
}
