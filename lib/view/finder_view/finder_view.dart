import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';
import 'package:h_ide/view/panel_view/bloc/panel_bloc.dart';

class FinderView extends StatefulWidget {
  const FinderView({Key? key}) : super(key: key);

  @override
  State<FinderView> createState() => _FinderViewState();
}

class _FinderViewState extends State<FinderView> {
  FinderBloc get bloc => BlocProvider.of<FinderBloc>(context);
  PanelBloc get panelBloc => BlocProvider.of<PanelBloc>(context);

  @override
  void initState() {
    super.initState();
    bloc.add(FinderInitialized());
  }

  Widget fileView({
    required HFile file,
  }) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: () {
          panelBloc.add(
            PanelEventOpenFile(file),
          );
        },
        child: Row(
          children: [
            // const Icon(Icons.file_open),
            Text(
              file.name,
            ),
          ],
        ),
      );
    });
  }

  Widget folderView({
    required HFile folder,
  }) {
    Widget folderWidget(bool isOpened) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: isOpened ? "▾" : "▸",
              style: const TextStyle(
                color: HColor.orange,
              ),
            ),
            const TextSpan(text: " "),
            TextSpan(
              text: folder.name,
              style: const TextStyle(
                color: HColor.green,
              ),
            )
          ],
        ),
      );
    }

    Widget children(bool isOpened, List<HFile> fileList) {
      if (!isOpened) {
        return const SizedBox();
      }
      return Padding(
        padding: const EdgeInsets.only(left: 24),
        child: finderWidget(
          list: fileList,
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
            children(isOpened, list),
          ],
        );
      },
    );
  }

  Widget finderWidget({required List<HFile> list}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((file) {
        if (file.isBinary) {
          return fileView(
            file: file,
          );
        }
        return folderView(
          folder: file,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinderBloc, FinderState>(
      buildWhen: (pre, curr) {
        return pre != curr && curr.state == FinderStatus.success;
      },
      builder: (context, state) {
        final path = bloc.rootPath();
        final list = bloc.fileList(path);
        return DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyLarge!,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Up a Dir"),
                  Text(path),
                  finderWidget(
                    list: list,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
