import 'package:test/test.dart';

void main() {
  test('field filter test', () {
    FieldFilter ff =
        FieldFilter('name,price, author( *),editor ( name, email),id');

    expect(ff.fieldList.length, 5);
    expect(ff.fieldList[0], 'name');
    expect(ff.fieldList[2], 'author(*)');
    expect(ff.fieldList[3], 'editor(name,email)');
    expect(ff.fieldList[4], 'id');

    expect(ff.contains('name'), true);
    expect(ff.contains('price'), true);
    expect(ff.contains('author'), true);
    expect(ff.contains('editor'), true);
    expect(ff.contains('id'), true);
    expect(ff.contains('author2'), false);
    expect(ff.contains('editor2'), false);
    expect(ff.contains('age'), false);

    var ff2 = FieldFilter(ff.subFilter('editor'));
    expect(ff2.contains('email'), true);
    expect(ff2.contains('address'), false);

    var ff3 = FieldFilter(ff.subFilter('author'));
    expect(ff3.contains('email'), true);
    expect(ff3.contains('address'), true);
  });
}

class FieldFilter {
  final String fields;

  List<String> _fieldList = [];

  List<String> get fieldList => List.of(_fieldList);

  FieldFilter(this.fields) {
    _fieldList = _parseFields();
  }

  bool contains(String field, {String? idField}) {
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
