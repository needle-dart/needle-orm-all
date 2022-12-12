// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// NeedleOrmMetaInfoGenerator
// **************************************************************************

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

  ModelInspector _inspector(Model m) =>
      ModelInspector.lookup(ModelInspector.getClassName(m));

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

class _OrmMetaInfoModel extends OrmMetaClass {
  _OrmMetaInfoModel()
      : super('Model', isAbstract: true, superClassName: null, ormAnnotations: [
          Entity(),
        ], fields: [
          OrmMetaClass.idField,
        ], methods: []);
}

class _OrmMetaInfoBasic extends OrmMetaClass {
  _OrmMetaInfoBasic()
      : super('Basic',
            isAbstract: true,
            superClassName: 'Model',
            ormAnnotations: [
              Entity(),
            ],
            fields: [
              OrmMetaField('version', 'int?', ormAnnotations: [
                Version(),
              ]),
              OrmMetaField('softDeleted', 'bool?', ormAnnotations: [
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
            ],
            methods: []);
}

class _OrmMetaInfoBook extends OrmMetaClass {
  _OrmMetaInfoBook()
      : super('Book',
            isAbstract: false,
            superClassName: 'Basic',
            ormAnnotations: [
              Table(),
              Entity(),
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
              OrmMetaField('image', 'List<int>?', ormAnnotations: [
                Lob(),
              ]),
              OrmMetaField('content', 'String?', ormAnnotations: [
                Lob(),
              ]),
            ],
            methods: []);
}

class _OrmMetaInfoUser extends OrmMetaClass {
  _OrmMetaInfoUser()
      : super('User',
            isAbstract: false,
            superClassName: 'Basic',
            ormAnnotations: [
              Table(name: 'users'),
              Entity(),
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
              OrmMetaField('books', 'List<Book>?', ormAnnotations: [
                OneToMany(mappedBy: "_author"),
              ]),
            ],
            methods: [
              OrmMetaMethod('beforeInsert', ormAnnotations: [
                PrePersist(),
              ]),
              OrmMetaMethod('afterInsert', ormAnnotations: [
                PostPersist(),
              ]),
              OrmMetaMethod('beforeRemove', ormAnnotations: [
                PreRemove(),
              ]),
              OrmMetaMethod('beforeRemovePermanent', ormAnnotations: [
                PreRemovePermanent(),
              ]),
              OrmMetaMethod('beforeUpdate', ormAnnotations: [
                PreUpdate(),
              ]),
              OrmMetaMethod('afterLoad', ormAnnotations: [
                PostLoad(),
              ]),
              OrmMetaMethod('afterUpdate', ormAnnotations: [
                PostUpdate(),
              ]),
              OrmMetaMethod('afterRemove', ormAnnotations: [
                PostRemove(),
              ]),
              OrmMetaMethod('afterRemovePermanent', ormAnnotations: [
                PostRemovePermanent(),
              ]),
            ]);
}

class _OrmMetaInfoDevice extends OrmMetaClass {
  _OrmMetaInfoDevice()
      : super('Device',
            isAbstract: false,
            superClassName: 'Model',
            ormAnnotations: [
              Table(),
              Entity(),
            ],
            fields: [
              OrmMetaField('name', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('address', 'String?', ormAnnotations: [
                Column(),
              ]),
            ],
            methods: [
              OrmMetaMethod('beforeInsert', ormAnnotations: [
                PrePersist(),
              ]),
              OrmMetaMethod('afterInsert', ormAnnotations: [
                PostPersist(),
              ]),
            ]);
}

final _allModelMetaClasses = [
  _OrmMetaInfoModel(),
  _OrmMetaInfoBasic(),
  _OrmMetaInfoBook(),
  _OrmMetaInfoUser(),
  _OrmMetaInfoDevice()
];

// **************************************************************************
// NeedleOrmModelGenerator
// **************************************************************************

abstract class BasicQuery<T extends Basic> extends _BaseModelQuery<T> {
  @override
  String get className => 'Basic';

  BasicQuery({super.db, super.topQuery, super.propName});

  IntColumn version = IntColumn("version");
  BoolColumn softDeleted = BoolColumn("softDeleted");
  DateTimeColumn createdAt = DateTimeColumn("createdAt");
  DateTimeColumn updatedAt = DateTimeColumn("updatedAt");
  StringColumn createdBy = StringColumn("createdBy");
  StringColumn lastUpdatedBy = StringColumn("lastUpdatedBy");
  StringColumn remark = StringColumn("remark");

  @override
  List<ColumnQuery> get columns => [
        version,
        softDeleted,
        createdAt,
        updatedAt,
        createdBy,
        lastUpdatedBy,
        remark,
        ...super.columns
      ];

  @override
  List<BaseModelQuery> get joins => [];
}

class BookQuery extends BasicQuery<Book> {
  @override
  String get className => 'Book';

  BookQuery({super.db, super.topQuery, super.propName});

  StringColumn title = StringColumn("title");
  DoubleColumn price = DoubleColumn("price");
  UserQuery get author => topQuery.findQuery(db, "User", "author");
  ColumnQuery image = ColumnQuery("image");
  StringColumn content = StringColumn("content");

  @override
  List<ColumnQuery> get columns =>
      [title, price, image, content, ...super.columns];

  @override
  List<BaseModelQuery> get joins => [author, ...super.joins];
}

class UserQuery extends BasicQuery<User> {
  @override
  String get className => 'User';

  UserQuery({super.db, super.topQuery, super.propName});

  StringColumn name = StringColumn("name");
  StringColumn loginName = StringColumn("loginName");
  StringColumn address = StringColumn("address");
  IntColumn age = IntColumn("age");
  BookQuery get books => topQuery.findQuery(db, "Book", "books");

  @override
  List<ColumnQuery> get columns =>
      [name, loginName, address, age, ...super.columns];

  @override
  List<BaseModelQuery> get joins => [books, ...super.joins];
}

class DeviceQuery extends _BaseModelQuery<Device> {
  @override
  String get className => 'Device';

  DeviceQuery({super.db, super.topQuery, super.propName});

  StringColumn name = StringColumn("name");
  StringColumn address = StringColumn("address");

  @override
  List<ColumnQuery> get columns => [name, address, ...super.columns];

  @override
  List<BaseModelQuery> get joins => [];
}

// **************************************************************************
// NeedleOrmImplGenerator
// **************************************************************************

extension BasicImpl on Basic {
  ModelInspector<Basic> get _modelInspector => ModelInspector.lookup("Basic");

  int? get version {
    _modelInspector.ensureLoaded(this);
    return _version;
  }

  set version(int? v) {
    _modelInspector.markDirty(this, 'version', _version, v);
    _version = v;
  }

  bool? get softDeleted {
    _modelInspector.ensureLoaded(this);
    return _softDeleted;
  }

  set softDeleted(bool? v) {
    _modelInspector.markDirty(this, 'softDeleted', _softDeleted, v);
    _softDeleted = v;
  }

  DateTime? get createdAt {
    _modelInspector.ensureLoaded(this);
    return _createdAt;
  }

  set createdAt(DateTime? v) {
    _modelInspector.markDirty(this, 'createdAt', _createdAt, v);
    _createdAt = v;
  }

  DateTime? get updatedAt {
    _modelInspector.ensureLoaded(this);
    return _updatedAt;
  }

  set updatedAt(DateTime? v) {
    _modelInspector.markDirty(this, 'updatedAt', _updatedAt, v);
    _updatedAt = v;
  }

  String? get createdBy {
    _modelInspector.ensureLoaded(this);
    return _createdBy;
  }

  set createdBy(String? v) {
    _modelInspector.markDirty(this, 'createdBy', _createdBy, v);
    _createdBy = v;
  }

  String? get lastUpdatedBy {
    _modelInspector.ensureLoaded(this);
    return _lastUpdatedBy;
  }

  set lastUpdatedBy(String? v) {
    _modelInspector.markDirty(this, 'lastUpdatedBy', _lastUpdatedBy, v);
    _lastUpdatedBy = v;
  }

  String? get remark {
    _modelInspector.ensureLoaded(this);
    return _remark;
  }

  set remark(String? v) {
    _modelInspector.markDirty(this, 'remark', _remark, v);
    _remark = v;
  }
}

extension BookImpl on Book {
  ModelInspector<Book> get _modelInspector => ModelInspector.lookup("Book");

  String? get title {
    _modelInspector.ensureLoaded(this);
    return _title;
  }

  set title(String? v) {
    _modelInspector.markDirty(this, 'title', _title, v);
    _title = v;
  }

  double? get price {
    _modelInspector.ensureLoaded(this);
    return _price;
  }

  set price(double? v) {
    _modelInspector.markDirty(this, 'price', _price, v);
    _price = v;
  }

  User? get author {
    _modelInspector.ensureLoaded(this);
    return _author;
  }

  set author(User? v) {
    _modelInspector.markDirty(this, 'author', _author, v);
    _author = v;
  }

  List<int>? get image {
    _modelInspector.ensureLoaded(this);
    return _image;
  }

  set image(List<int>? v) {
    _modelInspector.markDirty(this, 'image', _image, v);
    _image = v;
  }

  String? get content {
    _modelInspector.ensureLoaded(this);
    return _content;
  }

  set content(String? v) {
    _modelInspector.markDirty(this, 'content', _content, v);
    _content = v;
  }
}

extension UserImpl on User {
  ModelInspector<User> get _modelInspector => ModelInspector.lookup("User");

  String? get name {
    _modelInspector.ensureLoaded(this);
    return _name;
  }

  set name(String? v) {
    _modelInspector.markDirty(this, 'name', _name, v);
    _name = v;
  }

  String? get loginName {
    _modelInspector.ensureLoaded(this);
    return _loginName;
  }

  set loginName(String? v) {
    _modelInspector.markDirty(this, 'loginName', _loginName, v);
    _loginName = v;
  }

  String? get address {
    _modelInspector.ensureLoaded(this);
    return _address;
  }

  set address(String? v) {
    _modelInspector.markDirty(this, 'address', _address, v);
    _address = v;
  }

  int? get age {
    _modelInspector.ensureLoaded(this);
    return _age;
  }

  set age(int? v) {
    _modelInspector.markDirty(this, 'age', _age, v);
    _age = v;
  }

  List<Book>? get books {
    _modelInspector.ensureLoaded(this);
    return _books;
  }

  set books(List<Book>? v) {
    _modelInspector.markDirty(this, 'books', _books, v);
    _books = v;
  }
}

extension DeviceImpl on Device {
  ModelInspector<Device> get _modelInspector => ModelInspector.lookup("Device");

  String? get name {
    _modelInspector.ensureLoaded(this);
    return _name;
  }

  set name(String? v) {
    _modelInspector.markDirty(this, 'name', _name, v);
    _name = v;
  }

  String? get address {
    _modelInspector.ensureLoaded(this);
    return _address;
  }

  set address(String? v) {
    _modelInspector.markDirty(this, 'address', _address, v);
    _address = v;
  }
}

// **************************************************************************
// NeedleOrmInspectorGenerator
// **************************************************************************

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

class _BasicModelInspector<T extends Basic> extends ModelInspector<T> {
  @override
  String get className => "Basic";

  @override
  T newInstance({bool attachDb = false, id, required ModelQuery<T> topQuery}) {
    throw UnimplementedError();
  }

  @override
  getFieldValue(T model, String fieldName) {
    switch (fieldName) {
      case "version":
        return model.version;
      case "softDeleted":
        return model.softDeleted;
      case "createdAt":
        return model.createdAt;
      case "updatedAt":
        return model.updatedAt;
      case "createdBy":
        return model.createdBy;
      case "lastUpdatedBy":
        return model.lastUpdatedBy;
      case "remark":
        return model.remark;
      default:
        return super.getFieldValue(model, fieldName);
    }
  }

  @override
  void setFieldValue(T model, String fieldName, value,
      {errorOnNonExistField = false}) {
    switch (fieldName) {
      case "version":
        model.version = value;
        break;
      case "softDeleted":
        model.softDeleted = toBool(value);
        break;
      case "createdAt":
        model.createdAt = value;
        break;
      case "updatedAt":
        model.updatedAt = value;
        break;
      case "createdBy":
        model.createdBy = value;
        break;
      case "lastUpdatedBy":
        model.lastUpdatedBy = value;
        break;
      case "remark":
        model.remark = value;
        break;
      default:
        super.setFieldValue(model, fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }
}

class _BookModelInspector extends _BasicModelInspector<Book> {
  @override
  String get className => "Book";

  @override
  Book newInstance(
      {bool attachDb = false, id, required ModelQuery<Model> topQuery}) {
    var m = Book();
    m.id = id;
    initInstance(m, topQuery: topQuery);
    m._modelInspector.markAttached(m, topQuery: topQuery);
    return m;
  }

  @override
  BookQuery newQuery(Database db, String className) {
    return BookQuery(db: db);
  }

  @override
  getFieldValue(Book model, String fieldName) {
    switch (fieldName) {
      case "title":
        return model.title;
      case "price":
        return model.price;
      case "author":
        return model.author;
      case "image":
        return model.image;
      case "content":
        return model.content;
      default:
        return super.getFieldValue(model, fieldName);
    }
  }

  @override
  void setFieldValue(Book model, String fieldName, value,
      {errorOnNonExistField = false}) {
    switch (fieldName) {
      case "title":
        model.title = value;
        break;
      case "price":
        model.price = value;
        break;
      case "author":
        model.author = value;
        break;
      case "image":
        model.image = value;
        break;
      case "content":
        model.content = value;
        break;
      default:
        super.setFieldValue(model, fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }
}

class _UserModelInspector extends _BasicModelInspector<User> {
  @override
  String get className => "User";

  @override
  User newInstance(
      {bool attachDb = false, id, required ModelQuery<Model> topQuery}) {
    var m = User();
    m.id = id;
    initInstance(m, topQuery: topQuery);
    m._modelInspector.markAttached(m, topQuery: topQuery);
    return m;
  }

  /// init model properties after [newInstance()]
  @override
  void initInstance(User m, {required ModelQuery<Model> topQuery}) {
    {
      var meta = ModelInspector.lookupClass('Book');
      var field = meta
          .allFields(searchParents: true)
          .firstWhere((f) => f.name == 'author');
      m.books = LazyOneToManyList(
          db: topQuery.db, clz: meta, refField: field, refFieldValue: m.id);
    }

    super.initInstance(m, topQuery: topQuery);
  }

  @override
  UserQuery newQuery(Database db, String className) {
    return UserQuery(db: db);
  }

  @override
  getFieldValue(User model, String fieldName) {
    switch (fieldName) {
      case "name":
        return model.name;
      case "loginName":
        return model.loginName;
      case "address":
        return model.address;
      case "age":
        return model.age;
      case "books":
        return model.books;
      default:
        return super.getFieldValue(model, fieldName);
    }
  }

  @override
  void setFieldValue(User model, String fieldName, value,
      {errorOnNonExistField = false}) {
    switch (fieldName) {
      case "name":
        model.name = value;
        break;
      case "loginName":
        model.loginName = value;
        break;
      case "address":
        model.address = value;
        break;
      case "age":
        model.age = value;
        break;
      case "books":
        model.books = value;
        break;
      default:
        super.setFieldValue(model, fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void prePersist(User model) {
    model.beforeInsert();
  }

  @override
  void postPersist(User model) {
    model.afterInsert();
  }

  @override
  void preRemove(User model) {
    model.beforeRemove();
  }

  @override
  void preRemovePermanent(User model) {
    model.beforeRemovePermanent();
  }

  @override
  void preUpdate(User model) {
    model.beforeUpdate();
  }

  @override
  void postLoad(User model) {
    model.afterLoad();
  }

  @override
  void postUpdate(User model) {
    model.afterUpdate();
  }

  @override
  void postRemove(User model) {
    model.afterRemove();
  }

  @override
  void postRemovePermanent(User model) {
    model.afterRemovePermanent();
  }
}

class _DeviceModelInspector extends ModelInspector<Device> {
  @override
  String get className => "Device";

  @override
  Device newInstance(
      {bool attachDb = false, id, required ModelQuery<Model> topQuery}) {
    var m = Device();
    m.id = id;
    initInstance(m, topQuery: topQuery);
    m._modelInspector.markAttached(m, topQuery: topQuery);
    return m;
  }

  @override
  DeviceQuery newQuery(Database db, String className) {
    return DeviceQuery(db: db);
  }

  @override
  getFieldValue(Device model, String fieldName) {
    switch (fieldName) {
      case "name":
        return model.name;
      case "address":
        return model.address;
      default:
        return super.getFieldValue(model, fieldName);
    }
  }

  @override
  void setFieldValue(Device model, String fieldName, value,
      {errorOnNonExistField = false}) {
    switch (fieldName) {
      case "name":
        model.name = value;
        break;
      case "address":
        model.address = value;
        break;
      default:
        super.setFieldValue(model, fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void prePersist(Device model) {
    model.beforeInsert();
  }

  @override
  void postPersist(Device model) {
    model.afterInsert();
  }
}

final _allModelInspectors = <ModelInspector>[
  _BasicModelInspector(),
  _BookModelInspector(),
  _UserModelInspector(),
  _DeviceModelInspector()
];

initNeedle() {
  Needle.registerAll(_allModelInspectors);
  Needle.registerAllMetaClasses(_allModelMetaClasses);
}

// **************************************************************************
// NeedleOrmMigrationGenerator
// **************************************************************************

class _BookMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('books', (table) {
      table.varChar('title', length: 255);

      table.float('price');

      table.integer('author_id');

      table.blob('image');

      table.clob('content');

      table.integer('version');

      table.boolean('soft_deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark', length: 255);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('books');
  }
}

class _UserMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('users', (table) {
      table.varChar('name', length: 255);

      table.varChar('login_name', length: 255);

      table.varChar('address', length: 255);

      table.integer('age');

      table.integer('version');

      table.boolean('soft_deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark', length: 255);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('users');
  }
}

class _DeviceMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('devices', (table) {
      table.varChar('name', length: 255);

      table.varChar('address', length: 255);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('devices');
  }
}

final allMigrations = <Migration>[
  _BookMigration(),
  _UserMigration(),
  _DeviceMigration()
];
