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

const strBaseQuery = r'''
abstract class _BaseModelQuery<T extends Model> extends BaseModelQuery<T> {
  late _QueryModelCache _modelCache;
  final logger = Logger('_BaseModelQuery');

  _BaseModelQuery({BaseModelQuery? topQuery, String? propName, Database? db})
      : super(db ?? Database.defaultDb,
            topQuery: topQuery, propName: propName) {
    _modelCache = _QueryModelCache();
  }

  void cache(Model m) {
    _modelCache.add(m);
  }

  @override
  Future<void> ensureLoaded(Model m, {int batchSize = 1}) async {
    var inspector = _inspector(m);
    if (inspector.isStoreLoaded(m)) return;
    var className = ModelInspector.getClassName(m);
    var idFieldName = ModelInspector.idFields(className)![0].name;

    List<Model> modelList;

    if (batchSize > 1) {
      modelList = _modelCache.findUnloadedList(className).toList();

      // limit to 100 rows
      if (modelList.length > batchSize) {
        modelList = modelList.sublist(0, batchSize);
      }
      // maybe 101 here
      if (!modelList.contains(m)) {
        logger.info('\t not contains , add now ...');
        modelList.add(m);
      }
    } else {
      modelList = [m];
    }
    var modelInspector = ModelInspector.lookup(className);
    List<dynamic> idList = modelList
        .map((e) => modelInspector.getFieldValue(e, idFieldName))
        .toSet()
        .toList(growable: false);
    var newQuery = modelInspector.newQuery(db, className);
    var modelListResult =
        await newQuery.findByIds(idList, existModeList: modelList);
    for (Model m in modelListResult) {
      _inspector(m).markLoaded(m);
    }
    _inspector(m).markLoaded(m);
    // lock.release();
  }

  ModelInspector _inspector(Model m) => ModelInspector.lookup(className);

  @override
  Future<T?> findById(dynamic id,
      {T? existModel, bool includeSoftDeleted = false}) async {
    var model = await super.findById(id,
        existModel: existModel, includeSoftDeleted: includeSoftDeleted);
    if (model != null) {
      _inspector(model).postLoad(model);
    }
    return model;
  }

  /// find models by [idList]
  @override
  Future<List<T>> findByIds(List idList,
      {List<Model>? existModeList, bool includeSoftDeleted = false}) async {
    var list = await super.findByIds(idList, existModeList: existModeList);
    for (var model in list) {
      _inspector(model).postLoad(model);
    }
    return list;
  }

  @override
  Future<List<T>> findBy(Map<String, dynamic> params,
      {List<Model>? existModeList, bool includeSoftDeleted = false}) async {
    var list = await super.findBy(params,
        existModeList: existModeList, includeSoftDeleted: includeSoftDeleted);
    for (var model in list) {
      _inspector(model).postLoad(model);
    }
    return list;
  }

  /// find list
  @override
  Future<List<T>> findList({bool includeSoftDeleted = false}) async {
    var list = await super.findList();
    for (var model in list) {
      _inspector(model).postLoad(model);
    }
    return list;
  }
}

''';

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
