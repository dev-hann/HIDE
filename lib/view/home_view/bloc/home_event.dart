part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
}

class HomeEventUpdateLeftPanelSize extends HomeEvent {
  const HomeEventUpdateLeftPanelSize(this.size);
  final double size;

  @override
  List<Object?> get props => [size];
}

class HomeEventUpdateBottomPanelSize extends HomeEvent {
  const HomeEventUpdateBottomPanelSize(this.size);
  final double size;

  @override
  List<Object?> get props => [size];
}
