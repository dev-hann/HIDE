library code_bloc;

import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:h_ide/model/h_file.dart';

part 'code_event.dart';
part 'code_state.dart';

class CodeBloc extends Bloc<CodeEvent, CodeState> {
  CodeBloc() : super(const CodeState()) {
    on<CodeInitialized>(_onInit);
  }

  QuillController codeController = QuillController.basic();

  FutureOr<void> _onInit(CodeInitialized event, Emitter<CodeState> emit) async {
    emit(state.copyWith(state: CodeStatus.loading));
    final path = event.file.path;
    final file = File(path);
    final data = "${await file.readAsString()}\n";
    final words = data.split(" ").map((e) => Operation.insert(e)).toList();
    final list = Delta.fromOperations(words);
    codeController = QuillController(
      document: Document.fromDelta(list),
      selection: const TextSelection.collapsed(offset: 0),
    );
    emit(state.copyWith(state: CodeStatus.success));
  }
}
