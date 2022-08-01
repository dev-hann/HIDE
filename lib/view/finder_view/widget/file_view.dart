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
    Widget folderWidget() {
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

    return BlocBuilder<FinderBloc, FinderState>(
      builder: (context, state) {
        final bloc = BlocProvider.of<FinderBloc>(context);
        final path = folder.path;
        final isOpened = bloc.isOpened(path);
        final list = bloc.fileList(path);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                bloc.add(FinderOnSelectedFile(path, list));
              },
              child: folderWidget(),
            ),
            children(isOpened, list),
          ],
        );
      },
    );
  }

  Widget item(HFile file) {
    if (file.isBinary) {
      return fileView(file);
    }
    return folderView(file);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fileList.map(item).toList(),
      ),
    );
  }
}
