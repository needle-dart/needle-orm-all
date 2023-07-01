import 'package:inflection3/inflection3.dart';
import 'package:needle_orm/src/sql.dart';
import 'package:recase/recase.dart';

import '../api.dart';

/// generate table name based on [className]
String genTableName(String className) {
  return pluralize(ReCase(className).snakeCase);
}

/// generate table name based on [className]
String genColumnName(String fieldName) {
  return ReCase(fieldName).snakeCase;
}

String serverNowExpr(DbType dbType) {
  return switch (dbType.category) {
    DbCategory.PostgreSQL => "'now()'",
    DbCategory.MariaDB => "now()",
    DbCategory.Sqlite => "datetime('now')"
  };
}

String serverSideExpr(OrmAnnotation ann, ActionType action, DbType dbType) {
  switch (ann.runtimeType) {
    case WhenCreated:
      if (action == ActionType.insert) {
        return serverNowExpr(dbType);
      }
    case WhenModified:
      if (action == ActionType.update || action == ActionType.insert) {
        return serverNowExpr(dbType);
      }
  }
  return '';
}
