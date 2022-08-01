import 'package:hive_flutter/hive_flutter.dart';

abstract class HBox {
  String get name;
  late Box box;

  Future openBox() async {
    box = await Hive.openBox(name);
  }

  Future clearBox() async {
    await box.clear();
  }

  Stream<BoxEvent> stream() {
    return box.watch();
  }

  static Future init() async {
    await Hive.initFlutter();
  }
}
