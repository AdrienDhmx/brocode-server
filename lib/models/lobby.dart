import '../utils/utils.dart';
import 'player.dart';

enum LobbyState {
  waiting,
  inGame,
  over,
}

class Lobby {
  Lobby({required this.lobbyName, required String lobbyOwnerName}) {
    _id = Utils.getRandomUniqueIdentifier(12);
    players.add(Player(name: lobbyOwnerName, id: 0));
  }

  final String lobbyName;
  late String _id;
  String get id => _id;

  LobbyState state = LobbyState.waiting;
  bool get isWaiting => state == LobbyState.waiting;

  int startTime = 0;

  List<Player> players = [];

  /// start the game for this lobby
  void startGame() {
    startTime = DateTime.now().millisecondsSinceEpoch;
    state = LobbyState.inGame;
    for (Player player in players) {
      player.startGame(startTime);
    }
  }

  /// Check all players to see if they are AFK
  void checkAFKPlayers() {
    if(state != LobbyState.inGame) {
      return;
    }

    for (Player p in players) {
      p.isAFK();
    }
  }

  /// Create and add a player to the lobby with this name
  Player addPlayer(String playerName) {
    final player = Player(name: playerName, id: players.length);
    players.add(player);
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

  Player? getPlayer(int playerId) {
    if(playerId < 0 || playerId > players.length - 1) {
      return null;
    }
    return players[playerId];
  }

  Map<String, dynamic> toJson({bool summary = false, bool playerSummary = false}) {
    final defaultJson = {
      "id": id,
      "name": lobbyName,
    };

    if(summary) {
      return {
        ...defaultJson,
        "owner": players[0].toJson(summary: true),
      };
    }

    return {
      ...defaultJson,
      "players": [
        ...players.map((player) => player.toJson(summary: playerSummary))
      ],
    };
  }
}