import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';

class HFileView extends StatelessWidget {
  const HFileView({
    Key? key,
    required this.fileList,
    required String rootPath,
  })  : rootPath = "$rootPath/",
        super(key: key);
  final List<HFile> fileList;
  final String rootPath;
  Widget fileView(HFile file) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: () {
          BlocProvider.of<CodeBloc>(context).add(CodeFileOpened(file));
        },
        child: Row(
          children: [
            // const Icon(Icons.file_open),
            Text(file.path.replaceAll(rootPath, "")),
          ],
        ),
      );
    });
  }

  Widget folderView(HFile folder) {
    Widget folderWidget(bool isOpened) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: isOpened ? "▾" : "▸",
              style: const TextStyle(
                color: Color(orange),
              ),
            ),
            TextSpan(
              text: " ${folder.path.replaceAll(rootPath, "")}/",
              style: const TextStyle(
                color: Color(green),
              ),
            )
          ],
        ),
      );
    }

    Widget children(bool isOpened, String path, List<HFile> fileList) {
      if (!isOpened) {
        return const SizedBox();
      }
      return Padding(
        padding: const EdgeInsets.only(left: 24),
        child: HFileView(
          rootPath: path,
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
              child: folderWidget(isOpened),
            ),
            children(isOpened, path, list),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fileList.map(item).toList(),
    );
  }
}
