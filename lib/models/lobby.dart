import 'dart:io';

import 'package:brocode_server/utils/socket_utils.dart';

import '../utils/utils.dart';
import 'player.dart';

enum LobbyStatus {
  waiting,
  inGame,
  over,
}

class Lobby {
  Lobby({required this.lobbyName, required Player lobbyOwner}) {
    _id = Utils.getRandomUniqueIdentifier(12);
    players.add(lobbyOwner);
  }

  final String lobbyName;
  late String _id;
  String get id => _id;

  LobbyStatus status = LobbyStatus.waiting;
  bool get isWaiting => status == LobbyStatus.waiting;

  int startTime = 0;

  List<Player> _players = [];
  List<Player> get players => _players;
  List<Player> get activePlayers => _players.where((p) => !p.isAFK).toList();

  /// start the game for this lobby
  void startGame() {
    startTime = DateTime.now().millisecondsSinceEpoch;
    status = LobbyStatus.inGame;
    for (Player player in players) {
      player.startGame(startTime);
    }
    notifyAllPlayers("gameStarting", toJson());
  }

  /// Check all players to see if they are AFK
  void checkAFKPlayers() {
    if(status != LobbyStatus.inGame) {
      return;
    }

    for (Player p in _players) {
      p.updateIsAFK();
    }
  }

  /// Create and add a player to the lobby with this name
  Player addPlayer(Socket socket, String playerName) {
    final player = Player(socket: socket, name: playerName, id: _players.length);
    _players.add(player);
    return player;
  }

  /// Set the player as AFK (doesn't remove the player from the list of players)
  Player? removePlayer(int playerId) {
    final player = getPlayer(playerId);
    if(player != null) {
      player.playerLeftGame();
    }
    return player;
  }

  void removeAllPlayers() {
    _players = [];
  }

  Player? getPlayer(int playerId) {
    if(playerId < 0 || playerId > players.length - 1) {
      return null;
    }
    return _players[playerId];
  }

  void notifyAllPlayers(String action, Map<String, dynamic> data) {
    for(Player player in _players) {
      player.socket.writeAction(action, data);
    }
  }

  void notifyAllPlayersExcept(String action, Map<String, dynamic> data, {required int playerId}) {
    for(Player player in activePlayers) {
      if(player.id != playerId) {
        player.socket.writeAction(action, data);
      }
    }
  }

  Map<String, dynamic> toJson({bool summary = false, bool playerSummary = false}) {
    final defaultJson = {
      "id": id,
      "name": lobbyName,
      "lobbyStatus": status.index,
      "startTime": startTime,
    };

    if(summary) {
      return {
        ...defaultJson,
        "owner": _players[0].toJson(summary: true),
      };
    }

    return {
      ...defaultJson,
      "players": [
        ..._players.map((player) => player.toJson(summary: playerSummary))
      ],
    };
  }
}