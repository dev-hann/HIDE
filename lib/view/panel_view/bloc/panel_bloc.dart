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
    on<PanelEventUpdateFile>(_onUpdatedFile);
  }

  FutureOr<void> _onInit(PanelEventInited event, Emitter<PanelState> emit) {
    emit(
      state.copyWith(
        pageController: PageController(),
        fileList: [],
      ),
    );
  }

  Future<FutureOr<void>> _onOpenFile(
      PanelEventOpenFile event, Emitter<PanelState> emit) async {
    final list = [...state.fileList];
    final file = event.file;

    if (!list.contains(file)) {
      list.add(file);
    }
    emit(
      state.copyWith(
        selectedFile: file,
        fileList: list,
      ),
    );
    final pageController = state.pageController;
    if (pageController?.hasClients ?? false) {
      pageController?.jumpToPage(state.selectedIndex);
    }
  }

  Future<FutureOr<void>> _onCloseFile(
      PanelEventCloseFile event, Emitter<PanelState> emit) async {
    final list = state.fileList;
    final file = event.file;

    list.remove(file);

    emit(
      state.copyWith(
        selectedFile: file,
        fileList: [...list],
      ),
    );
    final pageController = state.pageController;
    if (pageController?.hasClients ?? false) {
      pageController?.jumpToPage(state.selectedIndex);
    }
  }

  FutureOr<void> _onUpdatedFile(
      PanelEventUpdateFile event, Emitter<PanelState> emit) async {
    final list = state.fileList;
    final file = event.file;
    final index = list.indexWhere((element) => element.path == file.path);
    if (index == -1) {
      return;
    }
    list[index] = file;
    emit(
      state.copyWith(
        fileList: [...list],
      ),
    );
  }
}
