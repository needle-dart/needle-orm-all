import 'package:inflection3/inflection3.dart';
import 'package:recase/recase.dart';

/// generate table name based on [className]
String genTableName(String className) {
  return pluralize(ReCase(className).snakeCase);
}

/// generate table name based on [className]
String genColumnName(String fieldName) {
  return ReCase(fieldName).snakeCase;
}
