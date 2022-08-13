library finder_bloc;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/repo/finder/finder_impl.dart';
import 'package:h_ide/repo/lsp/lsp_impl.dart';
import 'package:h_ide/use_case/finder/finder_use_case.dart';
import 'package:h_ide/use_case/lsp/lsp_use_case.dart';

part 'finder_state.dart';
part 'finder_event.dart';

class FinderBloc extends Bloc<FinderEvent, FinderState> {
  FinderBloc() : super(const FinderState()) {
    on<FinderInitialized>(_onInit);
    on<FinderOnSelectedFile>(_onSelected);
  }

  final FinderUseCase useCase = FinderUseCase(FinderImpl());
  final LSPUseCase lspUseCase = LSPUseCase(LSPImpl());
  FutureOr<void> _onInit(
      FinderInitialized event, Emitter<FinderState> emit) async {
    await useCase.init();
    await lspUseCase.init();
    lspUseCase.stream().listen((event) {
      print(event.toMap());
    });
    lspUseCase.setAnalysisRoots(useCase.rootPath());
    emit(
      state.copyWith(
        state: FinderStatus.success,
        opnedFolderList: useCase.folderList(),
      ),
    );
    await emit.forEach<List<String>>(
      useCase.folderListStream(),
      onData: (data) {
        return state.copyWith(
          state: FinderStatus.success,
          opnedFolderList: useCase.folderList(),
        );
      },
    );
  }

  FutureOr<void> _onSelected(
      FinderOnSelectedFile event, Emitter<FinderState> emit) {
    emit(state.copyWith(state: FinderStatus.loading));

    final path = event.path;
    useCase.toggleFolder(path);
  }

  String rootPath() {
    return useCase.rootPath();
  }

  bool isOpened(String path) {
    return state.opnedFolderList.contains(path);
  }

  List<HFile> fileList(String path) {
    return useCase.fileList(path);
  }
}
