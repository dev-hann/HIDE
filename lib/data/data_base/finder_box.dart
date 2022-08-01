import 'package:h_ide/data/data_base/h_box.dart';

class FinderBox extends HBox {
  @override
  String get name => "FinderBox";

  Future synchronizes(List<String> keyList) async {}
  List<String> read() {
    return List<String>.from(box.keys);
  }

  Future openFolder(String path) async {
    await box.put(path, true);
  }

  Future closeFolder(String path) async {
    await box.delete(path);
  }

  bool isOpened(String path) {
    return box.containsKey(path);
  }
}
