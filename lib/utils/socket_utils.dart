
import 'dart:convert';
import 'dart:io';

extension SocketExtension on Socket {
  void writeAction(String action, Map<String, dynamic> data) {
    write(jsonEncode({"action": action, "data": data}));
  }

  void writeError(String errorMessage) {
    writeAction("error", {"message": errorMessage});
  }

  void writeLobbyNotFoundError(String lobbyId) {
    writeError("Lobbby $lobbyId not found.");
  }

  void writePlayerNotFound(String playerId, String lobbyId) {
    writeError("Player $playerId not found in this lobby $lobbyId");
  }
}

