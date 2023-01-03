import 'dart:async';

import 'package:minerva/minerva.dart' hide Logger;
import 'package:needle_orm/api.dart';

import '../common/common.dart';
import 'domain.dart';

Future<void> initService(ServerContext context) async {
  context.logPipeline.info('init services ...');

  var configuration = ConfigurationManager();

  await configuration.load();
  Map<String, dynamic> dataSources = configuration['data-sources'];
  initLogger(context.logPipeline);

  var dsName = dataSources['default'];
  var dsCfg = dataSources[dsName]!;

  if (dsCfg['type'] == 'postgresql') {
    Database.register(dsName, await initPostgreSQL(dsCfg));
  } else if (dsCfg['type'] == 'mariadb') {
    Database.register(dsName, await initMariaDb(dsCfg));
  }

  initNeedle();

  Needle.currentUser = () {
    return Zone.current[#username];
  };
}
