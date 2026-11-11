import 'package:cube_solver/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("l'écran de démo s'affiche", (tester) async {
    await tester.pumpWidget(const CubeSolverApp());
    expect(find.text('Mélanger'), findsOneWidget);
    expect(find.text('Résoudre'), findsOneWidget);
  });
}
