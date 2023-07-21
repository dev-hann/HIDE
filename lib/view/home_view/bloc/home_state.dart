part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    this.leftPanelSize = 0.2,
    this.bottomPanelSize = 0.3,
  });

  final double leftPanelSize;
  final double bottomPanelSize;

  @override
  List<Object> get props => [
        leftPanelSize,
        bottomPanelSize,
      ];

  HomeState copyWith({
    double? leftPanelSize,
    double? bottomPanelSize,
  }) {
    return HomeState(
      leftPanelSize: leftPanelSize ?? this.leftPanelSize,
      bottomPanelSize: bottomPanelSize ?? this.bottomPanelSize,
    );
  }
}
