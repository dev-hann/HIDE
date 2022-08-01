part of finder_bloc;

abstract class FinderEvent {}

class FinderInitialized extends FinderEvent {}

class FinderOnSelectedFile extends FinderEvent {
  FinderOnSelectedFile(this.path, this.fileList);
  final String path;
  final List<HFile> fileList;
}
