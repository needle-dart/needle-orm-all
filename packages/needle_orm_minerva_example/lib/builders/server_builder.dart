import 'package:minerva/minerva.dart';

import '../services/services.dart';

class ServerBuilder extends MinervaServerBuilder {
  @override
  void build(ServerContext context) {
    // init database
    initService(context);

    // Inject dependency or resource
    context.store['message'] = 'Hello, world!';
  }
}
