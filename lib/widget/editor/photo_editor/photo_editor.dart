import 'dart:io';

import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';

class PhotoEditor extends StatelessWidget {
  const PhotoEditor({
    super.key,
    required this.file,
  });

  static const enableExtenxionList = ["png", "jpg", "jpeg"];

  final HFile file;
  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(file.path),
    );
  }
}
