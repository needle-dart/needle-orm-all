import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

class MigrationColumn extends TableColumn {
  final List<MigrationColumnReference> _references = [];
  late bool _nullable;
  late IndexType _index;
  dynamic _defaultValue;

  @override
  bool get isNullable => _nullable;

  @override
  IndexType get indexType => _index;

  @override
  dynamic get defaultValue => _defaultValue;

  List<MigrationColumnReference> get externalReferences =>
      List<MigrationColumnReference>.unmodifiable(_references);

  MigrationColumn(ColumnType type,
      {bool isNullable = true,
      int length = 255,
      IndexType indexType = IndexType.standardIndex,
      dynamic defaultValue})
      : super(
            type: type,
            length: length,
            isNullable: isNullable,
            defaultValue: defaultValue) {
    _nullable = isNullable;
    _index = indexType;
    _defaultValue = defaultValue;
  }

  factory MigrationColumn.from(TableColumn column) => column is MigrationColumn
      ? column
      : MigrationColumn(column.type,
          isNullable: column.isNullable,
          length: column.length,
          indexType: column.indexType);

  MigrationColumn notNull() => this.._nullable = false;

  MigrationColumn defaultsTo(value) => this.._defaultValue = value;

  MigrationColumn unique() => this.._index = IndexType.unique;

  MigrationColumn primaryKey() => this.._index = IndexType.primaryKey;

  MigrationColumnReference references(String foreignTable, String foreignKey) {
    var ref = MigrationColumnReference._(foreignTable, foreignKey);
    _references.add(ref);
    return ref;
  }
}

class MigrationColumnReference {
  final String foreignTable, foreignKey;
  String? _behavior;

  MigrationColumnReference._(this.foreignTable, this.foreignKey);

  String? get behavior => _behavior;

  StateError _locked() =>
      StateError('Cannot override existing "$_behavior" behavior.');

  void onDeleteCascade() {
    if (_behavior != null) throw _locked();
    _behavior = 'ON DELETE CASCADE';
  }

  void onUpdateCascade() {
    if (_behavior != null) throw _locked();
    _behavior = 'ON UPDATE CASCADE';
  }

  void onNoAction() {
    if (_behavior != null) throw _locked();
    _behavior = 'ON UPDATE NO ACTION';
  }

  void onUpdateSetDefault() {
    if (_behavior != null) throw _locked();
    _behavior = 'ON UPDATE SET DEFAULT';
  }

  void onUpdateSetNull() {
    if (_behavior != null) throw _locked();
    _behavior = 'ON UPDATE SET NULL';
  }
}

const List<String> sqlReservedWords = [
  'SELECT',
  'UPDATE',
  'INSERT',
  'DELETE',
  'FROM',
  'ASC',
  'DESC',
  'VALUES',
  'RETURNING',
  'ORDER',
  'BY',
];

/// Applies additional attributes to a database column.
class TableColumn {
  /// If `true`, a SQL field will be nullable.
  final bool isNullable;

  /// Specifies this column name.
  final String? name;

  /// Specifies the length of a `VARCHAR`.
  final int length;

  /// Specifies the precision of a `NUMERIC` or `DECIMAL`.
  final int precision;

  /// Specifies the scale of a `NUMERIC` or `DECIMAL`.
  final int scale;

  /// Specifies the timezone for temporal field.
  final String? timezone;

  /// Explicitly defines a SQL type for this column.
  final ColumnType type;

  /// Specifies what kind of index this column is, if any.
  final IndexType indexType;

  /// A custom SQL expression to execute, instead of a named column.
  final String? expression;

  /// Specifies the default values.
  final dynamic defaultValue;

  const TableColumn(
      {this.isNullable = true,
      this.length = 255,
      this.precision = 17,
      this.scale = 3,
      this.name,
      this.timezone,
      this.type = ColumnType.varChar,
      this.indexType = IndexType.none,
      this.expression,
      this.defaultValue});

  /// Returns `true` if [expression] is not `null`.
  bool get hasExpression => expression != null;
}

class PrimaryKey extends TableColumn {
  const PrimaryKey({ColumnType columnType = ColumnType.serial})
      : super(type: columnType, indexType: IndexType.primaryKey);
}

const TableColumn primaryKey = PrimaryKey();

/// Maps to SQL index types.
enum IndexType {
  none,

  /// Standard index.
  standardIndex,

  /// A primary key.
  primaryKey,

  /// A *unique* index.
  unique
}

/// Maps to SQL data types.
///
/// Features all types from this list: http://www.tutorialspoint.com/sql/sql-data-types.htm
class ColumnType {
  /// The name of this data type.
  final String name;
  final bool hasLength;
  final bool hasPrecision;
  final bool hasScale;
  final bool hasTimezone;

  const ColumnType(this.name,
      {this.hasLength = false,
      this.hasPrecision = false,
      this.hasScale = false,
      this.hasTimezone = false});

  static const ColumnType boolean = ColumnType('boolean');

  static const ColumnType smallSerial = ColumnType('smallserial');
  static const ColumnType serial = ColumnType('serial');
  static const ColumnType bigSerial = ColumnType('bigserial');

  // Numbers
  static const ColumnType bigInt = ColumnType('bigint');
  static const ColumnType int = ColumnType('int');
  static const ColumnType smallInt = ColumnType('smallint');
  static const ColumnType tinyInt = ColumnType('tinyint');
  static const ColumnType bit = ColumnType('bit');
  static const ColumnType decimal =
      ColumnType('decimal', hasPrecision: true, hasScale: true);
  static const ColumnType numeric =
      ColumnType('numeric', hasPrecision: true, hasScale: true);
  static const ColumnType money = ColumnType('money');
  static const ColumnType smallMoney = ColumnType('smallmoney');
  static const ColumnType float = ColumnType('float');
  static const ColumnType real = ColumnType('real');
  static const ColumnType double = ColumnType('double precision');

  // Dates and times
  static const ColumnType dateTime = ColumnType('datetime');
  static const ColumnType smallDateTime = ColumnType('smalldatetime');
  static const ColumnType date = ColumnType('date');
  static const ColumnType time = ColumnType('time');
  static const ColumnType timeStamp = ColumnType('timestamp');
  static const ColumnType timeStampWithTimeZone =
      ColumnType('timestamptz', hasTimezone: true);

  // Strings
  static const ColumnType char = ColumnType('char', hasLength: true);
  static const ColumnType varChar = ColumnType('varchar', hasLength: true);
  static const ColumnType varCharMax = ColumnType('varchar(max)');
  static const ColumnType text = ColumnType('text');

  // Unicode strings
  static const ColumnType nChar = ColumnType('nchar', hasLength: true);
  static const ColumnType nVarChar = ColumnType('nvarchar', hasLength: true);
  static const ColumnType nVarCharMax = ColumnType('nvarchar(max)');
  static const ColumnType nText = ColumnType('ntext', hasLength: true);

  // Binary
  static const ColumnType binary = ColumnType('binary');
  static const ColumnType varBinary = ColumnType('varbinary');
  static const ColumnType varBinaryMax = ColumnType('varbinary(max)');
  static const ColumnType image = ColumnType('image');

  // JSON.
  static const ColumnType json = ColumnType('json');
  static const ColumnType jsonb = ColumnType('jsonb');

  // Misc.
  static const ColumnType sqlVariant = ColumnType('sql_variant');
  static const ColumnType uniqueIdentifier = ColumnType('uniqueidentifier');
  static const ColumnType xml = ColumnType('xml');
  static const ColumnType cursor = ColumnType('cursor');
  static const ColumnType table = ColumnType('table');

  // Blob
  static const ColumnType blob = ColumnType('blob');
  static const ColumnType clob = ColumnType('clob');
}

/// Detect and return the correct column type
ColumnType inferColumnType(FieldElement field) {
  DartType type = field.type;
  if (const TypeChecker.fromRuntime(String).isAssignableFromType(type)) {
    if (field.metadata
        .where((annot) => annot.toSource() == '@Lob()')
        .isNotEmpty) {
      return ColumnType.clob;
    }
    return ColumnType.varChar;
  }
  if (const TypeChecker.fromRuntime(int).isAssignableFromType(type)) {
    return ColumnType.int;
  }
  if (const TypeChecker.fromRuntime(double).isAssignableFromType(type)) {
    return ColumnType.double;
  }
  if (const TypeChecker.fromRuntime(num).isAssignableFromType(type)) {
    return ColumnType.float;
  }
  if (const TypeChecker.fromRuntime(bool).isAssignableFromType(type)) {
    return ColumnType.boolean;
  }
  if (const TypeChecker.fromRuntime(DateTime).isAssignableFromType(type)) {
    return ColumnType.timeStamp;
  }
  if (const TypeChecker.fromRuntime(Map).isAssignableFromType(type)) {
    return ColumnType.jsonb;
  }
  if (const TypeChecker.fromRuntime(List).isAssignableFromType(type)) {
    /* print('${field.name} : ${field.type} : ${field.metadata}');
    for (var annot in field.metadata) {
      print('\t annot toSource: ${annot.toSource()}');
    } */
    if (field.metadata
        .where((annot) => annot.toSource() == '@Lob()')
        .isNotEmpty) {
      return ColumnType.blob;
    }
    return ColumnType.jsonb;
  }
  if (type is InterfaceType && type.element is EnumElement) {
    return ColumnType.int;
  }

  // Default to varChar
  return ColumnType.varChar;
}

/// Can passed to a [MigrationColumn] to default to a raw SQL expression.
class RawSql {
  /// The raw SQL text.
  final String value;

  const RawSql(this.value);
}

const RawSql currentTimestamp = RawSql('CURRENT_TIMESTAMP');
