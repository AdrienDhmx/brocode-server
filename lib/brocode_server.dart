import 'dart:convert';
import 'dart:io';

import 'package:brocode_server/utils/socket_utils.dart';
import 'package:brocode_server/utils/utils.dart';

import 'models/lobby.dart';
import 'models/player.dart';
import 'models/vector_2.dart';

class BrocodeService {
  List<Lobby> lobbies = [];
  final String serverIP;

  BrocodeService({required this.serverIP});

  void startSocketServer(InternetAddress address, int port) async {
    final serverSocket = await ServerSocket.bind(address, port);
    print('Socket server listening on ws://${address.address}:$port');

    await for (Socket socket in serverSocket) {
      handleSocket(socket);
    }
  }

  void handleSocket(Socket socket) {
    print('New Socket connection');

    socket.listen((List<int> data) {
      final message = utf8.decode(data);
      try {
        final jsonData = jsonDecode(message);
        handleMessage(socket, jsonData);
      } catch(e) {
        print("$e: $message");
      }
    },
    onError: (error) {
      print('Socket error: $error');
    },
    onDone: () {
      print('Socket connection closed');
      socket.close();
    });
  }

  /// Handle incoming Socket messages
  void handleMessage(Socket socket, Map<String, dynamic> data) {
    switch (data['action']) {
      case 'getAvailableLobbies':
        handleGetLobbiesInWaiting(socket);
        break;
      case 'createLobby':
        handleCreateLobby(socket, data);
        break;
      case 'getLobby':
        handleGetLobby(socket, data);
        break;
      case 'deleteLobby':
        handleDeleteLobby(socket, data);
        break;
      case 'joinLobby':
        handleJoinLobby(socket, data);
        break;
      case 'playerLeaveLobby':
        handlePlayerLeaveLobby(socket, data);
        break;
      case 'updatePlayer':
        handleUpdatePlayer(socket, data);
        break;
      case 'startGame':
        handleStartGame(socket, data);
        break;
      default:
        socket.writeError('Unknown action: ${data['action']}');
    }
  }

  void handleGetLobbiesInWaiting(Socket socket) {
    final lobbiesJson = {
      "lobbies": lobbies.where((l) => l.isWaiting).map((l) => l.toJson()).toList(),
    };
    socket.writeAction("availableLobbiesResponse", lobbiesJson);
  }

  void handleCreateLobby(Socket socket, Map<String, dynamic> data) {
    final lobbyName = data["name"]?.toString();
    final lobbyOwnerName = data["ownerName"]?.toString();

    if (lobbyName == null || lobbyOwnerName == null) {
      socket.writeError('Invalid parameters');
      return;
    }

    final player = Player(socket: socket, name: lobbyOwnerName, id: 0);
    final lobby = Lobby(lobbyName: lobbyName, lobbyOwner: player);
    lobbies.add(lobby);

    socket.writeAction("lobbyCreatedResponse", lobby.toJson());
  }

  void handleGetLobby(Socket socket, Map<String, dynamic> data) {
    final lobbyId = data["lobbyId"]?.toString() ?? '';
    final lobby = lobbies.findById(lobbyId);
    if (lobby == null) {
      socket.writeLobbyNotFoundError(data["lobbyId"]);
      return;
    }
    lobby.checkAFKPlayers();
    socket.writeAction("lobby", lobby.toJson());
  }

  void handleDeleteLobby(Socket socket, Map<String, dynamic> data) {
    final lobbyId = data["lobbyId"]?.toString() ?? '';
    final lobby = lobbies.removeById(lobbyId);
    if (lobby == null) {
      socket.writeLobbyNotFoundError(data["lobbyId"]);
      return;
    } else if (lobby.players.isNotEmpty) {
      lobby.notifyAllPlayers("lobbyClosing", {});
      lobby.removeAllPlayers();
    }
  }

  void handleJoinLobby(Socket socket, Map<String, dynamic> data) {
    final lobbyId = data["lobbyId"]?.toString() ?? '';
    final lobby = lobbies.findById(lobbyId);
    if (lobby == null) {
      socket.writeLobbyNotFoundError(data["lobbyId"]);
      return;
    } else if (lobby.status != LobbyStatus.waiting) {
      socket.writeError("The lobby doesn't accept new players at the moment.");
      return;
    }

    final playerName = data["name"]?.toString();
    if (playerName == null) {
      socket.writeError("The parameter 'name' for the player name is required");
      return;
    }

    final player = lobby.addPlayer(socket, playerName);
    final lobbyData = lobby.toJson(summary: false, playerSummary: false);
    lobby.notifyAllPlayersExcept("playerJoining", player.toJson(), playerId: player.id);
    socket.writeAction("joinLobbyResponse", lobbyData);
  }

  void handlePlayerLeaveLobby(Socket socket, Map<String, dynamic> data) {
    final lobbyId = data["lobbyId"]?.toString() ?? '';
    final playerId = data["playerId"]?.toString() ?? '';
    final lobby = lobbies.findById(lobbyId);
    if (lobby == null) {
      socket.writeLobbyNotFoundError(data["lobbyId"]);
      return;
    }

    final intPlayerId = int.tryParse(playerId);
    if (intPlayerId == null) {
      socket.writeError('The playerId must be an int.');
      return;
    }

    final player = lobby.removePlayer(intPlayerId);
    if (player == null) {
      socket.writeError('Player not found');
      return;
    }
    lobby.notifyAllPlayers("playerLeaving", player.toJson());
  }

  void handleUpdatePlayer(Socket socket, Map<String, dynamic> data) {
    final lobbyId = data["lobbyId"]?.toString() ?? '';
    final playerId = data["playerId"]?.toString() ?? '';
    final lobby = lobbies.findById(lobbyId);
    if (lobby == null) {
      socket.writeLobbyNotFoundError(data["lobbyId"]);
      return;
    }
    final intPlayerId = int.tryParse(playerId);
    if (intPlayerId == null) {
      socket.writeError('The playerId must be an int.');
      return;
    }

    final player = lobby.getPlayer(intPlayerId);
    if (player == null) {
      socket.writeError('Player not found');
      return;
    }

    final hasShot = bool.tryParse(data["hasShot"]);
    final hasJumped = bool.tryParse(data["hasJumped"]);
    final horizontalDirection = Utils.tryParseToDouble(data["horizontalDirection"]);
    final healthPoints = int.tryParse(data["healthPoints"]);
    final isReloading = bool.tryParse(data["isReloading"]);

    if (hasShot == null || hasJumped == null || horizontalDirection == null || healthPoints == null || isReloading == null) {
      socket.writeError('Body with missing or wrongly typed values');
      return;
    }

    try {
      final aimDirection = Vector2.fromJson(data["aimDirection"]);
      player.update(hasShot, hasJumped, aimDirection, horizontalDirection, healthPoints, isReloading);
      // notify all players of the update
      lobby.notifyAllPlayersExcept("playerUpdated", player.toJson(), playerId: intPlayerId);
    } on ArgumentError catch (_) {
      socket.writeError('Body with missing or wrongly typed aimDirection');
    }
  }

  void handleStartGame(Socket socket, Map<String, dynamic> data) {
    final lobbyId = data["lobbyId"]?.toString() ?? '';
    final lobby = lobbies.findById(lobbyId);
    if (lobby == null) {
      socket.writeLobbyNotFoundError(data["lobbyId"]);
      return;
    }
    // lobby notify all players
    lobby.startGame();
  }

  void start() {
    final address = InternetAddress.tryParse(serverIP);
    startSocketServer(address ?? InternetAddress.anyIPv4, 8083);
  }
}
