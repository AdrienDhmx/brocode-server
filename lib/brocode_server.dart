import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class BrocodeRoutes {
  Handler get handler {
    final app = Router();

    app.get('/', (Request request) {
      return Response.ok('Welcome to Brocode !');
    });

    app.get('/hello/<name>', (Request request, String name) {
      return Response.ok('hello $name');
    });

    app.post('/lobby', (Request request) async {
      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString);
      final lobbyName = body["name"];
      final lobbyOwnerName = body["ownerName"];
      return Response.ok("Lobby created with the name '$lobbyName' by '$lobbyOwnerName'.");
    });

    app.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return app.call;
  }
}
