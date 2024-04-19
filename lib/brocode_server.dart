import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models/lobby.dart';

class BrocodeService {
  Map<String, Lobby> lobbies = {};

  Handler get handler {
    final app = Router();

    app.get('/', (Request request) {
      return Response.ok('Welcome to Brocode !');
    });

    app.get('/hello/<name>', (Request request, String name) {
      return Response.ok('hello $name');
    });

    app.get('/lobby', (Request request) async {
      final lobbiesJson = {
        "lobbies": [
          ...lobbies.values.map((lobby) => lobby.toJson(summary: true)),
        ]
      };
      return Response.ok(jsonEncode(lobbiesJson));
    });

    app.post('/lobby', (Request request) async {
      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString);
      final lobbyName = body["name"]?.toString();
      final lobbyOwnerName = body["ownerName"]?.toString();

      if(lobbyName == null || lobbyOwnerName == null) {
        return Response.badRequest(body: body);
      }

      final lobby = Lobby(lobbyName: lobbyName, lobbyOwnerName: lobbyOwnerName);
      lobbies[lobby.id] = lobby;

      return Response.ok(jsonEncode(lobby.toJson()));
    });

    app.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return app.call;
  }
}
