library code_bloc;

import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/model/h_file.dart';
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
  }

  final EditorController controller = EditorController(syntaxMap: syntaxMap);

  List<String> get tabList {
    return state.controllerMap.keys.map((e) {
      return e.path;
    }).toList();
  }

  FutureOr<void> _onInit(CodeInitialized event, Emitter<CodeState> emit) async {
    emit(state.copyWith(state: CodeStatus.loading));
    final path = event.file.path;
    final file = File(path);
    final data = "${await file.readAsString()}";
    controller.text = data;
    emit(state.copyWith(state: CodeStatus.success));
  }
}
