import 'package:needle_orm/impl.dart';

import '../api.dart';
import 'package:intl/intl.dart';

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

//
dynamic convertValue(dynamic value, OrmMetaField field, DbType dbType) {
  if (value is String && field.elementType == 'int') {
    return int.parse(value);
  }
  if (dbType.category == DbCategory.Sqlite) {
    if (field.elementType == 'DateTime' && value != null && value is String) {
      return _df.parse(value);
    }
  }
  return value;
}

final _df = DateFormat('yyyy-MM-dd HH:mm:ss');
