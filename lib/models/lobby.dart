

import '../utils/utils.dart';
import 'player.dart';

class Lobby {
  Lobby({required this.lobbyName, required String lobbyOwnerName}) {
    _id = Utils.getRandomUniqueIdentifier(12);
    players.add(Player(name: lobbyOwnerName, id: 0));
  }

  final String lobbyName;
  late String _id;
  String get id => _id;

  List<Player> players = [];

  void addPlayer(String playerName) {
    players.add(Player(name: playerName, id: players.length - 1));
  }

  Map<String, dynamic> toJson({bool summary = false}) {
    if(summary) {
      return {
        "id": id,
        "name": lobbyName,
        "owner": players[0].toJson(summary: true),
      };
    }

    return {
      "id": id,
      "name": lobbyName,
      "players": [
        ...players.map((player) => player.toJson())
      ],
    };
  }
}