import 'column.dart';

abstract class MigrationTable {
  MigrationColumn declareColumn(String name, TableColumn column);

  MigrationColumn declare(String name, ColumnType type, {String? comment}) =>
      declareColumn(name, MigrationColumn(type, comment: comment));

  MigrationColumn serial(String name, {String? comment}) =>
      declare(name, ColumnType.serial, comment: comment);

  MigrationColumn integer(String name, {String? comment}) =>
      declare(name, ColumnType.int, comment: comment);

  MigrationColumn float(String name, {String? comment}) =>
      declare(name, ColumnType.float, comment: comment);

  MigrationColumn double(String name, {String? comment}) =>
      declare(name, ColumnType.double, comment: comment);

  MigrationColumn binary(String name, {String? comment}) =>
      declare(name, ColumnType.binary, comment: comment);

  MigrationColumn blob(String name, {String? comment}) =>
      declare(name, ColumnType.blob, comment: comment);

  MigrationColumn clob(String name, {String? comment}) =>
      declare(name, ColumnType.clob, comment: comment);

  MigrationColumn numeric(String name,
      {int precision = 17, int scale = 3, String? comment}) {
    return declare(name, ColumnType.numeric, comment: comment);
  }

  MigrationColumn boolean(String name, {String? comment}) =>
      declare(name, ColumnType.boolean, comment: comment);

  MigrationColumn date(String name, {String? comment}) =>
      declare(name, ColumnType.date, comment: comment);

  //@deprecated
  //MigrationColumn dateTime(String name) => timeStamp(name, timezone: true);

  MigrationColumn timeStamp(String name,
      {bool timezone = false, String? comment}) {
    if (!timezone) {
      return declare(name, ColumnType.timeStamp, comment: comment);
    }
    return declare(name, ColumnType.timeStampWithTimeZone, comment: comment);
  }

  MigrationColumn text(String name, {String? comment}) =>
      declare(name, ColumnType.text, comment: comment);

  MigrationColumn varChar(String name, {int? length, String? comment}) {
    if (length == null) {
      return declare(name, ColumnType.varChar, comment: comment);
    }
    return declareColumn(
        name,
        TableColumn(
            type: ColumnType.varChar, length: length, comment: comment));
  }
}

abstract class MutableTable extends MigrationTable {
  void rename(String newName);
  void dropColumn(String name);
  void renameColumn(String name, String newName);
  void changeColumnType(String name, ColumnType type);
  void dropNotNull(String name);
  void setNotNull(String name);
}
