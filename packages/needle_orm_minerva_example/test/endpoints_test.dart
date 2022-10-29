import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'test_app_setting.g.dart';

void main() {
  group('Endpoints', () {
    final Dio dio = Dio();

    final String host = $TestAppSetting.host;

    final int port = $TestAppSetting.port;

    test('GET /hello', () async {
      var response = await dio.get('http://$host:$port/hello');

      expect(response.data, 'Hello, world!');
    });
  });
}
