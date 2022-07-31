import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/repo/window/window_impl.dart';
import 'package:h_ide/use_case/window/window_use_case.dart';
import 'package:h_ide/view/home_view/bloc/home_bloc.dart';
import 'package:h_ide/view/home_view/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final WindowUseCase useCase = WindowUseCase(WindowImpl());
  await useCase.init();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => HomeBloc()..add(HomeInitialized(useCase)),
        child: const HomeView(),
      ),
    ),
  );
}
