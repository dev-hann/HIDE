library finder_bloc;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/h_folder.dart';
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

  FutureOr<void> _onInit(FinderInitialized event, Emitter<FinderState> emit) {
    final folder = useCase.currentFolder();
    emit(
      state.copyWith(
          state: FinderStatus.success,
          currentFolder: useCase.currentFolder(),
          openedMap: {folder: true}),
    );
  }

  FutureOr<void> _onSelected(
      FinderOnSelectedFile event, Emitter<FinderState> emit) {
    emit(state.copyWith(state: FinderStatus.loading));
    final file = event.file;
    if (file.isBinary) {
      print("isBinary");
    } else {
      final map = useCase.toggleFolderOpen(state.openedMap, file);
      emit(
        state.copyWith(
          state: FinderStatus.success,
          openedMap: map,
        ),
      );
    }
  }

  bool isOpendFolder(HFileFolder folder) {
    return state.openedMap[folder] ?? false;
  }
}
