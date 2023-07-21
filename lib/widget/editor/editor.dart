import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/panel_view/bloc/panel_bloc.dart';
import 'package:h_ide/widget/editor/code_editor/code_editor.dart';
import 'package:h_ide/widget/editor/photo_editor/photo_editor.dart';

class HEditor extends StatefulWidget {
  const HEditor({
    super.key,
    required this.file,
  });
  final HFile file;

  @override
  State<HEditor> createState() => _HEditorState();
}

class _HEditorState extends State<HEditor> with AutomaticKeepAliveClientMixin {
  PanelBloc get bloc => BlocProvider.of<PanelBloc>(context);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final file = widget.file;
    final extension = file.extension.toLowerCase();
    if (PhotoEditor.enableExtenxionList.contains(extension)) {
      return PhotoEditor(file: file);
    }
    return CodeEditor(
      file: widget.file,
      onChanged: (_) {
        bloc.add(
          PanelEventUpdateFile(
            file.copyWith(isModified: true),
          ),
        );
      },
      onTapSaved: (value) async {
        file.write(value);
        bloc.add(
          PanelEventUpdateFile(
            file.copyWith(isModified: false),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
