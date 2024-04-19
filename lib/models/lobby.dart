

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

  List<Player> players = [];

  Player addPlayer(String playerName) {
    final player = Player(name: playerName, id: players.length - 1);
    players.add(player);
    return player;
  }

  Map<String, dynamic> toJson({bool summary = false, bool playerSummary = false}) {
    if(summary) {
      return {
        "id": id,
        "name": lobbyName,
        "owner": players[0].toJson(summary: true),
        "playerCount": players.length,
      };
    }

    return {
      "id": id,
      "name": lobbyName,
      "players": [
        ...players.map((player) => player.toJson(summary: playerSummary))
      ],
    };
  }
}