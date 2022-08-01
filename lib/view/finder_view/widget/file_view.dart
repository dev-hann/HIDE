import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';

class HFileView extends StatelessWidget {
  const HFileView({
    Key? key,
    required this.fileList,
  }) : super(key: key);
  final List<HFile> fileList;
  Widget fileView(HFile file) {
    return Row(
      children: [
        const Icon(Icons.file_open),
        Text(file.path),
      ],
    );
  }

  Widget folderView(HFile folder) {
    return Row(
      children: [
        const Icon(Icons.folder),
        Text(folder.path),
      ],
    );
  }

  Widget children(bool isOpened, List<HFile> fileList) {
    if (!isOpened) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: HFileView(
        key: UniqueKey(),
        fileList: fileList,
      ),
    );
  }

  Widget item(HFile file) {
    if (file.isBinary) {
      return fileView(file);
    }
    return BlocBuilder<FinderBloc, FinderState>(builder: (context, state) {
      final bloc = BlocProvider.of<FinderBloc>(context);
      final path = file.path;
      final isOpened = bloc.isOpened(path);
      final list = bloc.fileList(path);
      return Column(
        children: [
          GestureDetector(
              onTap: () {
                bloc.add(FinderOnSelectedFile(path, list));
              },
              child: folderView(file)),
          children(isOpened, list),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: fileList.map(item).toList(),
    );
  }
}
