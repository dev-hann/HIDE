
abstract class FinderRepo {
  Future init();
  void dispose();
  Stream<List<dynamic>> fileListStream();
  String currentPath();
  List<String> fileList(String rootPath);

  Future updateFile(String path, dynamic data);
}
