import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/migration_generator.dart';

Builder ormMigrationGenerator(BuilderOptions options) =>
    SharedPartBuilder([NeedleOrmMigrationGenerator()], 'needle_orm_migration');
