

import '../utils/utils.dart';

class Vector2 {
  Vector2({this.x = 0.0, this.y = 0.0});

  double x;
  double y;

  static Vector2 fromJson(Map<String, dynamic> json) {
    final x = Utils.tryParseToDouble(json["x"]);
    final y = Utils.tryParseToDouble(json["y"]);

    if(x == null || y == null) {
      throw ArgumentError("The x and y are required: $json");
    }

    return Vector2(x: x, y: y);
  }
}