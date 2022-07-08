A complete example for [Needle ORM](https://pub.dev/packages/needle_orm).

Get Started:

# Define models

* write everything in domain.dart

# Run generator

    dart run build_runner build

# Run migration to update Database Schema

Of course, all databases need to be created first, then create database schema:

    dart run bin/migration.dart

# Run example

    dart run bin/main.dart

# explore sample code 

- lib/common.dart : how to create connections to MariaDB / PostgreSQL
- bin/main.dart : how to use Needle ORM