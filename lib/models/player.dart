import 'dart:io';

import 'vector_2.dart';

class Player {
  Player({required this.socket, required this.name, required this.id});
  final Socket socket;
  final String name;
  final int id;

  int _lastUpdate = 0;
  bool isAFK = false;
  bool _hasLeft = false;

  bool hasShot = false;
  bool hasJumped = false;
  Vector2 aimDirection = Vector2();
  Vector2 position = Vector2();
  double horizontalDirection = 0.0;
  int healthPoints = 100;
  bool isReloading = false;
  bool isDead = false;

  /// init the player for the game
  void startGame(int time) {
    if(!isAFK) {
      _lastUpdate = time;
    }
  }

  /// Check if the player is AFK and return the result
  bool updateIsAFK() {
    if(_hasLeft) {
      isAFK = true;
      return true;
    }
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    isAFK = currentTime - _lastUpdate > 1000 * 60 * 2;
    return isAFK;
  }

  /// set the player as AFK
  void playerLeftGame() {
    _hasLeft = true;
    isAFK = true;
  }

  /// Update the player state
  void update(bool hasShot, bool hasJumped, Vector2 aimDirection, double horizontalDirection, int healthPoints, bool isReloading, bool isDead, Vector2 position) {
    this.hasShot = hasShot;
    this.hasJumped = hasJumped;
    this.aimDirection = aimDirection;
    this.position = position;
    this.horizontalDirection = horizontalDirection;
    this.healthPoints = healthPoints;
    this.isReloading = isReloading;
    this.isDead = isDead;

    _lastUpdate = DateTime.now().millisecondsSinceEpoch;
  }

  /// Update the player from a Map
  int updateFromJson(Map<String, dynamic> jsonState) {
    final hasShot = bool.tryParse(jsonState["hasShot"]);
    final hasJumped = bool.tryParse(jsonState["hasJumped"]);
    final horizontalDirection = double.tryParse(jsonState["horizontalDirection"]);
    final healthPoints = int.tryParse(jsonState["healthPoints"]);
    final isReloading = bool.tryParse(jsonState["isReloading"]);
    final isDead = bool.tryParse(jsonState["isDead"]);

    if(hasShot == null || hasJumped == null || horizontalDirection == null || healthPoints == null || isReloading == null || isDead == null) {
      print("Json with missing or wrongly typed values: $jsonState");
      return 400;
    }

    try {
      final aimDirection = Vector2.fromJson(jsonState["aimDirection"]);
      final position = Vector2.fromJson(jsonState["position"]);
      update(hasShot, hasJumped, aimDirection, horizontalDirection, healthPoints, isReloading, isDead, position);
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
      "isAFK": isAFK,
      "hasLeft": _hasLeft,
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
      "position": {
        "x": position.x,
        "y": position.y,
      },
      "horizontalDirection": horizontalDirection,
      "healthPoints": healthPoints,
      "isReloading": isReloading,
      "isDead": isDead,
    };
  }
}