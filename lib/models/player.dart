import 'vector_2.dart';

class Player {
  Player({required this.name, required this.id});
  final String name;
  final int id;

  bool hasShot = false;
  bool hasJumped = false;
  Vector2 aimDirection = Vector2();
  double horizontalDirection = 0.0;

  void update(bool hasShot, bool hasJumped, Vector2 aimDirection, double horizontalDirection) {
    this.hasShot = hasShot;
    this.hasJumped = hasJumped;
    this.aimDirection = aimDirection;
    this.horizontalDirection = horizontalDirection;
  }

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
    if(summary) {
      return {
        "id": id,
        "name": name,
      };
    }

    return {
      "id": id,
      "name": name,
      "state": getJsonPlayerState(),
    };
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