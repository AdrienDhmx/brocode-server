import 'dart:convert';
import 'package:brocode_server/utils/response_utils.dart';
import 'package:brocode_server/utils/utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models/lobby.dart';
import 'models/vector_2.dart';

class BrocodeService {
  List<Lobby> lobbies = [];

  /// GET - /lobby <br>
  /// get all lobbies in waiting <br>
  /// @return a list of the lobbies in waiting with their owner
  void getLobbiesInWaitingRoute(Router app) {
    app.get('/lobby', (Request request) async {
      final lobbiesJson = {
        "lobbies": lobbies.filterMap(predicate: (l) => l.isWaiting, mapper: (l) => l.toJson(summary: true)),
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
      lobbies.add(lobby);

      return Response.ok(jsonEncode(lobby.toJson(playerSummary: true)));
    });
  }

  /// GET - /lobby/:lobbyId <br>
  /// Get the lobby with the given id (waiting lobbies only) <br>
  /// @return The lobby with all it's players and their state
  void getLobbyRoute(Router app) {
    app.get('/lobby/<LobbyId>', (Request request, String lobbyId) async {
      final lobby = lobbies.findById(lobbyId);
      if(lobby == null) {
        return lobbyNotFound(lobbyId);
      }
      lobby.checkAFKPlayers();
      return Response.ok(jsonEncode(lobby.toJson()));
    });
  }

  /// DELETE - /lobby/:lobbyId <br>
  /// Delete the lobby with the given id
  void deleteLobbyRoute(Router app) {
    app.delete('/lobby/<lobbyId>', (Request request, String lobbyId) {
      final lobby = lobbies.removeById(lobbyId);
      if(lobby == null) {
        return lobbyNotFound(lobbyId);
      }
      return Response.ok("Lobby deleted");
    });
  }

  /// POST - /lobby/:lobbyId <br>
  /// Join the lobby with the given id and create a player with the name "name" <br>
  /// @return The joined lobby with all its players and this created player
  void joinLobbyRoute(Router app) {
    app.post('/lobby/<lobbyId>', (Request request, String lobbyId) async {
      final lobby = lobbies.findById(lobbyId);
      if(lobby == null) {
        return lobbyNotFound(lobbyId);
      } else if(lobby.status != LobbyStatus.waiting) {
        return Response.forbidden("The lobby doesn't accept new players at the moment.");
      }

      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString);
      final playerName = body["name"]?.toString();
      if(playerName == null) {
        return Response.badRequest(body: "The parameter 'name' for the player name is required");
      }

      final player = lobby.addPlayer(playerName);
      final json = {
        "lobby": lobby.toJson(playerSummary: true),
        "player": player.toJson(summary: true),
      };
      return Response.ok(jsonEncode(json));
    });
  }

  /// DELETE - /lobby/:lobbyId/player/:playerId <br>
  /// Remove this player from this lobby
  void playerLeaveLobbyRoute(Router app) {
    app.delete('/lobby/<lobbyId>/player/<playerId>', (Request request, String lobbyId, String playerId) {
      final lobby = lobbies.findById(lobbyId);
      if(lobby == null) {
        return lobbyNotFound(lobbyId);
      }

      final intPlayerId = int.tryParse(playerId);
      if(intPlayerId == null) {
        return Response.badRequest(body: "The playerId must be an int.");
      }

      final player = lobby.removePlayer(intPlayerId);
      if(player == null) {
        return playerNotFound(lobbyId, intPlayerId);
      }
      return Response.ok("Player $playerId removed from the lobby $lobbyId");
    });
  }

  /// PUT - /lobby/:lobbyId/player/:playerId <br>
  /// Update the state of this player.
  void updatePlayer(Router app) {
    app.put('/lobby/<lobbyId>/player/<playerId>', (Request request, String lobbyId, String playerId) async {
      final lobby = lobbies.findById(lobbyId);
      if(lobby == null) {
        return lobbyNotFound(lobbyId);
      }
      final intPlayerId = int.tryParse(playerId);
      if(intPlayerId == null) {
        return Response.badRequest(body: "The playerId must be an int.");
      }

      final player = lobby.getPlayer(intPlayerId);
      if(player == null) {
        return playerNotFound(lobbyId, intPlayerId);
      }
      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString);

      final hasShot = bool.tryParse(body["hasShot"]);
      final hasJumped = bool.tryParse(body["hasJumped"]);
      final horizontalDirection = Utils.tryParseToDouble(body["horizontalDirection"]);

      if(hasShot == null || hasJumped == null || horizontalDirection == null) {
        return Response.badRequest(body: "Body with missing or wrongly typed values: $bodyString");
      }

      try {
        final aimDirection = Vector2.fromJson(body["aimDirection"]);
        player.update(hasShot, hasJumped, aimDirection, horizontalDirection);
        return Response.ok("Player updated.");
      } on ArgumentError catch (_, e) {
        return Response.badRequest(body: "Body with missing or wrongly typed aimDirection: $bodyString");
      }
    });
  }

  /// PUT - /lobby/:lobbyId/start-game <br>
  /// Start the game for this lobby
  void startGame(Router app) {
    app.put('/lobby/<lobbyId>/start-game', (Request request, String lobbyId){
      final lobby = lobbies.findById(lobbyId);
      if(lobby == null) {
        return lobbyNotFound(lobbyId);
      }
      lobby.startGame();
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

    // /lobby/<lobbyId>/player/<playerId>
    playerLeaveLobbyRoute(app);
    updatePlayer(app);

    // /lobby/<lobbyId>/start-game
    startGame(app);

    app.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return app.call;
  }
}
