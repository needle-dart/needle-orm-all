## 0.0.4

 - **FIX**: repository link in README.md.
 - **FIX**: document/yaml.
 - **FEAT**: implement @PostLoad.
 - **FEAT**: only update when fields are truely modified.
 - **FEAT**: clean dirty mark after insert/update.
 - **FEAT**: replace _globalDb with Database.defaultDb.
 - **FEAT**: implement @Pre/PostPersist/Update...

# 0.0.3

* change Query() => query()
* fix lints issues
* remove unused code

# 0.0.2

* remove dart:cli from generated partial file, and explicitly load() for @ManyToOne property is mandatory before accessing properties.

# 0.0.1

* Initial version.
