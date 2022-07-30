import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/home_view/bloc/home_bloc.dart';
import 'package:h_ide/view/home_view/home_view.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => HomeBloc(),
        child: const HomeView(),
      ),
    ),
  );
  doWhenWindowReady(() {
    appWindow.alignment = Alignment.center;
    appWindow.title = "Hello";
    appWindow.maximize();
    appWindow.show();
  });
}
