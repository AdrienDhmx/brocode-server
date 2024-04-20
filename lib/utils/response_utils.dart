import 'package:shelf/shelf.dart';

Response lobbyNotFound(String missingLobbyId) {
  return Response.badRequest(body: "Lobbby $missingLobbyId not found.");
}

Response playerNotFound(String lobbyId, int missingPlayerId) {
  return Response.badRequest(body: "Player $missingPlayerId not found in this lobby $lobbyId");
}

