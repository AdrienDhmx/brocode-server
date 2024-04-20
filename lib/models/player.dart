import 'vector_2.dart';

class Player {
  Player({required this.name, required this.id});
  final String name;
  final int id;

  int _lastUpdate = 0;
  bool _isAFK = false;
  bool _leftGame = false;

  bool hasShot = false;
  bool hasJumped = false;
  Vector2 aimDirection = Vector2();
  double horizontalDirection = 0.0;

  /// init the player for the game
  void startGame(int time) {
    if(!_isAFK) {
      _lastUpdate = time;
    }
  }

  /// Check if the player is AFK and return the result
  bool isAFK() {
    if(_leftGame) {
      return true;
    }
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    _isAFK = currentTime - _lastUpdate > 1000 * 60 * 2;
    return _isAFK;
  }

  /// set the player as AFK
  void playerLeftGame() {
    _leftGame = true;
    _isAFK = true;
  }

  /// Update the player state
  void update(bool hasShot, bool hasJumped, Vector2 aimDirection, double horizontalDirection) {
    this.hasShot = hasShot;
    this.hasJumped = hasJumped;
    this.aimDirection = aimDirection;
    this.horizontalDirection = horizontalDirection;

    _lastUpdate = DateTime.now().millisecondsSinceEpoch;
  }

  /// Update the player from a Map
  int updateFromJson(Map<String, dynamic> jsonState) {
    final hasShot = bool.tryParse(jsonState["hasShot"]);
    final hasJumped = bool.tryParse(jsonState["hasJumped"]);
    final horizontalDirection = double.tryParse(jsonState["horizontalDirection"]);

    if(hasShot == null || hasJumped == null || horizontalDirection == null) {
      print("Json with missing or wrongly typed values: $jsonState");
      return 400;
    }

    try {
      final aimDirection = Vector2.fromJson(jsonState["aimDirection"]);
      update(hasShot, hasJumped, aimDirection, horizontalDirection);
      return 200;
    } on ArgumentError catch (_, e) {
      print(e);
      return 400;
    }
  }

  Map<String, dynamic> toJson({bool summary = false}) {
    final Map<String, dynamic> json = {
      "id": id,
      "name": name,
      "isAFK": _isAFK,
    };

    if (!summary) {
      json.addAll(getJsonPlayerState());
    }

    return json;
  }

  Map<String, dynamic> getJsonPlayerState() {
    return {
      "hasShot": hasShot,
      "hasJumped": hasJumped,
      "aimDirection": {
        "x": aimDirection.x,
        "y": aimDirection.y,
      },
      "horizontalDirection": horizontalDirection,
    };
  }
}