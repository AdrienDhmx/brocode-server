import 'dart:io';

import 'package:brocode_server/brocode_server.dart';

void main(List<String> arguments) async {
  final serverIP = Platform.environment['BROCODE_SERVER_IP'] ?? "127.0.0.1"; // use 127.0.0.1 when running without docker
  final brocodeService = BrocodeService(serverIP: serverIP);
  brocodeService.start();
}
