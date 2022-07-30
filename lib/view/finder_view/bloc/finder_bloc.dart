library finder_bloc;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
    emit(
      state.copyWith(
        state: FinderStatus.success,
        currentFolder: useCase.currentFolder(),
      ),
    );
  }

  FutureOr<void> _onSelected(
      FinderOnSelectedFile event, Emitter<FinderState> emit) {}
}
