import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';

part 'panel_event.dart';
part 'panel_state.dart';

class PanelBloc extends Bloc<PanelEvent, PanelState> {
  PanelBloc() : super(const PanelState()) {
    on<PanelEventInited>(_onInit);
    on<PanelEventOpenFile>(_onOpenFile);
    on<PanelEventCloseFile>(_onCloseFile);
  }
  FutureOr<void> _onInit(PanelEventInited event, Emitter<PanelState> emit) {
    emit(
      state.copyWith(
        controllerMap: {},
      ),
    );
  }

  FutureOr<void> _onOpenFile(
      PanelEventOpenFile event, Emitter<PanelState> emit) {
    final list = state.fileList;
    final file = event.file;
    final index = list.indexOf(file);
    if (index != -1) {
      emit(
        state.copyWith(
          selectedIndex: index,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedIndex: list.length,
          fileList: [...list, event.file],
        ),
      );
    }
  }

  FutureOr<void> _onCloseFile(
      PanelEventCloseFile event, Emitter<PanelState> emit) {
    final list = state.fileList;
    final file = event.file;
    list.remove(file);
    int selectedIndex = state.selectedIndex;
    if (list.isEmpty) {
      selectedIndex = -1;
    }
    if (list.length == state.selectedIndex) {
      selectedIndex = list.length - 1;
    }

    emit(
      state.copyWith(
        selectedIndex: selectedIndex,
        fileList: [...list],
      ),
    );
  }
}
