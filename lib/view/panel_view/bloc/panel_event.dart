part of 'panel_bloc.dart';

abstract class PanelEvent extends Equatable {
  const PanelEvent();
}

class PanelEventInited extends PanelEvent {
  @override
  List<Object?> get props => [];
}

class PanelEventOpenFile extends PanelEvent {
  const PanelEventOpenFile(this.file);
  final HFile file;

  @override
  List<Object> get props => [file];
}

class PanelEventCloseFile extends PanelEvent {
  const PanelEventCloseFile(this.file);
  final HFile file;

  @override
  List<Object?> get props => [file];
}

class PanelEventUpdateFile extends PanelEvent {
  const PanelEventUpdateFile(this.file);
  final HFile file;

  @override
  List<Object?> get props => [file];
}
