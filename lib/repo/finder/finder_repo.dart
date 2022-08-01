abstract class FinderRepo {
  Future init();
  void dispose();
  Stream<List<String>> folderListStream();
  String rootPath();
  List<String> fileList(String rootPath);

  List<String> folderList();
  bool isOpened(String path);
  Future openFolder(String path);
  Future closeFolder(String path);
}
