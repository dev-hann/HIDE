library code_bloc;

import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/model/h_file.dart';

part 'code_event.dart';
part 'code_state.dart';

class CodeBloc extends Bloc<CodeEvent, CodeState> {
  CodeBloc() : super(const CodeState()) {
    on<CodeInitialized>(_onInit);
  }

  FutureOr<void> _onInit(CodeInitialized event, Emitter<CodeState> emit) async {
    emit(state.copyWith(state: CodeStatus.loading));
    final path = event.file.path;
    final file = File(path);
    final data = "${await file.readAsString()}";
    emit(state.copyWith(state: CodeStatus.success));
  }
}
