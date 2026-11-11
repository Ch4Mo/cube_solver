import 'package:cube_solver/cube/cube.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('une saisie neuve ne contient que les centres', () {
    final input = CubeInput();
    expect(input.filledCount, 6);
    expect(input.isComplete, isFalse);
    expect(input.validate(), isNull);
    expect(input[Face.F.centerIndex], CubeColor.green);
  });

  test('saisie complète d\'un cube mélangé → valide', () {
    final cube = CubieCube()..applyMoves(Move.parseSequence("R U F' L2 D"));
    final input = CubeInput.fromCube(cube);
    final v = input.validate()!;
    expect(v.isValid, isTrue);
    expect(v.cube, cube);
    expect(v.colorScheme, standardScheme);
  });

  test('effacer garde les centres', () {
    final input = CubeInput.fromCube(CubieCube())..clear();
    expect(input.filledCount, 6);
  });

  test('couleur utilisée plus de 9 fois signalée avant la fin', () {
    final input = CubeInput();
    for (var i = 0; i < 9; i++) {
      if (i != 4) input[Face.F.index * 9 + i] = CubeColor.red;
    }
    input[0] = CubeColor.red;
    input[1] = CubeColor.red;
    expect(input.overusedColors, [CubeColor.red]);
  });

  test('consignes d\'orientation', () {
    final input = CubeInput();
    expect(
      input.orientationHint(Face.F),
      'Centre vert face à vous, centre blanc en haut.',
    );
    expect(
      input.orientationHint(Face.U),
      'Centre blanc face à vous, centre bleu en haut.',
    );
    expect(
      input.orientationHint(Face.D),
      'Centre jaune face à vous, centre vert en haut.',
    );
  });

  test('description des mouvements', () {
    expect(
      describeMove(Move.parse('R'), standardScheme),
      'Tournez la face droite (rouge) d\'un quart de tour dans le sens '
      'horaire.',
    );
    expect(
      describeMove(Move.parse("U'")),
      'Tournez la face haut d\'un quart de tour dans le sens anti-horaire.',
    );
    expect(describeMove(Move.parse('F2')), contains('demi-tour'));
  });
}
