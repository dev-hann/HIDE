import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';
import 'package:h_ide/view/finder_view/widget/file_view.dart';
import 'package:h_ide/view/home_view/bloc/home_bloc.dart';

class FinderView extends StatelessWidget {
  const FinderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinderBloc, FinderState>(
      buildWhen: (pre, curr) {
        return pre != curr && curr.state == FinderStatus.success;
      },
      builder: (context, state) {
        final bloc = BlocProvider.of<FinderBloc>(context);
        final path = bloc.rootPath();
        final list = bloc.fileList(path);
        BlocProvider.of<HomeBloc>(context).add(HomeAnalysisdRoots(path));
        return DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyText1!,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Up a Dir"),
                  Text(path),
                  HFileView(
                    rootPath: path,
                    key: ValueKey(path),
                    fileList: list,
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
