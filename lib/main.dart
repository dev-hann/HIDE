import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/data/data_base/h_box.dart';
import 'package:h_ide/repo/window/window_impl.dart';
import 'package:h_ide/use_case/window/window_use_case.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';
import 'package:h_ide/view/home_view/bloc/home_bloc.dart';
import 'package:h_ide/view/home_view/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HBox.init();
  final WindowUseCase useCase = WindowUseCase(WindowImpl());
  await useCase.init();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(black),
        textTheme: GoogleFonts.robotoMonoTextTheme().apply(
          displayColor: const Color(white),
          bodyColor: const Color(white),
        ),
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => HomeBloc()..add(HomeInitialized(useCase)),
          ),
          BlocProvider(
            create: (_) => FinderBloc()..add(FinderInitialized()),
          ),
          BlocProvider(
            create: (_) => CodeBloc()..add(CodeInitialized()),
          ),
        ],
        child: const HomeView(),
      ),
    ),
  );
}

