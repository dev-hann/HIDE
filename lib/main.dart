import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/data/data_base/h_box.dart';
import 'package:h_ide/util/window.dart';
import 'package:h_ide/view/finder_view/bloc/finder_bloc.dart';
import 'package:h_ide/view/home_view/bloc/home_bloc.dart';
import 'package:h_ide/view/home_view/home_view.dart';
import 'package:h_ide/view/panel_view/bloc/panel_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HBox.init();
  await Window.instance.init();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Hack",
        scaffoldBackgroundColor: HColor.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 13,
          ),
        ).apply(
          displayColor: HColor.white,
          bodyColor: HColor.white,
        ),
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => HomeBloc(),
          ),
          BlocProvider(
            create: (_) => FinderBloc(),
          ),
          BlocProvider(
            create: (_) => PanelBloc(),
          ),
        ],
        child: const HomeView(),
      ),
    ),
  );
}
