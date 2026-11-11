import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../cube/cube.dart';
import 'cube_widgets.dart';

/// Point 3D. Repère : x vers la droite, y vers le haut, z vers l'observateur.
/// Le cube occupe [0, 3]³ ; la face avant (F) est en z = 3, la droite (R) en
/// x = 3 et le haut (U) en y = 3.
typedef P3 = (double, double, double);

const double _cos30 = 0.8660254;

/// Projection isométrique (vue de face, de droite et de dessus).
Offset project(P3 p) =>
    Offset((p.$1 - p.$3) * _cos30, (p.$1 + p.$3) * 0.5 - p.$2);

/// Les 4 coins d'une case visible (faces U, F et R uniquement).
List<P3> faceletQuad(Face face, int row, int col) {
  final r = row.toDouble(), c = col.toDouble();
  return switch (face) {
    Face.F => [
      (c, 3 - r, 3),
      (c + 1, 3 - r, 3),
      (c + 1, 2 - r, 3),
      (c, 2 - r, 3),
    ],
    Face.R => [
      (3, 3 - r, 3 - c),
      (3, 3 - r, 2 - c),
      (3, 2 - r, 2 - c),
      (3, 2 - r, 3 - c),
    ],
    Face.U => [(c, 3, r), (c + 1, 3, r), (c + 1, 3, r + 1), (c, 3, r + 1)],
    _ => throw ArgumentError('Face non visible : $face'),
  };
}

/// Tracé de la flèche indiquant un mouvement (sens horaire de base ; la
/// liste est inversée pour un quart de tour anti-horaire).
List<P3> movePath(Face face) => switch (face) {
  Face.R => [(2.5, 0.4, 3), (2.5, 3, 3), (2.5, 3, 0.4)],
  Face.L => [(0.5, 3, 0.4), (0.5, 3, 3), (0.5, 0.4, 3)],
  Face.U => [(3, 2.5, 0.4), (3, 2.5, 3), (0.4, 2.5, 3)],
  Face.D => [(0.4, 0.5, 3), (3, 0.5, 3), (3, 0.5, 0.4)],
  Face.B => [(3, 0.4, 0.5), (3, 3, 0.5), (0.4, 3, 0.5)],
  Face.F => [
    for (var deg = 20; deg <= 320; deg += 10)
      (1.5 + 1.05 * sin(deg * pi / 180), 1.5 + 1.05 * cos(deg * pi / 180), 3.0),
  ],
};

/// Cube en perspective isométrique, avec éventuellement la flèche du
/// prochain mouvement.
class Cube3DView extends StatelessWidget {
  const Cube3DView({
    super.key,
    required this.colors,
    this.move,
    this.size = 240,
  });

  /// Les 54 couleurs (ordre URFDLB).
  final List<CubeColor> colors;
  final Move? move;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: move == null
          ? 'Vue 3D du cube'
          : 'Vue 3D du cube, mouvement ${move!.notation}',
      child: CustomPaint(
        size: Size.square(size),
        painter: _Cube3DPainter(
          colors,
          move,
          Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _Cube3DPainter extends CustomPainter {
  _Cube3DPainter(this.colors, this.move, this.arrowColor);

  final List<CubeColor> colors;
  final Move? move;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Le cube projeté tient dans [-3·cos30, 3·cos30] × [-3, 3].
    final scale = min(size.width / (6 * _cos30), size.height / 6) * 0.92;
    final center = size.center(Offset.zero);
    Offset toScreen(P3 p) => center + project(p) * scale;

    final edge = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, scale * 0.06)
      ..strokeJoin = StrokeJoin.round;

    for (final face in [Face.U, Face.F, Face.R]) {
      // Ombrage léger pour donner du relief.
      final shade = switch (face) {
        Face.U => 1.0,
        Face.F => 0.92,
        _ => 0.8,
      };
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          final quad = faceletQuad(face, row, col).map(toScreen).toList();
          final path = Path()..addPolygon(quad, true);
          final base = displayColor(colors[face.index * 9 + row * 3 + col]);
          canvas.drawPath(
            path,
            Paint()..color = Color.lerp(Colors.black, base, shade)!,
          );
          canvas.drawPath(path, edge);
        }
      }
    }

    final m = move;
    if (m != null) _drawArrow(canvas, m, toScreen, scale);
  }

  void _drawArrow(
    Canvas canvas,
    Move m,
    Offset Function(P3) toScreen,
    double scale,
  ) {
    var points = movePath(m.face).map(toScreen).toList();
    if (m.turns == 3) points = points.reversed.toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final width = max(3.0, scale * 0.16);
    // Contour clair pour rester lisible sur toutes les couleurs.
    final halo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tip = points.last;
    final dir = tip - points[points.length - 2];
    final unit = dir / dir.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final head = width * 2.6;
    final headPath = Path()
      ..moveTo(tip.dx + unit.dx * head * 0.4, tip.dy + unit.dy * head * 0.4)
      ..lineTo(
        tip.dx - unit.dx * head + normal.dx * head * 0.75,
        tip.dy - unit.dy * head + normal.dy * head * 0.75,
      )
      ..lineTo(
        tip.dx - unit.dx * head - normal.dx * head * 0.75,
        tip.dy - unit.dy * head - normal.dy * head * 0.75,
      )
      ..close();

    canvas.drawPath(path, halo);
    canvas.drawPath(
      headPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, line);
    canvas.drawPath(headPath, Paint()..color = Colors.black);

    if (m.turns == 2) {
      final tp = TextPainter(
        text: TextSpan(
          text: '×2',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: scale * 0.55,
            shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final mid = points[points.length ~/ 2];
      tp.paint(canvas, mid + normal * (width * 2) - Offset(0, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_Cube3DPainter old) =>
      old.move != move || old.colors != colors || old.arrowColor != arrowColor;
}
