import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/h_folder.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';

class HFileView extends StatelessWidget {
  const HFileView({
    Key? key,
    required this.file,
    required this.rootPath,
    required this.onTapFile,
  }) : super(key: key);

  final HFile file;
  final String rootPath;
  final Function(HFile file) onTapFile;
  bool get isFolder => file.isFolder;
  String get path {
    final filePath = file.path;
    if (filePath == rootPath) {
      return rootPath;
    }
    return filePath.replaceFirst(rootPath, "").substring(1);
  }

  Widget fileView() {
    return Row(
      children: [
        const Icon(Icons.file_open),
        Text(path),
      ],
    );
  }

  Widget folderView() {
    return Row(
      children: [
        const Icon(Icons.folder),
        Text(path),
      ],
    );
  }

  Widget children() {
    return Builder(builder: (conetxt) {
      final folder = file as HFileFolder;
      final isOpend =
          BlocProvider.of<FinderBloc>(conetxt).isOpendFolder(folder);
      if (!isOpend) {
        return const SizedBox();
      }
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: folder.children
              .map(
                (file) => HFileView(
                  file: file,
                  rootPath: rootPath,
                  onTapFile: onTapFile,
                ),
              )
              .toList(),
        ),
      );
    });
  }

  Widget item() {
    if (!isFolder) {
      return fileView();
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          folderView(),
          children(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapFile(file);
      },
      child: item(),
    );
  }
}
