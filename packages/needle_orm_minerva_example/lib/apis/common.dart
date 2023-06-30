import 'package:minerva/minerva.dart';

import '../common/ncontext.dart';

abstract class ApiBase extends Api {
  late ConfigurationManager config;

  get logger => NContext.current!.logger!;

  @override
  Future<void> initialize(ServerContext context) async {
    config = ConfigurationManager();
    await config.load();
  }
}
