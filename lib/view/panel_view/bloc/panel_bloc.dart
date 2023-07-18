import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/widget/editor/editor.dart';

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
        pageController: PageController(),
        editorMap: {},
      ),
    );
  }

  Future<FutureOr<void>> _onOpenFile(
      PanelEventOpenFile event, Emitter<PanelState> emit) async {
    final Map<HFile, HEditor> map = {...state.editorMap};
    final list = map.keys.toList();
    final file = event.file;
    final index = list.indexOf(file);
    if (index != -1) {
      emit(
        state.copyWith(
          selectedIndex: index,
        ),
      );
    } else {
      map[file] = HEditor(file: file);
      emit(
        state.copyWith(
          selectedIndex: list.length,
          editorMap: map,
        ),
      );
    }
    final pageController = state.pageController;
    if (pageController?.hasClients ?? false) {
      pageController?.jumpToPage(state.selectedIndex);
    }
  }

  Future<FutureOr<void>> _onCloseFile(
      PanelEventCloseFile event, Emitter<PanelState> emit) async {
    final Map<HFile, HEditor> map = {...state.editorMap};
    final file = event.file;
    map.remove(file);
    int selectedIndex = state.selectedIndex;
    if (map.isEmpty) {
      selectedIndex = -1;
    }
    if (map.length == state.selectedIndex) {
      selectedIndex = map.length - 1;
    }

    emit(
      state.copyWith(
        selectedIndex: selectedIndex,
        editorMap: map,
      ),
    );
    final pageController = state.pageController;
    if (pageController?.hasClients ?? false) {
      pageController?.jumpToPage(state.selectedIndex);
    }
  }
}
