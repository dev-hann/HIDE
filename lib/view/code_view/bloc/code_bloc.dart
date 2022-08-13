library code_bloc;

import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/enum/short_cut_type.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/syntax.dart';
import 'package:h_ide/repo/code/code_impl.dart';
import 'package:h_ide/repo/lsp/lsp_impl.dart';
import 'package:h_ide/use_case/code/code_use_case.dart';
import 'package:h_ide/use_case/lsp/lsp_use_case.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

part 'code_event.dart';
part 'code_state.dart';

const syntaxMap = <String, TextStyle>{
  "class": TextStyle(color: Colors.orange),
  "import": TextStyle(color: Colors.greenAccent),
  "extends": TextStyle(color: Colors.orangeAccent),
};

class CodeBloc extends Bloc<CodeEvent, CodeState> {
  CodeBloc() : super(const CodeState()) {
    on<CodeInitialized>(_onInit);
    on<CodeFileOpened>(_onFileOpened);
    on<CodeFileClosed>(_onFileClosed);
    on<CodeOnTapKey>(_onTapKey);
  }

  final CodeUseCase useCase = CodeUseCase(CodeImpl());
  final LSPUseCase lspUseCase = LSPUseCase(LSPImpl());
  EditorController? get controller {
    final index = state.index;
    if (index == -1) {
      return null;
    }
    return state.controllerList[index];
  }

  List<HFile> get fileList {
    return state.controllerList.map((e) => e.file).toList();
  }

  FutureOr<void> _onInit(CodeInitialized event, Emitter<CodeState> emit) async {
    emit(
      state.copyWith(
        state: CodeStatus.success,
        syntaxMap: useCase.loadSyntax(),
      ),
    );
  }

  FutureOr<void> _onFileOpened(
      CodeFileOpened event, Emitter<CodeState> emit) async {
    emit(state.copyWith(state: CodeStatus.loading));
    final onTappedFile = event.file;
    final list = [...state.controllerList];
    int index =
        list.map((e) => e.file).toList().indexWhere((e) => e == onTappedFile);
    if (index == -1) {
      final controller = EditorController(
        file: onTappedFile,
        syntax: state.syntaxMap[onTappedFile.extension],
      );
      list.add(controller);
      index = list.length - 1;
    }
    emit(state.copyWith(
      state: CodeStatus.success,
      index: index,
      controllerList: list,
    ));
  }

  FutureOr<void> _onFileClosed(CodeFileClosed event, Emitter<CodeState> emit) {
    emit(state.copyWith(state: CodeStatus.loading));
    final onTappedFile = event.file;
    final list = [...state.controllerList];
    int index =
        list.map((e) => e.file).toList().indexWhere((e) => e == onTappedFile);
    final isSelected = state.index == index;
    if (index != -1) {
      list.removeAt(index);
      if (list.isEmpty) {
        index = -1;
      } else {
        if (isSelected) {
          index = max(index - 1, 0);
        } else {
          index = state.index - 1;
        }
      }
      emit(
        state.copyWith(
          state: CodeStatus.success,
          controllerList: list,
          index: index,
        ),
      );
    }
  }

  FutureOr<void> _onTapKey(CodeOnTapKey event, Emitter<CodeState> emit) {
    final key = event.key;
    if (key.isAltPressed || key.isControlPressed) {
      emit(
        state.copyWith(
          state: CodeStatus.success,
          readOnly: true,
        ),
      );
      // check shortcut db
      for (final type in ShortCutType.values) {
        if (key.isKeyPressed(type.initKey()) ||
            key.isKeyPressed(type.commandKey())) {
          switch (type) {
            case ShortCutType.suggestion:
              lspUseCase.completionGetSuggestions(event.filePath, event.offset);
          }
        }
      }
    } else {
      emit(
        state.copyWith(
          state: CodeStatus.success,
          readOnly: false,
        ),
      );
    }
  }
}
