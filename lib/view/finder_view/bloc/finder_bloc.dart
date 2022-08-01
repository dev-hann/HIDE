library finder_bloc;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/repo/finder/finder_impl.dart';
import 'package:h_ide/use_case/finder/finder_use_case.dart';

part 'finder_state.dart';
part 'finder_event.dart';

class FinderBloc extends Bloc<FinderEvent, FinderState> {
  FinderBloc() : super(const FinderState()) {
    on<FinderInitialized>(_onInit);
    on<FinderOnSelectedFile>(_onSelected);
  }

  final FinderUseCase useCase = FinderUseCase(FinderImpl());

  FutureOr<void> _onInit(
      FinderInitialized event, Emitter<FinderState> emit) async {
    await useCase.init();
    final rootPath = useCase.rootPath();
    emit(state.copyWith(
      state: FinderStatus.success,
      fileMap: {rootPath: useCase.fileList(rootPath)},
    ));
    await emit.forEach<Map<String, List<HFile>>>(
      useCase.fileMapStream(),
      onData: (data) {
        return state.copyWith(
          state: FinderStatus.success,
          // fileMap: data,
        );
      },
    );
  }

  FutureOr<void> _onSelected(
      FinderOnSelectedFile event, Emitter<FinderState> emit) {
    emit(state.copyWith(state: FinderStatus.loading));
    final map = state.fileMap;
    final path = event.path;
    if (map.containsKey(path)) {
      map.remove(path);
    } else {
      map[path] = event.fileList;
    }
    emit(
      state.copyWith(
        state: FinderStatus.success,
        fileMap: map,
      ),
    );
  }

  String rootPath() {
    return useCase.rootPath();
  }

  bool isOpened(String path) {
    return state.fileMap.containsKey(path);
  }

  List<HFile> fileList(String path) {
    return state.fileMap[path] ?? useCase.fileList(path);
  }
}
