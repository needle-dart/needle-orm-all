// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// NeedleOrmMetaInfoGenerator
// **************************************************************************

abstract class __Model extends Model {
  // abstract begin

  // String get __tableName;
  String get __className;
  String? get __idFieldName;

  // ignore: unused_element
  dynamic __getField(String fieldName, {errorOnNonExistField = true});
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField = true});

  // abstract end

  // mark whether this instance is loaded from db.
  bool __dbLoaded = false; // if fields has been loaded from db.
  bool __dbAttached = false; // if this instance is created by Query
  _BaseModelQuery? __topQuery;

  // mark all modified fields after loaded
  final __dirtyFields = <String>{};

  void loadMap(Map<String, dynamic> m, {errorOnNonExistField = false}) {
    m.forEach((key, value) {
      __setField(key, value, errorOnNonExistField: errorOnNonExistField);
    });
  }

  void __markDirty(String fieldName) {
    __dirtyFields.add(fieldName);
  }

  void __cleanDirty() {
    __dirtyFields.clear();
  }

  // String __dirtyValues() {
  //   return __dirtyFields.map((e) => "${e.toLowerCase()} : ${__getField(e)}").join(", ");
  // }

  void __markAttached(bool attached, _BaseModelQuery topQuery) {
    __dbAttached = attached;
    __topQuery = topQuery;
    topQuery.cache(this);
  }

  void __markLoaded(bool loaded) {
    __dbLoaded = loaded;
  }

  @override
  Future<void> load({int batchSize = 1}) async {
    if (__dbAttached && !__dbLoaded) {
      await __topQuery?.ensureLoaded(this, batchSize: batchSize);
    }
  }

  void __ensureLoaded() {
    if (__dbAttached && !__dbLoaded) {
      throw 'should call load() before accessing properties!';
      // __topQuery?.ensureLoaded(this);
    }
  }

  BaseModelQuery __query(Database? db) =>
      _modelInspector.newQuery(db ?? _globalDb, __className);

  Future<void> insert({Database? db}) async {
    __prePersist();
    await __query(db).insert(this);
    __postPersist();
  }

  Future<void> update({Database? db}) async {
    __preUpdate();
    await __query(db).update(this);
    __postUpdate();
  }

  Future<void> save({Database? db}) async {
    if (__idFieldName == null) throw 'no @ID field';

    if (__getField(__idFieldName!) != null) {
      await update(db: db);
    } else {
      await insert(db: db);
    }
  }

  Future<void> delete({Database? db}) async {
    __preRemove();
    await __query(db).deleteOne(this);
    __postRemove();
  }

  Future<void> deletePermanent({Database? db}) async {
    __preRemovePermanent();
    await __query(db).deleteOnePermanent(this);
    __postRemovePermanent();
  }

  void __prePersist() {}
  void __preUpdate() {}
  void __preRemove() {}
  void __preRemovePermanent() {}
  void __postPersist() {}
  void __postUpdate() {}
  void __postRemove() {}
  void __postRemovePermanent() {}
  void __postLoad() {}
}

/// cache bound with a top query
class QueryModelCache {
  final ModelInspector modelInspector;

  // ignore: library_private_types_in_public_api
  Map<String, List<__Model>> cacheMap = {};

  QueryModelCache(this.modelInspector);

  // ignore: library_private_types_in_public_api
  void add(__Model m) {
    var className = modelInspector.getClassName(m);
    var list = cacheMap[className] ?? [];
    if (!list.contains(m)) {
      list.add(m);
    }
    cacheMap[className] = list;
  }

  // ignore: library_private_types_in_public_api
  Iterable<__Model> findUnloadedList(String className) {
    cacheMap[className] ??= [];
    return cacheMap[className]!.where((e) => !e.__dbLoaded);
  }
}

/// support toMap(fields:'*'), toMap(fields:'name,price,author(*),editor(name,email)')
class FieldFilter {
  final String fields;
  final String? idField;

  List<String> _fieldList = [];

  List<String> get fieldList => List.of(_fieldList);

  FieldFilter(this.fields, this.idField) {
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

abstract class _BaseModelQuery<T extends __Model, D>
    extends BaseModelQuery<T, D> {
  late QueryModelCache _modelCache;
  final logger = Logger('_BaseModelQuery');

  _BaseModelQuery({BaseModelQuery? topQuery, String? propName, Database? db})
      : super(_modelInspector, db ?? _globalDb,
            topQuery: topQuery, propName: propName) {
    _modelCache = QueryModelCache(modelInspector);
  }

  void cache(__Model m) {
    _modelCache.add(m);
  }

  Future<void> ensureLoaded(Model m, {int batchSize = 1}) async {
    if ((m as __Model).__dbLoaded) return;
    var className = modelInspector.getClassName(m);
    var idFieldName = m.__idFieldName;
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

    List<dynamic> idList = modelList
        .map((e) => modelInspector.getFieldValue(e, idFieldName!))
        .toSet()
        .toList(growable: false);
    var newQuery = modelInspector.newQuery(db, className);
    var modelListResult =
        await newQuery.findByIds(idList, existModeList: modelList);
    for (Model m in modelListResult) {
      (m as __Model).__markLoaded(true);
    }
    m.__markLoaded(true);
    // lock.release();
  }
}

class _ModelInspector extends ModelInspector<__Model> {
  @override
  String getClassName(__Model obj) {
    return obj.__className;
  }

  @override
  get allOrmMetaClasses => _allOrmClasses;

  @override
  OrmMetaClass? meta(String className) {
    var list =
        _allOrmClasses.where((element) => element.name == className).toList();
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  @override
  dynamic getFieldValue(__Model obj, String fieldName) {
    return obj.__getField(fieldName);
  }

  @override
  void setFieldValue(__Model obj, String fieldName, dynamic value) {
    obj.__setField(fieldName, value);
  }

  @override
  void markDeleted(__Model obj, bool deleted) {
    var clz = meta(getClassName(obj))!;
    var softDeleteField = clz.softDeleteField;
    if (softDeleteField == null) {
      return;
    }
    setFieldValue(obj, softDeleteField.name, deleted);
    obj.__markDirty(softDeleteField.name);
  }

  @override
  Map<String, dynamic> getDirtyFields(__Model model) {
    var map = <String, dynamic>{};
    for (var name in model.__dirtyFields) {
      map[name] = model.__getField(name);
    }
    return map;
  }

  @override
  void loadModel(__Model model, Map<String, dynamic> m,
      {errorOnNonExistField = false}) {
    model.loadMap(m, errorOnNonExistField: false);
    model.__dbAttached = true;
    model.__dbLoaded = true;
    model.__cleanDirty();
  }

  @override
  __Model newInstance(String className,
      {bool attachDb = false, required BaseModelQuery topQuery}) {
    switch (className) {
      case 'Book':
        return Book()..__markAttached(true, topQuery as _BaseModelQuery);
      case 'User':
        return User()..__markAttached(true, topQuery as _BaseModelQuery);
      case 'Job':
        return Job()..__markAttached(true, topQuery as _BaseModelQuery);
      default:
        throw 'unknown class : $className';
    }
  }

  @override
  BaseModelQuery newQuery(Database db, String name) {
    switch (name) {
      case 'Book':
        return BookModelQuery(db: db);
      case 'User':
        return UserModelQuery(db: db);
      case 'Job':
        return JobModelQuery(db: db);
    }
    throw 'Unknow Query Name: $name';
  }

  @override
  void markLoaded(__Model model) {
    model.__markLoaded(true);
  }
}

final _ModelInspector _modelInspector = _ModelInspector();

class OrmMetaInfoBaseModel extends OrmMetaClass {
  OrmMetaInfoBaseModel()
      : super('BaseModel', _modelInspector,
            isAbstract: true,
            superClassName: 'Object',
            ormAnnotations: [
              Entity(),
            ],
            fields: [
              OrmMetaField('id', 'int?', ormAnnotations: [
                ID(),
              ]),
              OrmMetaField('version', 'int?', ormAnnotations: [
                Version(),
              ]),
              OrmMetaField('deleted', 'bool?', ormAnnotations: [
                SoftDelete(),
              ]),
              OrmMetaField('createdAt', 'DateTime?', ormAnnotations: [
                WhenCreated(),
              ]),
              OrmMetaField('updatedAt', 'DateTime?', ormAnnotations: [
                WhenModified(),
              ]),
              OrmMetaField('createdBy', 'String?', ormAnnotations: [
                WhoCreated(),
              ]),
              OrmMetaField('lastUpdatedBy', 'String?', ormAnnotations: [
                WhoModified(),
              ]),
              OrmMetaField('remark', 'String?', ormAnnotations: [
                Column(),
              ]),
            ]);
}

class OrmMetaInfoBook extends OrmMetaClass {
  OrmMetaInfoBook()
      : super('Book', _modelInspector,
            isAbstract: false,
            superClassName: 'BaseModel',
            ormAnnotations: [
              Table(),
              Entity(ds: "mysql_example_db"),
            ],
            fields: [
              OrmMetaField('title', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('price', 'double?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('author', 'User?', ormAnnotations: [
                ManyToOne(),
              ]),
            ]);
}

class OrmMetaInfoUser extends OrmMetaClass {
  OrmMetaInfoUser()
      : super('User', _modelInspector,
            isAbstract: false,
            superClassName: 'BaseModel',
            ormAnnotations: [
              Table(name: 'users'),
              Entity(
                  ds: Entity.DEFAULT_DB,
                  prePersist: 'beforeInsert',
                  postPersist: 'afterInsert'),
            ],
            fields: [
              OrmMetaField('name', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('loginName', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('address', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('age', 'int?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('books', 'List<_Book>?', ormAnnotations: [
                OneToMany(mappedBy: "_author"),
              ]),
            ]);
}

class OrmMetaInfoJob extends OrmMetaClass {
  OrmMetaInfoJob()
      : super('Job', _modelInspector,
            isAbstract: false,
            superClassName: 'BaseModel',
            ormAnnotations: [
              Entity(),
            ],
            fields: [
              OrmMetaField('name', 'String?', ormAnnotations: [
                Column(),
              ]),
            ]);
}

final _allOrmClasses = [
  OrmMetaInfoBaseModel(),
  OrmMetaInfoBook(),
  OrmMetaInfoUser(),
  OrmMetaInfoJob()
];

// **************************************************************************
// NeedleOrmModelGenerator
// **************************************************************************

class BaseModelModelQuery<T extends BaseModel> extends _BaseModelQuery<T, int> {
  @override
  String get className => 'BaseModel';

  BaseModelModelQuery(
      // ignore: library_private_types_in_public_api
      {_BaseModelQuery? topQuery,
      String? propName,
      Database? db})
      : super(topQuery: topQuery, propName: propName, db: db);

  IntColumn id = IntColumn("id");
  IntColumn version = IntColumn("version");
  BoolColumn deleted = BoolColumn("deleted");
  DateTimeColumn createdAt = DateTimeColumn("createdAt");
  DateTimeColumn updatedAt = DateTimeColumn("updatedAt");
  StringColumn createdBy = StringColumn("createdBy");
  StringColumn lastUpdatedBy = StringColumn("lastUpdatedBy");
  StringColumn remark = StringColumn("remark");

  @override
  List<ColumnQuery> get columns => [
        id,
        version,
        deleted,
        createdAt,
        updatedAt,
        createdBy,
        lastUpdatedBy,
        remark
      ];

  @override
  List<BaseModelQuery> get joins => [];
}

abstract class BaseModel extends __Model {
  int? _id;
  int? get id {
    return _id;
  }

  set id(int? v) {
    _id = v;
    __markDirty('id');
  }

  int? _version;
  int? get version {
    __ensureLoaded();
    return _version;
  }

  set version(int? v) {
    _version = v;
    __markDirty('version');
  }

  bool? _deleted;
  bool? get deleted {
    __ensureLoaded();
    return _deleted;
  }

  set deleted(bool? v) {
    _deleted = v;
    __markDirty('deleted');
  }

  DateTime? _createdAt;
  DateTime? get createdAt {
    __ensureLoaded();
    return _createdAt;
  }

  set createdAt(DateTime? v) {
    _createdAt = v;
    __markDirty('createdAt');
  }

  DateTime? _updatedAt;
  DateTime? get updatedAt {
    __ensureLoaded();
    return _updatedAt;
  }

  set updatedAt(DateTime? v) {
    _updatedAt = v;
    __markDirty('updatedAt');
  }

  String? _createdBy;
  String? get createdBy {
    __ensureLoaded();
    return _createdBy;
  }

  set createdBy(String? v) {
    _createdBy = v;
    __markDirty('createdBy');
  }

  String? _lastUpdatedBy;
  String? get lastUpdatedBy {
    __ensureLoaded();
    return _lastUpdatedBy;
  }

  set lastUpdatedBy(String? v) {
    _lastUpdatedBy = v;
    __markDirty('lastUpdatedBy');
  }

  String? _remark;
  String? get remark {
    __ensureLoaded();
    return _remark;
  }

  set remark(String? v) {
    _remark = v;
    __markDirty('remark');
  }

  BaseModel();

  @override
  String get __className => 'BaseModel';

  static BaseModelModelQuery query({Database? db}) =>
      BaseModelModelQuery(db: db);

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "id":
        return _id;
      case "version":
        return _version;
      case "deleted":
        return _deleted;
      case "createdAt":
        return _createdAt;
      case "updatedAt":
        return _updatedAt;
      case "createdBy":
        return _createdBy;
      case "lastUpdatedBy":
        return _lastUpdatedBy;
      case "remark":
        return _remark;
      default:
        if (errorOnNonExistField) {
          throw 'class _BaseModel has now such field: $fieldName';
        }
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "id":
        id = value;
        break;
      case "version":
        version = value;
        break;
      case "deleted":
        deleted = value is bool
            ? value
            : (0 == value || null == value || "" == value ? false : true);
        break;
      case "createdAt":
        createdAt = value;
        break;
      case "updatedAt":
        updatedAt = value;
        break;
      case "createdBy":
        createdBy = value;
        break;
      case "lastUpdatedBy":
        lastUpdatedBy = value;
        break;
      case "remark":
        remark = value;
        break;
      default:
        if (errorOnNonExistField) {
          throw 'class _BaseModel has now such field: $fieldName';
        }
    }
  }

  @override
  Map<String, dynamic> toMap({String fields = '*', bool ignoreNull = true}) {
    var filter = FieldFilter(fields, __idFieldName);
    if (ignoreNull) {
      var m = <String, dynamic>{};
      id != null && filter.contains("id") ? m["id"] = id : "";
      version != null && filter.contains("version")
          ? m["version"] = version
          : "";
      deleted != null && filter.contains("deleted")
          ? m["deleted"] = deleted
          : "";
      createdAt != null && filter.contains("createdAt")
          ? m["createdAt"] = createdAt?.toIso8601String()
          : "";
      updatedAt != null && filter.contains("updatedAt")
          ? m["updatedAt"] = updatedAt?.toIso8601String()
          : "";
      createdBy != null && filter.contains("createdBy")
          ? m["createdBy"] = createdBy
          : "";
      lastUpdatedBy != null && filter.contains("lastUpdatedBy")
          ? m["lastUpdatedBy"] = lastUpdatedBy
          : "";
      remark != null && filter.contains("remark") ? m["remark"] = remark : "";

      return m;
    }
    return {
      if (filter.contains('id')) "id": id,
      if (filter.contains('version')) "version": version,
      if (filter.contains('deleted')) "deleted": deleted,
      if (filter.contains('createdAt'))
        "createdAt": createdAt?.toIso8601String(),
      if (filter.contains('updatedAt'))
        "updatedAt": updatedAt?.toIso8601String(),
      if (filter.contains('createdBy')) "createdBy": createdBy,
      if (filter.contains('lastUpdatedBy')) "lastUpdatedBy": lastUpdatedBy,
      if (filter.contains('remark')) "remark": remark,
    };
  }

  // @override
  // String get __tableName {
  //   return "basemodel";
  // }

  @override
  String? get __idFieldName {
    return "id";
  }
}

class BookModelQuery extends BaseModelModelQuery<Book> {
  @override
  String get className => 'Book';

  BookModelQuery(
      // ignore: library_private_types_in_public_api
      {_BaseModelQuery? topQuery,
      String? propName,
      Database? db})
      : super(topQuery: topQuery, propName: propName, db: db);

  StringColumn title = StringColumn("title");
  DoubleColumn price = DoubleColumn("price");
  UserModelQuery get author => topQuery.findQuery(db, "User", "author");

  @override
  List<ColumnQuery> get columns => [title, price];

  @override
  List<BaseModelQuery> get joins => [author];
}

class Book extends BaseModel {
  String? _title;
  String? get title {
    __ensureLoaded();
    return _title;
  }

  set title(String? v) {
    _title = v;
    __markDirty('title');
  }

  double? _price;
  double? get price {
    __ensureLoaded();
    return _price;
  }

  set price(double? v) {
    _price = v;
    __markDirty('price');
  }

  User? _author;
  User? get author {
    __ensureLoaded();
    return _author;
  }

  set author(User? v) {
    _author = v;
    __markDirty('author');
  }

  Book();

  @override
  String get __className => 'Book';

  static BookModelQuery query({Database? db}) => BookModelQuery(db: db);

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "title":
        return _title;
      case "price":
        return _price;
      case "author":
        return _author;
      default:
        return super
            .__getField(fieldName, errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "title":
        title = value;
        break;
      case "price":
        price = value;
        break;
      case "author":
        author = value;
        break;
      default:
        super.__setField(fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  Map<String, dynamic> toMap({String fields = '*', bool ignoreNull = true}) {
    var filter = FieldFilter(fields, __idFieldName);
    if (ignoreNull) {
      var m = <String, dynamic>{};
      title != null && filter.contains("title") ? m["title"] = title : "";
      price != null && filter.contains("price") ? m["price"] = price : "";
      author != null && filter.contains("author")
          ? m["author"] = author?.toMap(
              fields: filter.subFilter("author"), ignoreNull: ignoreNull)
          : "";
      m.addAll(super.toMap(fields: fields, ignoreNull: true));
      return m;
    }
    return {
      if (filter.contains('title')) "title": title,
      if (filter.contains('price')) "price": price,
      if (filter.contains('author'))
        "author": author?.toMap(
            fields: filter.subFilter("author"), ignoreNull: ignoreNull),
      ...super.toMap(fields: fields, ignoreNull: ignoreNull),
    };
  }

  // @override
  // String get __tableName {
  //   return "book";
  // }

  @override
  String? get __idFieldName {
    return "id";
  }
}

class UserModelQuery extends BaseModelModelQuery<User> {
  @override
  String get className => 'User';

  UserModelQuery(
      // ignore: library_private_types_in_public_api
      {_BaseModelQuery? topQuery,
      String? propName,
      Database? db})
      : super(topQuery: topQuery, propName: propName, db: db);

  StringColumn name = StringColumn("name");
  StringColumn loginName = StringColumn("loginName");
  StringColumn address = StringColumn("address");
  IntColumn age = IntColumn("age");
  BookModelQuery get books => topQuery.findQuery(db, "Book", "books");

  @override
  List<ColumnQuery> get columns => [name, loginName, address, age];

  @override
  List<BaseModelQuery> get joins => [books];
}

class User extends BaseModel {
  String? _name;
  String? get name {
    __ensureLoaded();
    return _name;
  }

  set name(String? v) {
    _name = v;
    __markDirty('name');
  }

  String? _loginName;
  String? get loginName {
    __ensureLoaded();
    return _loginName;
  }

  set loginName(String? v) {
    _loginName = v;
    __markDirty('loginName');
  }

  String? _address;
  String? get address {
    __ensureLoaded();
    return _address;
  }

  set address(String? v) {
    _address = v;
    __markDirty('address');
  }

  int? _age;
  int? get age {
    __ensureLoaded();
    return _age;
  }

  set age(int? v) {
    _age = v;
    __markDirty('age');
  }

  List<Book>? _books;
  List<Book>? get books {
    if (__dbAttached && _books == null) {
      var meta = _modelInspector.meta('Book')!;
      var field = meta.fields.firstWhere((f) => f.name == 'author');
      _books = LazyOneToManyList(
          db: __topQuery!.db, clz: meta, refField: field, refFieldValue: id);
    }

    return _books;
  }

  set books(List<Book>? v) {
    _books = v;
  }

  User();

  @override
  String get __className => 'User';

  static UserModelQuery query({Database? db}) => UserModelQuery(db: db);

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "name":
        return _name;
      case "loginName":
        return _loginName;
      case "address":
        return _address;
      case "age":
        return _age;
      case "books":
        return _books;
      default:
        return super
            .__getField(fieldName, errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "name":
        name = value;
        break;
      case "loginName":
        loginName = value;
        break;
      case "address":
        address = value;
        break;
      case "age":
        age = value;
        break;
      case "books":
        books = value;
        break;
      default:
        super.__setField(fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  Map<String, dynamic> toMap({String fields = '*', bool ignoreNull = true}) {
    var filter = FieldFilter(fields, __idFieldName);
    if (ignoreNull) {
      var m = <String, dynamic>{};
      name != null && filter.contains("name") ? m["name"] = name : "";
      loginName != null && filter.contains("loginName")
          ? m["loginName"] = loginName
          : "";
      address != null && filter.contains("address")
          ? m["address"] = address
          : "";
      age != null && filter.contains("age") ? m["age"] = age : "";
      books != null && filter.contains("books") ? m["books"] = books : "";
      m.addAll(super.toMap(fields: fields, ignoreNull: true));
      return m;
    }
    return {
      if (filter.contains('name')) "name": name,
      if (filter.contains('loginName')) "loginName": loginName,
      if (filter.contains('address')) "address": address,
      if (filter.contains('age')) "age": age,
      if (filter.contains('books')) "books": books,
      ...super.toMap(fields: fields, ignoreNull: ignoreNull),
    };
  }

  // @override
  // String get __tableName {
  //   return "user";
  // }

  @override
  String? get __idFieldName {
    return "id";
  }

  @override
  void __prePersist() {
    beforeInsert();
  }

  @override
  void __postPersist() {
    afterInsert();
  }
}

class JobModelQuery extends BaseModelModelQuery<Job> {
  @override
  String get className => 'Job';

  JobModelQuery(
      // ignore: library_private_types_in_public_api
      {_BaseModelQuery? topQuery,
      String? propName,
      Database? db})
      : super(topQuery: topQuery, propName: propName, db: db);

  StringColumn name = StringColumn("name");

  @override
  List<ColumnQuery> get columns => [name];

  @override
  List<BaseModelQuery> get joins => [];
}

class Job extends BaseModel {
  String? _name;
  String? get name {
    __ensureLoaded();
    return _name;
  }

  set name(String? v) {
    _name = v;
    __markDirty('name');
  }

  Job();

  @override
  String get __className => 'Job';

  static JobModelQuery query({Database? db}) => JobModelQuery(db: db);

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "name":
        return _name;
      default:
        return super
            .__getField(fieldName, errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField = true}) {
    switch (fieldName) {
      case "name":
        name = value;
        break;
      default:
        super.__setField(fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  Map<String, dynamic> toMap({String fields = '*', bool ignoreNull = true}) {
    var filter = FieldFilter(fields, __idFieldName);
    if (ignoreNull) {
      var m = <String, dynamic>{};
      name != null && filter.contains("name") ? m["name"] = name : "";
      m.addAll(super.toMap(fields: fields, ignoreNull: true));
      return m;
    }
    return {
      if (filter.contains('name')) "name": name,
      ...super.toMap(fields: fields, ignoreNull: ignoreNull),
    };
  }

  // @override
  // String get __tableName {
  //   return "job";
  // }

  @override
  String? get __idFieldName {
    return "id";
  }
}

// **************************************************************************
// NeedleOrmMigrationGenerator
// **************************************************************************

class BookMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('books', (table) {
      table.varChar('title');

      table.float('price');

      table.integer('author_id');

      table.serial('id');

      table.integer('version');

      table.boolean('deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark');
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('books');
  }
}

class UserMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('users', (table) {
      table.varChar('name');

      table.varChar('login_name');

      table.varChar('address');

      table.integer('age');

      table.serial('id');

      table.integer('version');

      table.boolean('deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark');
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('users');
  }
}

class JobMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('jobs', (table) {
      table.varChar('name');

      table.serial('id');

      table.integer('version');

      table.boolean('deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark');
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('jobs');
  }
}
