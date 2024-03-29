## 0.1.1

 - **FIX**: hard coded 'books'.
 - **FIX**: clear dirty mark after properties loaded from db.
 - **FEAT**: bump version: 0.1.0.
 - **FEAT**: support @Transient.

## 0.0.6

 - **FIX**: define blob column.
 - **FEAT**: bump version.

## 0.0.5

 - **FIX**: deprecated properties of analyzer.
 - **FIX**: small changelog format.
 - **FIX**: remove overrides.yaml.
 - **FEAT**: support @Lob (for type List<int>).
 - **FEAT**: support blob column (Uint8List).
 - **FEAT**: Query reuses instance with the same id.

## 0.0.4+1

 - **FIX**: homepage & repository url in pubspec.yaml.

## 0.0.4

 - **FIX**: repository link in README.md.
 - **FIX**: document/yaml.
 - **FEAT**: implement @PostLoad.
 - **FEAT**: only update when fields are truely modified.
 - **FEAT**: clean dirty mark after insert/update.
 - **FEAT**: replace _globalDb with Database.defaultDb.
 - **FEAT**: implement @Pre/PostPersist/Update...

## 0.0.3

* change Query() => query()
* fix lints issues
* remove unused code

## 0.0.2

* remove dart:cli from generated partial file, and explicitly load() for @ManyToOne property is mandatory before accessing properties.

## 0.0.1

* Initial version.
