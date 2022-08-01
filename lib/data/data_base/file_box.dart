import 'package:h_ide/data/data_base/h_box.dart';

class FileBox extends HBox {
  @override
  String get name => "FileBox";

  List<dynamic> read() {
    return box.values.toList();
  }

  Future update(String path, dynamic data) async {
    await box.put(path, data);
  }
}
