import 'package:cube_solver/cube/cube.dart';
import 'package:cube_solver/l10n/l10n_scope.dart';
import 'package:cube_solver/main.dart';
import 'package:cube_solver/ui/manual_input_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Page seule, en français.
Widget wrap(Widget child, [AppLanguage language = AppLanguage.fr]) =>
    MaterialApp(
      home: child,
      builder: (context, child) => L10nScope(language: language, child: child!),
    );

/// Écran de téléphone haut, pour que toute la page soit construite.
void tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Strings.current = const StringsFr());

  testWidgets("l'accueil s'affiche", (tester) async {
    await tester.pumpWidget(
      CubeSolverApp(language: LanguageController(AppLanguage.fr)),
    );
    expect(find.text('Saisir les couleurs'), findsOneWidget);
    expect(find.text('Scanner mon cube'), findsOneWidget);
    expect(find.text('Essayer avec un cube mélangé'), findsNothing);
  });

  testWidgets('saisie vide : bouton Résoudre désactivé', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(wrap(const ManualInputPage()));
    expect(find.text('Face 1/6 : avant'), findsOneWidget);
    expect(find.text('48 case(s) restante(s).'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Résoudre'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('toucher une case la colore', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(wrap(const ManualInputPage()));
    await tester.tap(find.bySemanticsLabel('Rouge, 1 sur 9'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Case 1 : vide'));
    await tester.pump();
    expect(find.bySemanticsLabel('Case 1 : Rouge'), findsOneWidget);
    expect(find.text('47 case(s) restante(s).'), findsOneWidget);
  });

  testWidgets('navigation entre les faces', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(wrap(const ManualInputPage()));
    await tester.tap(find.byTooltip('Face suivante'));
    await tester.pump();
    expect(find.text('Face 2/6 : droite'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Face haut'));
    await tester.pump();
    expect(find.text('Face 5/6 : haut'), findsOneWidget);
  });

  testWidgets('pièce manipulée signalée', (tester) async {
    final cube = CubieCube()..applyMoves(Move.parseSequence('R U'));
    final input = CubeInput.fromCube(cube);
    // On tourne le coin URF sur lui-même (rotation de ses 3 couleurs).
    final a = input[8], b = input[9], c = input[20];
    input[8] = c;
    input[9] = a;
    input[20] = b;
    tallScreen(tester);
    await tester.pumpWidget(wrap(ManualInputPage(initial: input)));
    expect(find.textContaining('tourné sur lui-même'), findsOneWidget);
  });

  testWidgets('cube valide → solution affichée', (tester) async {
    tallScreen(tester);
    final cube = CubieCube()..applyMoves(Move.parseSequence("R U R' F2"));
    await tester.pumpWidget(
      wrap(ManualInputPage(initial: CubeInput.fromCube(cube))),
    );
    expect(find.text('Cube valide, prêt à être résolu.'), findsOneWidget);
    await tester.tap(find.text('Résoudre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Solution'), findsOneWidget);

    // Le solveur tourne dans un isolate : on lui laisse le temps réel.
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (find.text('Calcul de la solution…').evaluate().isEmpty) break;
        await tester.pump();
      }
    });
    await tester.pump();
    expect(find.textContaining('Tournez la face'), findsOneWidget);
    expect(find.text('Étape 1 / 4'), findsOneWidget);
  });

  group('Langues', () {
    testWidgets('langue du téléphone non disponible → anglais', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(CubeSolverApp(language: LanguageController()));
      await tester.pump();
      expect(find.text('Scan my cube'), findsOneWidget);
    });

    testWidgets('langue du téléphone espagnole', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(CubeSolverApp(language: LanguageController()));
      await tester.pump();
      expect(find.text('Escanear mi cubo'), findsOneWidget);
    });

    testWidgets("changer de langue depuis l'accueil", (tester) async {
      final language = LanguageController(AppLanguage.fr);
      await tester.pumpWidget(CubeSolverApp(language: language));
      expect(find.text('Scanner mon cube'), findsOneWidget);

      await tester.tap(find.text('FR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('English'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(language.value, AppLanguage.en);
      expect(find.text('Scan my cube'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('saisie en anglais : messages traduits', (tester) async {
      tallScreen(tester);
      final cube = CubieCube()..applyMoves(Move.parseSequence('R U'));
      final input = CubeInput.fromCube(cube);
      final a = input[8], b = input[9], c = input[20];
      input[8] = c;
      input[9] = a;
      input[20] = b;
      await tester.pumpWidget(
        wrap(ManualInputPage(initial: input), AppLanguage.en),
      );
      expect(find.text('Face 1/6: front'), findsOneWidget);
      expect(find.textContaining('twisted in place'), findsOneWidget);
    });

    testWidgets('solution en espagnol', (tester) async {
      tallScreen(tester);
      final cube = CubieCube()..applyMoves(Move.parseSequence('R2'));
      await tester.pumpWidget(
        wrap(
          ManualInputPage(initial: CubeInput.fromCube(cube)),
          AppLanguage.es,
        ),
      );
      expect(find.text('Cubo válido, listo para resolver.'), findsOneWidget);
      await tester.tap(find.text('Resolver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          if (find.text('Calculando la solución…').evaluate().isEmpty) break;
          await tester.pump();
        }
      });
      await tester.pump();
      expect(
        find.text('Gira la cara derecha (rojo) media vuelta.'),
        findsOneWidget,
      );
    });
  });
}
