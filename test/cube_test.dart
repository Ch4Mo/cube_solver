import 'dart:math';

import 'package:cube_solver/cube/cube.dart';
import 'package:cube_solver/cube/cubie_cube.dart' show basicMoves;
import 'package:flutter_test/flutter_test.dart';

const solvedString = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';

String toStr(List<Face> f) => f.map((x) => x.letter).join();

CubieCube scrambled(String moves) =>
    CubieCube()..applyMoves(Move.parseSequence(moves));

void main() {
  group('Mouvements', () {
    test('notation', () {
      expect(Move.formatSequence(Move.parseSequence("R  U2 F'")), "R U2 F'");
      expect(() => Move.parse('X'), throwsFormatException);
      for (var i = 0; i < 18; i++) {
        expect(Move.fromIndex(i).index, i);
        expect(Move.parse(Move.fromIndex(i).notation), Move.fromIndex(i));
      }
    });

    test('chaque face tournée 4 fois revient à l\'état résolu', () {
      for (final face in Face.values) {
        final c = CubieCube();
        for (var i = 0; i < 4; i++) {
          c.multiply(basicMoves[face.index]);
        }
        expect(c.isSolved, isTrue, reason: face.letter);
      }
    });

    test("(R U R' U') × 6 = identité", () {
      final c = CubieCube();
      for (var i = 0; i < 6; i++) {
        c.applyMoves(Move.parseSequence("R U R' U'"));
      }
      expect(c.isSolved, isTrue);
    });

    test('un mouvement suivi de son inverse = identité', () {
      for (var i = 0; i < 18; i++) {
        final m = Move.fromIndex(i);
        expect((CubieCube()..applyMoves([m, m.inverse])).isSolved, isTrue);
      }
    });

    test('R déplace la colonne de droite de F vers U', () {
      final f = toStr(scrambled('R').toFacelets());
      // U3, U6, U9 (index 2, 5, 8) viennent de la face F.
      expect(f[2] + f[5] + f[8], 'FFF');
      // La face R reste entièrement R.
      expect(f.substring(9, 18), 'RRRRRRRRR');
      // B reçoit l'ancienne colonne U.
      expect(f[45] + f[48] + f[51], 'UUU');
    });

    test('superflip connu (Kociemba)', () {
      final c = scrambled("U R2 F B R B2 R U2 L B2 R U' D' R2 F R' L B2 U2 F2");
      expect(
        toStr(c.toFacelets()),
        'UBULURUFURURFRBRDRFUFLFRFDFDFDLDRDBDLULBLFLDLBUBRBLBDB',
      );
    });
  });

  group('Coordonnées', () {
    test('lecture / écriture cohérentes', () {
      final c = CubieCube();
      for (final v in [0, 1, 1000, 2186]) {
        c.twist = v;
        expect(c.twist, v);
        expect(c.cornerTwistSum, 0);
      }
      for (final v in [0, 1, 1000, 2047]) {
        c.flip = v;
        expect(c.flip, v);
        expect(c.edgeFlipSum, 0);
      }
      for (final v in [0, 17, 300, 494]) {
        c.slice = v;
        expect(c.slice, v);
      }
      for (final v in [0, 1, 12345, 40319]) {
        c.cornerPerm = v;
        expect(c.cornerPerm, v);
      }
    });
  });

  group('Validation', () {
    test('cube résolu valide', () {
      final v = validateFaceletString(solvedString);
      expect(v.isValid, isTrue);
      expect(v.cube!.isSolved, isTrue);
    });

    test('aller-retour facettes ↔ pièces sur des cubes aléatoires', () {
      final rnd = Random(42);
      for (var i = 0; i < 200; i++) {
        final c = CubieCube.random(rnd);
        final v = validateFacelets(c.toFacelets());
        expect(v.isValid, isTrue, reason: v.errors.join());
        expect(v.cube, c);
      }
    });

    test('couleurs : le schéma est déduit des centres', () {
      // Schéma standard : U blanc, R rouge, F vert, D jaune, L orange, B bleu.
      const scheme = {
        Face.U: CubeColor.white,
        Face.R: CubeColor.red,
        Face.F: CubeColor.green,
        Face.D: CubeColor.yellow,
        Face.L: CubeColor.orange,
        Face.B: CubeColor.blue,
      };
      final c = scrambled("R U R' U' F2 D L'");
      final colors = [for (final f in c.toFacelets()) scheme[f]!];
      final v = validateColors(colors);
      expect(v.isValid, isTrue);
      expect(v.cube, c);
      expect(v.colorScheme, scheme);
    });

    test('mauvais nombre de couleurs', () {
      final s = 'R${solvedString.substring(1)}';
      final v = validateFaceletString(s);
      expect(v.errors.single.type, CubeErrorType.wrongColorCount);
    });

    test('coin tourné sur lui-même', () {
      final c = scrambled("R U F'")
        ..co[0] = (scrambled("R U F'").co[0] + 1) % 3;
      final v = validateFacelets(c.toFacelets());
      expect(v.errors.map((e) => e.type), [CubeErrorType.twistedCorner]);
      expect(v.errors.single.isPhysicalTampering, isTrue);
    });

    test('arête retournée', () {
      final c = scrambled('L D2 B')..eo[5] ^= 1;
      final v = validateFacelets(c.toFacelets());
      expect(v.errors.map((e) => e.type), [CubeErrorType.flippedEdge]);
    });

    test('deux arêtes échangées', () {
      final c = scrambled('F R');
      final t = c.ep[0];
      c.ep[0] = c.ep[1];
      c.ep[1] = t;
      final v = validateFacelets(c.toFacelets());
      expect(v.errors.map((e) => e.type), [CubeErrorType.swappedPieces]);
    });

    test('deux autocollants d\'un coin échangés (couleurs impossibles)', () {
      // Échanger U9 et F3 sur le coin URF donne un coin « miroir ».
      final f = solvedString.split('');
      f[8] = 'F';
      f[20] = 'U';
      final v = validateFaceletString(f.join());
      expect(v.isValid, isFalse);
      expect(v.errors.first.type, CubeErrorType.invalidCorner);
    });

    test('centres identiques', () {
      final f = solvedString.split('');
      // Échange d'un centre et d'une case : comptes toujours bons.
      f[4] = 'R';
      f[9] = 'U';
      final v = validateFaceletString(f.join());
      expect(v.errors.single.type, CubeErrorType.duplicateCenter);
    });
  });

  group('Solveur', () {
    final solver = Solver.instance;

    void expectSolves(CubieCube c, {int maxLength = 23}) {
      final solution = solver.solveCubie(c);
      final check = c.copy()..applyMoves(solution);
      expect(
        check.isSolved,
        isTrue,
        reason: 'solution : ${Move.formatSequence(solution)}',
      );
      expect(solution.length, lessThanOrEqualTo(maxLength));
    }

    test('cube résolu → solution vide', () {
      expect(solver.solveFacelets(solvedString), isEmpty);
    });

    test('mélanges courts', () {
      expectSolves(scrambled('R'), maxLength: 1);
      expectSolves(scrambled("R U R' U'"), maxLength: 4);
      expectSolves(scrambled('F2 B2 U D'), maxLength: 4);
    });

    test('superflip', () {
      expectSolves(
        scrambled("U R2 F B R B2 R U2 L B2 R U' D' R2 F R' L B2 U2 F2"),
      );
    });

    test('50 cubes aléatoires', () {
      final rnd = Random(7);
      final lengths = <int>[];
      final sw = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        final c = CubieCube.random(rnd);
        final solution = solver.solveCubie(c);
        expect((c.copy()..applyMoves(solution)).isSolved, isTrue);
        lengths.add(solution.length);
      }
      // ignore: avoid_print
      print(
        'Longueur moyenne : '
        '${(lengths.reduce((a, b) => a + b) / lengths.length).toStringAsFixed(1)}'
        ', max : ${lengths.reduce(max)}, temps : ${sw.elapsedMilliseconds} ms',
      );
      expect(lengths.reduce(max), lessThanOrEqualTo(24));
    });

    test('cube impossible → exception explicite', () {
      final c = CubieCube()..co[0] = 1;
      expect(
        () => solver.solveFacelets(toStr(c.toFacelets())),
        throwsA(isA<UnsolvableCubeException>()),
      );
    });
  });

  group('Suivi de la résolution', () {
    final start = scrambled("R U2 F' L D B2");
    final solution = Solver.instance.solveCubie(start);

    List<Face> faceAfter(int step, Face face) {
      final f = expectedFacelets(start, solution, step);
      return f.sublist(face.index * 9, face.index * 9 + 9);
    }

    test('face correcte', () {
      final r = checkFace(start, solution, 2, Face.F, faceAfter(2, Face.F));
      expect(r.matches, isTrue);
    });

    test('mouvement oublié détecté', () {
      final r = checkFace(start, solution, 3, Face.U, faceAfter(2, Face.U));
      expect(r.matches, isFalse);
      expect(r.matchingStep, 2);
      expect(r.message, contains('manquer 1'));
    });

    test('pièce bougée détectée', () {
      final observed = faceAfter(1, Face.F);
      observed[0] = observed[0] == Face.U ? Face.D : Face.U;
      final r = checkFace(start, solution, 1, Face.F, observed);
      expect(r.matches, isFalse);
      expect(r.matchingStep, isNull);
      expect(r.mismatchedFacelets, [0]);
    });
  });
}
