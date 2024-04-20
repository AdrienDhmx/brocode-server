import 'dart:math';

import 'package:brocode_server/utils/type_def.dart';

import '../models/lobby.dart';

class Utils {
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _rnd = Random();

  static String getRandomUniqueIdentifier(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  static double? tryParseToDouble(dynamic value) {
    if(value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }
}

extension ListExtension on List {
  T? find<T>(Predicate<T> predicate) {
    for(T element in this) {
      if(predicate(element)) {
        return element;
      }
    }
    return null;
  }

  T? removeFirstWhere<T>(Predicate<T> predicate) {
    for(int i = 0; i < length; ++i) {
      if(predicate(this[i])) {
        return removeAt(i);
      }
    }
    return null;
  }
}

extension LobbyList on List<Lobby> {
  List<T> filterMap<T>({required Predicate<Lobby> predicate, required Mapper<Lobby, T> mapper}) {
    List<T> output = [];
    for(Lobby lobby in this) {
      if(predicate(lobby)) {
        output.add(mapper(lobby));
      }
    }
    return output;
  }

  Lobby? findById(String id) {
    return find((l) => l.id == id);
  }

  Lobby? removeById(String id) {
    return removeFirstWhere((l) => l.id == id);
  }
}