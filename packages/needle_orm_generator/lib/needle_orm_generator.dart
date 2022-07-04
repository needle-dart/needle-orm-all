import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/model_class_generator.dart';
import 'src/meta_class_generator.dart';

/// generate all model enhance files.
Builder ormGenerator(BuilderOptions options) => SharedPartBuilder(
    [NeedleOrmMetaInfoGenerator(), NeedleOrmModelGenerator()], 'needle_orm');

// Builder ormGenerator2(BuilderOptions options) =>
//     SharedPartBuilder([NeedleOrmModelGenerator()], 'needle_orm');
