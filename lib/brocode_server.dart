import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models/lobby.dart';

class BrocodeService {
  Map<String, Lobby> lobbies = {};

  /// GET - /lobby <br>
  /// get all lobbies in waiting <br>
  /// @return a list of the lobbies in waiting with their owner
  void getLobbiesInWaitingRoute(Router app) {
    app.get('/lobby', (Request request) async {
      final lobbiesInWaiting = [];
      for (Lobby lobby in lobbies.values) {
        if(lobby.state == LobbyState.waiting) {
          lobbiesInWaiting.add(lobby.toJson(summary: true));
        }
      }

      final lobbiesJson = {
        "lobbies": lobbiesInWaiting,
      };
      return Response.ok(jsonEncode(lobbiesJson));
    });
  }

  /// POST - /lobby <br>
  /// create a lobby with "name" and a player who is the lobby owner with "ownerName" <br>
  /// @return the created lobby with its owner
  void createLobbyRoute(Router app) {
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

      return Response.ok(jsonEncode(lobby.toJson(playerSummary: true)));
    });
  }

  /// GET - /lobby/:lobbyId <br>
  /// Get the lobby with the given id (waiting lobbies only) <br>
  /// @return The lobby with all it's players and their state
  void getLobbyRoute(Router app) {
    app.get('/lobby/<LobbyId>', (Request request, String lobbyId) async {
      final lobby = lobbies[lobbyId];
      if(lobby == null) {
        return Response.badRequest(body: "Lobbby $lobbyId not found.");
      }
      return Response.ok(jsonEncode(lobby.toJson()));
    });
  }

  /// DELETE - /lobby/:lobbyId <br>
  /// Delete the lobby with the given id
  void deleteLobbyRoute(Router app) {
    app.delete('/lobby/<lobbyId>', (Request request, String lobbyId) {
      final lobby = lobbies.remove(lobbyId);
      if(lobby == null) {
        return Response.badRequest(body: "Lobbby $lobbyId not found.");
      }
      return Response.ok("Lobby deleted");
    });
  }

  /// POST - /lobby/:lobbyId <br>
  /// Join the lobby with the given id and create a player with the name "name" <br>
  /// @return The joined lobby with all its players and this created player
  void joinLobbyRoute(Router app) {
    app.post('/lobby/<lobbyId>', (Request request, String lobbyId) async {
      final lobby = lobbies[lobbyId];
      if(lobby == null) {
        return Response.badRequest(body: "Lobby $lobbyId not found");
      } else if(lobby.state != LobbyState.waiting) {
        return Response.forbidden("The lobby doesn't accept new players at the moment.");
      }

      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString);
      final playerName = body["name"]?.toString();
      if(playerName == null) {
        return Response.badRequest(body: "Player name is required");
      }

      final player = lobby.addPlayer(playerName);
      final json = {
        "lobby": lobby.toJson(playerSummary: true),
        "player": player.toJson(summary: true),
      };
      return Response.ok(jsonEncode(json));
    });
  }

  /// PUT - /lobby/:lobbyId/start-game <br>
  /// Start the game for this lobby
  void startGame(Router app) {
    app.put('/lobby/<lobbyId>/start-game', (Request request, String lobbyId){
      final lobby = lobbies[lobbyId];
      if(lobby == null) {
        return Response.badRequest(body: "Lobby $lobbyId not found");
      }

      lobby.state = LobbyState.inGame;
      return Response.ok("Game started.");
    });
  }

  Handler get handler {
    final app = Router();

    app.get('/', (Request request) {
      return Response.ok('Welcome to Brocode !');
    });

    // /lobby
    getLobbiesInWaitingRoute(app);
    createLobbyRoute(app);

    // /lobby/<lobbyId>
    getLobbyRoute(app);
    deleteLobbyRoute(app);
    joinLobbyRoute(app);

    // /lobby/<lobbyId>/start-game
    startGame(app);

    app.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return app.call;
  }
}
