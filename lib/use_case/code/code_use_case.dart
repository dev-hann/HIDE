import 'package:h_ide/model/syntax.dart';
import 'package:h_ide/repo/code/code_repo.dart';

class CodeUseCase {
  CodeUseCase(this.repo);
  final CodeRepo repo;

  Map<String, Syntax> loadSyntax() {
    return {
      "dart": Syntax(
        "dart",
        {
          "brightOrange": 0xFFfe8019,
          "class": "brightOrange",
          "extends": "brightOrange"
        },
      ),
    };
  }
}
