import 'dart:math';

import 'package:cube_solver/cube/cube.dart';
import 'package:cube_solver/ui/cube_3d.dart';
import 'package:cube_solver/vision/color_classifier.dart';
import 'package:cube_solver/vision/sampler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Couleurs réelles typiques d'autocollants (différentes des prototypes).
const realColors = {
  CubeColor.white: Rgb(220, 222, 215),
  CubeColor.yellow: Rgb(225, 215, 40),
  CubeColor.green: Rgb(0, 155, 72),
  CubeColor.blue: Rgb(0, 70, 173),
  CubeColor.red: Rgb(183, 18, 40),
  CubeColor.orange: Rgb(255, 100, 0),
};

/// Simule une photo : luminosité par face, teinte de l'éclairage et bruit.
Rgb shoot(
  CubeColor c,
  Random rnd, {
  double light = 1,
  double warm = 0,
  int noise = 10,
}) {
  final base = realColors[c]!;
  int ch(int v, double k) =>
      (v * light * k + rnd.nextInt(2 * noise + 1) - noise).round().clamp(
        0,
        255,
      );
  return Rgb(ch(base.r, 1 + warm), ch(base.g, 1), ch(base.b, 1 - warm));
}

List<CubeColor> colorsOf(CubieCube cube) => [
  for (final f in cube.toFacelets()) standardScheme[f]!,
];

void main() {
  group('Conversion Lab', () {
    test('blanc, noir et rouge pur', () {
      final white = const Rgb(255, 255, 255).toLab();
      expect(white.l, closeTo(100, 0.5));
      expect(white.chroma, lessThan(1));
      expect(const Rgb(0, 0, 0).toLab().l, closeTo(0, 0.5));
      final red = const Rgb(255, 0, 0).toLab();
      expect(red.l, closeTo(53.2, 0.5));
      expect(red.a, closeTo(80.1, 0.5));
    });
  });

  group('Classification du cube complet', () {
    test('les centres sont nommés correctement', () {
      final centers = [
        for (final f in Face.values) realColors[standardScheme[f]!]!.toLab(),
      ];
      final names = nameCenters(centers);
      for (final f in Face.values) {
        expect(names[f.index], standardScheme[f]);
      }
    });

    test('éclairage neutre et bruit', () {
      final rnd = Random(1);
      for (var n = 0; n < 30; n++) {
        final truth = colorsOf(CubieCube.random(rnd));
        final samples = [for (final c in truth) shoot(c, rnd)];
        expect(classifyCube(samples).colors, truth);
      }
    });

    test('luminosité différente sur chaque face', () {
      final rnd = Random(2);
      for (var n = 0; n < 30; n++) {
        final truth = colorsOf(CubieCube.random(rnd));
        final lights = [
          for (var f = 0; f < 6; f++) 0.65 + rnd.nextDouble() * 0.45,
        ];
        final samples = [
          for (var i = 0; i < 54; i++)
            shoot(truth[i], rnd, light: lights[i ~/ 9]),
        ];
        expect(classifyCube(samples).colors, truth);
      }
    });

    test('lumière chaude (ampoule)', () {
      final rnd = Random(3);
      for (var n = 0; n < 30; n++) {
        final truth = colorsOf(CubieCube.random(rnd));
        final samples = [
          for (final c in truth) shoot(c, rnd, light: 0.85, warm: 0.12),
        ];
        expect(classifyCube(samples).colors, truth);
      }
    });

    test('toujours 9 cases par couleur, même avec beaucoup de bruit', () {
      final rnd = Random(4);
      final truth = colorsOf(CubieCube.random(rnd));
      final samples = [for (final c in truth) shoot(c, rnd, noise: 60)];
      final result = classifyCube(samples);
      for (final c in CubeColor.values) {
        expect(result.colors.where((x) => x == c).length, 9);
      }
    });

    test('schéma de couleurs non standard (centres déduits)', () {
      // Cube japonais : bleu opposé au blanc. Peu importe : les centres
      // sont nommés d'après leur couleur mesurée.
      const scheme = {
        Face.U: CubeColor.white,
        Face.F: CubeColor.blue,
        Face.D: CubeColor.green,
        Face.R: CubeColor.red,
        Face.L: CubeColor.orange,
        Face.B: CubeColor.yellow,
      };
      final rnd = Random(5);
      final cube = CubieCube.random(rnd);
      final truth = [for (final f in cube.toFacelets()) scheme[f]!];
      final result = classifyCube([for (final c in truth) shoot(c, rnd)]);
      expect(result.colors, truth);
      expect(validateColors(result.colors).cube, cube);
    });
  });

  group('Classification d\'une face', () {
    test('avec les références du scan', () {
      final rnd = Random(6);
      final refs = {
        for (final c in CubeColor.values)
          c: shoot(c, rnd, light: 0.8, warm: 0.1, noise: 0).toLab(),
      };
      final truth = [
        for (var i = 0; i < 9; i++) CubeColor.values[rnd.nextInt(6)],
      ];
      final samples = [
        for (final c in truth) shoot(c, rnd, light: 0.8, warm: 0.1),
      ];
      expect(classifyFace(samples, refs), truth);
    });
  });

  group('Échantillonnage d\'une photo', () {
    test('grille 3×3 au centre d\'une image portrait', () {
      // Image 600×900 : fond gris, cube de 420 px (0,7 × 600) au centre.
      final image = img.Image(width: 600, height: 900);
      img.fill(image, color: img.ColorRgb8(90, 90, 90));
      const side = 420, left = 90, top = 240, cell = side ~/ 3;
      final truth = [
        CubeColor.red,
        CubeColor.white,
        CubeColor.blue,
        CubeColor.green,
        CubeColor.yellow,
        CubeColor.orange,
        CubeColor.white,
        CubeColor.red,
        CubeColor.green,
      ];
      for (var k = 0; k < 9; k++) {
        final c = realColors[truth[k]]!;
        final x = left + (k % 3) * cell, y = top + (k ~/ 3) * cell;
        // Autocollant avec une bordure noire de 8 px.
        img.fillRect(
          image,
          x1: x,
          y1: y,
          x2: x + cell - 1,
          y2: y + cell - 1,
          color: img.ColorRgb8(10, 10, 10),
        );
        img.fillRect(
          image,
          x1: x + 8,
          y1: y + 8,
          x2: x + cell - 9,
          y2: y + cell - 9,
          color: img.ColorRgb8(c.r, c.g, c.b),
        );
      }
      // Un reflet blanc sur une case : la médiane doit l'ignorer.
      img.fillCircle(
        image,
        x: left + cell ~/ 2,
        y: top + cell ~/ 2,
        radius: 10,
        color: img.ColorRgb8(255, 255, 255),
      );

      final samples = sampleGrid(image);
      expect(samples.length, 9);
      for (var k = 0; k < 9; k++) {
        final expected = realColors[truth[k]]!;
        expect(samples[k].r, closeTo(expected.r, 2), reason: 'case $k');
        expect(samples[k].g, closeTo(expected.g, 2), reason: 'case $k');
        expect(samples[k].b, closeTo(expected.b, 2), reason: 'case $k');
      }

      // Bout en bout : encodage JPEG puis décodage comme une vraie photo.
      final jpeg = img.encodeJpg(image, quality: 90);
      final fromJpeg = sampleFacePhoto(SampleRequest(jpeg));
      expect(classifyFace(fromJpeg), truth);
    });
  });

  group('Vue 3D', () {
    test('face avant à gauche, face droite à droite, dessus en haut', () {
      Offset centerOf(Face f) {
        final q = faceletQuad(f, 1, 1).map(project).toList();
        return q.reduce((a, b) => a + b) / 4;
      }

      expect(centerOf(Face.F).dx, lessThan(0));
      expect(centerOf(Face.R).dx, greaterThan(0));
      expect(centerOf(Face.U).dy, lessThan(centerOf(Face.F).dy));
    });

    test('flèche R vers le haut sur la face avant', () {
      final path = movePath(Face.R).map(project).toList();
      expect(path[1].dy, lessThan(path[0].dy)); // monte
    });

    test('flèche U vers la gauche sur la face avant', () {
      final path = movePath(Face.U).map(project).toList();
      expect(path.last.dx, lessThan(path[1].dx));
    });
  });
}
