import 'package:brocode_server/brocode_server.dart' as brocode_server;
import 'package:shelf/shelf_io.dart' as io;

void main(List<String> arguments) async {
  final routes = brocode_server.BrocodeRoutes();

  final serverIP = "0.0.0.0";  // use 127.0.0.1 when running without docker
  var server = await io.serve(routes.handler, serverIP, 8080);

  print("Server started at ${server.address.address}:${server.port}");
}
