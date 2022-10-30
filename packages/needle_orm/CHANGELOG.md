## 0.1.1

 - **FIX**: clear dirty mark after properties loaded from db.
 - **FEAT**: bump version: 0.1.0.

## 0.0.6

 - **FEAT**: readme: blob & clob support.
 - **FEAT**: support blob (List<int>) & clob (String).

## 0.0.5

 - **FIX**: small changelog format.
 - **FEAT**: support @Lob (for type List<int>).
 - **FEAT**: support blob column (Uint8List).
 - **FEAT**: Query reuses instance with the same id.

## 0.0.4+1

 - **FIX**: homepage & repository url in pubspec.yaml.

## 0.0.4

 - **FIX**: readme.
 - **FIX**: remove hard-coded soft-delete column name.
 - **FIX**: readme.
 - **FIX**: README.md.
 - **FIX**: repository link in README.md.
 - **FIX**: document/yaml.
 - **FEAT**: implement @PostLoad.
 - **FEAT**: find Model by raw sql.
 - **FEAT**: implement optimistic lock: @Version.
 - **FEAT**: replace _globalDb with Database.defaultDb.
 - **FEAT**: implement @Pre/PostPersist/Update...

## 0.0.3

  * change Query() => query()
  * fix lints issues
  
## 0.0.2

  * remove dart:cli dependency to make it runnable on almost everywhere (also make pub.dev happy :) ).

## 0.0.1

  * implement basic functions : insert/update/delete/findList/transaction ...