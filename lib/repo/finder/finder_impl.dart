import 'dart:io';

import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderImpl implements FinderRepo {
  @override
  String currentPath() {
    return Directory.current.path;
  }
}
