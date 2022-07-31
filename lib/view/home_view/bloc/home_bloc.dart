library home_bloc;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:h_ide/use_case/window/window_use_case.dart';

part 'home_state.dart';
part 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState()) {
    on<HomeInitialized>(_onInit);
  }

  late WindowUseCase windowUseCase;
  FutureOr<void> _onInit(HomeInitialized event, Emitter<HomeState> emit) async {
    windowUseCase = event.windowUseCase;
  }
}
