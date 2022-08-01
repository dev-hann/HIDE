import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';
import 'package:h_ide/view/finder_view/widget/file_view.dart';

class FinderView extends StatelessWidget {
  const FinderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinderBloc()..add(FinderInitialized()),
      child: _FinderView(),
    );
  }
}

class _FinderView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.red.withOpacity(0.5),
      child: BlocBuilder<FinderBloc, FinderState>(
        buildWhen: (pre, curr) {
          return pre != curr && curr.state == FinderStatus.success;
        },
        builder: (context, state) {
          final bloc = BlocProvider.of<FinderBloc>(context);
          final path = bloc.rootPath();
          final list = bloc.fileList(path);
          return SingleChildScrollView(
            child: HFileView(
              key: UniqueKey(),
              fileList: list,
            ),
          );
        },
      ),
    );
  }
}
