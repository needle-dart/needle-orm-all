const toBool = r'''
  bool? toBool(value) {
    if (value == null) return null;
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value != 0;
    } else if (value is String) {
      return value != 'true';
    }
    throw '${value.runtimeType}($value) can not be converted to bool';
  }
''';

const strModelCache = r'''
/// cache bound with a top query
class _QueryModelCache {
  // ignore: library_private_types_in_public_api
  Map<String, List<Model>> cacheMap = {};

  _QueryModelCache();

  // ignore: library_private_types_in_public_api
  void add(Model m) {
    var className = ModelInspector.getClassName(m);
    var list = cacheMap[className] ?? [];
    if (!list.contains(m)) {
      list.add(m);
    }
    cacheMap[className] = list;
  }

  // ignore: library_private_types_in_public_api
  Iterable<Model> findUnloadedList(String className) {
    cacheMap[className] ??= [];
    return cacheMap[className]!.where((e) => !ModelInspector.storeLoaded(e));
  }

  Model? find(String className, dynamic id) {
    var idName = ModelInspector.idFields(className)!.first.name;
    var r = cacheMap[className]?.where(
        (m) => ModelInspector.lookup(className).getFieldValue(m, idName) == id);
    if (r?.isEmpty ?? true) {
      return null;
    } else {
      return r!.first;
    }
  }
}
''';

const strModelMixin = r'''
mixin ModelMixin<T> on TableQuery<T> {
  IntColumn get id => IntColumn(this, "id");
}''';

const strFieldFilter = r'''
  /// support toMap(fields:'*'), toMap(fields:'name,price,author(*),editor(name,email)')
  class _FieldFilter {
    final String fields;
    final String? idField;

    List<String> _fieldList = [];

    List<String> get fieldList => List.of(_fieldList);

    _FieldFilter(this.fields, this.idField) {
      _fieldList = _parseFields();
    }

    bool contains(String field) {
      if (shouldIncludeIdFields()) {
        if (field == idField) {
          return true;
        }
      }
      return fieldList.any(
          (name) => name == '*' || name == field || name.startsWith('$field('));
    }

    bool shouldIncludeIdFields() {
      return fields.trim().isEmpty;
    }

    String subFilter(String field) {
      List<String> subList = fieldList
          .where((name) => name == field || name.startsWith('$field('))
          .toList();
      if (subList.isEmpty) {
        return '';
      }
      var str = subList.first;
      int i = str.indexOf('(');
      if (i != -1) {
        return str.substring(i + 1, str.length - 1);
      }
      return '';
    }

    List<String> _parseFields() {
      var result = <String>[];
      var str = fields.trim().replaceAll(' ', '');
      int j = 0;
      for (int i = 1; i < str.length; i++) {
        if (str[i] == ',') {
          result.add(str.substring(j, i));
          j = i + 1;
        } else if (str[i] == '(') {
          int k = _readTillParenthesisEnd(str, i + 1);
          if (k == -1) {
            throw '( and ) do NOT match';
          }
          i = k;
        }
      }
      if (j < str.length) {
        result.add(str.substring(j));
      }
      return result;
    }

    int _readTillParenthesisEnd(String str, int index) {
      int left = 1;
      for (; index < str.length; index++) {
        if (str[index] == ')') {
          left--;
        } else if (str[index] == '(') {
          left++;
        }
        if (left == 0) {
          return index;
        }
      }
      return -1;
    }
  }

''';

var strOrmMetaInfoModel = """
class _OrmMetaInfoModel extends OrmMetaClass {
  _OrmMetaInfoModel()
      : super('Model', isAbstract: true, superClassName: null, ormAnnotations: [
          Entity(),
        ], fields: [
          OrmMetaClass.idField,
        ], methods: []);
}
""";
