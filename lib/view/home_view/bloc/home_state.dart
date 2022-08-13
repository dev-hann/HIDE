part of home_bloc;

class HomeState extends Equatable {
  const HomeState({
    this.rootPath = "",
  });
  final String rootPath;

  @override
  List<Object?> get props => [rootPath];

  HomeState copyWith({
    String? rootPath,
  }) {
    return HomeState(
      rootPath: rootPath ?? this.rootPath,
    );
  }
}
