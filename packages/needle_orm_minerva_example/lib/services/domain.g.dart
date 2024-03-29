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

mixin ModelMixin<T> on TableQuery<T> {
  IntColumn get id => IntColumn(this, "id");
}

class _OrmMetaInfoModel extends OrmMetaClass {
  _OrmMetaInfoModel()
      : super('Model', isAbstract: true, superClassName: null, ormAnnotations: [
          Entity(),
        ], fields: [
          OrmMetaClass.idField,
        ], methods: []);
}

class _OrmMetaInfoModelBase extends OrmMetaClass {
  _OrmMetaInfoModelBase()
      : super('ModelBase',
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
              OrmMetaField('createdBy', 'User?', ormAnnotations: [
                WhoCreated(),
                ManyToOne(),
              ]),
              OrmMetaField('lastUpdatedBy', 'User?', ormAnnotations: [
                WhoModified(),
                ManyToOne(),
              ]),
              OrmMetaField('remark', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('extra', 'Map<String, dynamic>?', ormAnnotations: [
                Transient(),
              ]),
            ],
            methods: []);
}

class _OrmMetaInfoBook extends OrmMetaClass {
  _OrmMetaInfoBook()
      : super('Book',
            isAbstract: false,
            superClassName: 'ModelBase',
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
            superClassName: 'ModelBase',
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
              OrmMetaField('password', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('address', 'String?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('age', 'int?', ormAnnotations: [
                Column(),
              ]),
              OrmMetaField('books', 'List<Book>?', ormAnnotations: [
                OneToMany(mappedBy: "author"),
              ]),
            ],
            methods: [
              OrmMetaMethod('_beforeInsert', ormAnnotations: [
                PrePersist(),
              ]),
              OrmMetaMethod('_afterInsert', ormAnnotations: [
                PostPersist(),
              ]),
              OrmMetaMethod('_beforeRemove', ormAnnotations: [
                PreRemove(),
              ]),
              OrmMetaMethod('_beforeRemovePermanent', ormAnnotations: [
                PreRemovePermanent(),
              ]),
              OrmMetaMethod('_beforeUpdate', ormAnnotations: [
                PreUpdate(),
              ]),
              OrmMetaMethod('_afterLoad', ormAnnotations: [
                PostLoad(),
              ]),
              OrmMetaMethod('_afterUpdate', ormAnnotations: [
                PostUpdate(),
              ]),
              OrmMetaMethod('_afterRemove', ormAnnotations: [
                PostRemove(),
              ]),
              OrmMetaMethod('_afterRemovePermanent', ormAnnotations: [
                PostRemovePermanent(),
              ]),
            ]);
}

class _OrmMetaInfoJob extends OrmMetaClass {
  _OrmMetaInfoJob()
      : super('Job',
            isAbstract: false,
            superClassName: 'ModelBase',
            ormAnnotations: [
              Entity(),
            ],
            fields: [
              OrmMetaField('name', 'String?', ormAnnotations: [
                Column(),
              ]),
            ],
            methods: []);
}

final _allModelMetaClasses = [
  _OrmMetaInfoModel(),
  _OrmMetaInfoModelBase(),
  _OrmMetaInfoBook(),
  _OrmMetaInfoUser(),
  _OrmMetaInfoJob()
];

// **************************************************************************
// NeedleOrmModelGenerator
// **************************************************************************

mixin ModelBaseMixin<T> on TableQuery<T> {
  IntColumn get version => IntColumn(this, "version");
  BoolColumn get softDeleted => BoolColumn(this, "softDeleted");
  DateTimeColumn get createdAt => DateTimeColumn(this, "createdAt");
  DateTimeColumn get updatedAt => DateTimeColumn(this, "updatedAt");
  UserColumn get createdBy =>
      UserColumn(this, "createdBy")..joinRelation = JoinRelation();
  UserColumn get lastUpdatedBy =>
      UserColumn(this, "lastUpdatedBy")..joinRelation = JoinRelation();
  StringColumn get remark => StringColumn(this, "remark");
}

class ModelBaseColumn extends TableQuery<ModelBase>
    with ModelMixin, ModelBaseMixin {
  ModelBaseColumn(super.owner, super.name);
}

class ModelBaseQuery extends TopTableQuery<ModelBase>
    with ModelMixin, ModelBaseMixin {
  ModelBaseQuery({super.db});
}

mixin BookMixin on TableQuery<Book> {
  StringColumn get title => StringColumn(this, "title");
  DoubleColumn get price => DoubleColumn(this, "price");
  UserColumn get author =>
      UserColumn(this, "author")..joinRelation = JoinRelation();
  ColumnQuery get image => ColumnQuery(this, "image");
  StringColumn get content => StringColumn(this, "content");
}

class BookColumn extends TableQuery<Book>
    with ModelBaseMixin, ModelMixin, BookMixin {
  BookColumn(super.owner, super.name);
}

class BookQuery extends TopTableQuery<Book>
    with ModelBaseMixin, ModelMixin, BookMixin {
  BookQuery({super.db});
}

mixin UserMixin on TableQuery<User> {
  StringColumn get name => StringColumn(this, "name");
  StringColumn get loginName => StringColumn(this, "loginName");
  StringColumn get password => StringColumn(this, "password");
  StringColumn get address => StringColumn(this, "address");
  IntColumn get age => IntColumn(this, "age");
  BookColumn get books => BookColumn(this, "books")
    ..joinRelation = JoinRelation(JoinKind.oneToMany, "author");
}

class UserColumn extends TableQuery<User>
    with ModelBaseMixin, ModelMixin, UserMixin {
  UserColumn(super.owner, super.name);
}

class UserQuery extends TopTableQuery<User>
    with ModelBaseMixin, ModelMixin, UserMixin {
  UserQuery({super.db});
}

mixin JobMixin on TableQuery<Job> {
  StringColumn get name => StringColumn(this, "name");
}

class JobColumn extends TableQuery<Job>
    with ModelBaseMixin, ModelMixin, JobMixin {
  JobColumn(super.owner, super.name);
}

class JobQuery extends TopTableQuery<Job>
    with ModelBaseMixin, ModelMixin, JobMixin {
  JobQuery({super.db});
}

// **************************************************************************
// NeedleOrmImplGenerator
// **************************************************************************

extension ModelBaseImpl on ModelBase {
  ModelInspector<ModelBase> get _modelInspector =>
      ModelInspector.lookup("ModelBase");

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

  User? get createdBy {
    _modelInspector.ensureLoaded(this);
    return _createdBy;
  }

  set createdBy(User? v) {
    _modelInspector.markDirty(this, 'createdBy', _createdBy, v);
    _createdBy = v;
  }

  User? get lastUpdatedBy {
    _modelInspector.ensureLoaded(this);
    return _lastUpdatedBy;
  }

  set lastUpdatedBy(User? v) {
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

  Map<String, dynamic>? get extra {
    _modelInspector.ensureLoaded(this);
    return _extra;
  }

  set extra(Map<String, dynamic>? v) {
    _modelInspector.markDirty(this, 'extra', _extra, v);
    _extra = v;
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

  String? get password {
    _modelInspector.ensureLoaded(this);
    return _password;
  }

  set password(String? v) {
    _modelInspector.markDirty(this, 'password', _password, v);
    _password = v;
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

extension JobImpl on Job {
  ModelInspector<Job> get _modelInspector => ModelInspector.lookup("Job");

  String? get name {
    _modelInspector.ensureLoaded(this);
    return _name;
  }

  set name(String? v) {
    _modelInspector.markDirty(this, 'name', _name, v);
    _name = v;
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

class _ModelBaseModelInspector<T extends ModelBase> extends ModelInspector<T> {
  @override
  String get className => "ModelBase";

  @override
  T newInstance({bool attachDb = false, id}) {
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
      case "extra":
        return model.extra;
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
      case "extra":
        model.extra = value;
        break;
      default:
        super.setFieldValue(model, fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }
}

class _BookModelInspector extends _ModelBaseModelInspector<Book> {
  @override
  String get className => "Book";

  @override
  Book newInstance({bool attachDb = false, id}) {
    var m = Book();
    m.id = id;
    initInstance(m);
    m._modelInspector.markAttached(m);
    return m;
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

class _UserModelInspector extends _ModelBaseModelInspector<User> {
  @override
  String get className => "User";

  @override
  User newInstance({bool attachDb = false, id}) {
    var m = User();
    m.id = id;
    initInstance(m);
    m._modelInspector.markAttached(m);
    return m;
  }

  @override
  getFieldValue(User model, String fieldName) {
    switch (fieldName) {
      case "name":
        return model.name;
      case "loginName":
        return model.loginName;
      case "password":
        return model.password;
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
      case "password":
        model.password = value;
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
    model._beforeInsert();
  }

  @override
  void postPersist(User model) {
    model._afterInsert();
  }

  @override
  void preRemove(User model) {
    model._beforeRemove();
  }

  @override
  void preRemovePermanent(User model) {
    model._beforeRemovePermanent();
  }

  @override
  void preUpdate(User model) {
    model._beforeUpdate();
  }

  @override
  void postLoad(User model) {
    model._afterLoad();
  }

  @override
  void postUpdate(User model) {
    model._afterUpdate();
  }

  @override
  void postRemove(User model) {
    model._afterRemove();
  }

  @override
  void postRemovePermanent(User model) {
    model._afterRemovePermanent();
  }
}

class _JobModelInspector extends _ModelBaseModelInspector<Job> {
  @override
  String get className => "Job";

  @override
  Job newInstance({bool attachDb = false, id}) {
    var m = Job();
    m.id = id;
    initInstance(m);
    m._modelInspector.markAttached(m);
    return m;
  }

  @override
  getFieldValue(Job model, String fieldName) {
    switch (fieldName) {
      case "name":
        return model.name;
      default:
        return super.getFieldValue(model, fieldName);
    }
  }

  @override
  void setFieldValue(Job model, String fieldName, value,
      {errorOnNonExistField = false}) {
    switch (fieldName) {
      case "name":
        model.name = value;
        break;
      default:
        super.setFieldValue(model, fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }
}

final _allModelInspectors = <ModelInspector>[
  _ModelBaseModelInspector(),
  _BookModelInspector(),
  _UserModelInspector(),
  _JobModelInspector()
];

initNeedle() {
  Needle.registerAll(_allModelInspectors);
  Needle.registerAllMetaClasses(_allModelMetaClasses);
}
