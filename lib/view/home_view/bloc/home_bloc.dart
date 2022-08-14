library home_bloc;

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:h_ide/enum/lsp_response_type.dart';
import 'package:h_ide/model/lsp/response.dart';
import 'package:h_ide/repo/lsp/lsp_impl.dart';
import 'package:h_ide/use_case/lsp/lsp_use_case.dart';
import 'package:h_ide/use_case/window/window_use_case.dart';

part 'home_state.dart';
part 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeInitialized>(_onInit);
    on<HomeAnalysisdRoots>(_onAnalysisRoots);
  }
  late WindowUseCase windowUseCase;
  final LSPUseCase lspUseCase = LSPUseCase(LSPImpl());
  final Completer _loading = Completer();
  FutureOr<void> _onInit(HomeInitialized event, Emitter<HomeState> emit) async {
    await lspUseCase.init();
    lspUseCase.stream().listen((event) {
      if(event.type==LSPResponseType.response){
        final e = event as Response;
        print(e.result);
      }else{
        final e = event as Notification;
        if(e.event == "completion.results"){
          final text =e.params["results"].toString(); 
          print(text.substring(0,10000));
        }
        print(e.event);
      }
    });
    windowUseCase = event.windowUseCase;
    _loading.complete();
  }

  FutureOr<void> _onAnalysisRoots(
      HomeAnalysisdRoots event, Emitter<HomeState> emit)async {
    await _loading.future;
    final preRoot = state.rootPath;
    final newRoot = event.filePath;
    if (preRoot == newRoot) {
      return null;
    }
    final Directory file = Directory(newRoot);
    final fileList = file.listSync(recursive: true).where((e) {
      final path = e.path;
      return path.split("/").last.split(".").last == "dart";
    }).map((e) {
      return e.path;
    }).toList();
    lspUseCase.setAnalysisRoots(fileList);
  }
}
