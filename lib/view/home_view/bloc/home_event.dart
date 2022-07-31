part of home_bloc;

abstract class HomeEvent {}

class HomeInitialized extends HomeEvent {
  HomeInitialized(this.windowUseCase);
  final WindowUseCase windowUseCase;
}
