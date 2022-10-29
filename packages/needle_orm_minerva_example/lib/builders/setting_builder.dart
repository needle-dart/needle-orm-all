import 'package:minerva/minerva.dart';

import 'agents_builder.dart';
import 'apis_builder.dart';
import 'middlewares_builder.dart';
import 'server_builder.dart';
import 'loggers_builder.dart';
import 'dart:io';

class SettingBuilder extends MinervaSettingBuilder {
  @override
  MinervaSetting build() {
    // Creates server setting
    return MinervaSetting(
        instance: Platform.numberOfProcessors ~/ 2,
        loggersBuilder: LoggersBuilder(),
        // endpointsBuilder: EndpointsBuilder(),
        serverBuilder: ServerBuilder(),
        apisBuilder: ApisBuilder(),
        agentsBuilder: AgentsBuilder(),
        middlewaresBuilder: MiddlewaresBuilder());
  }
}
