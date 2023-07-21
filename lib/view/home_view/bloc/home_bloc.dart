import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeEventUpdateLeftPanelSize>(_onUpdateLeftPanelSize);
    on<HomeEventUpdateBottomPanelSize>(_onUpdateBottomPanelSize);
  }

  FutureOr<void> _onUpdateLeftPanelSize(
      HomeEventUpdateLeftPanelSize event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        leftPanelSize: event.size,
      ),
    );
  }

  FutureOr<void> _onUpdateBottomPanelSize(
      HomeEventUpdateBottomPanelSize event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        bottomPanelSize: event.size,
      ),
    );
  }
}
