import 'package:material_ui/material_ui.dart';

import '../cube/cube.dart';

/// Couleur d'affichage d'un autocollant (`null` = case non renseignée).
Color displayColor(CubeColor? color) => switch (color) {
  CubeColor.white => const Color(0xFFF5F5F5),
  CubeColor.yellow => const Color(0xFFFDD835),
  CubeColor.green => const Color(0xFF2E7D32),
  CubeColor.blue => const Color(0xFF1565C0),
  CubeColor.red => const Color(0xFFC62828),
  CubeColor.orange => const Color(0xFFEF6C00),
  null => const Color(0xFF9E9E9E),
};

/// Une face de 3×3 cases.
class FaceGrid extends StatelessWidget {
  const FaceGrid({
    super.key,
    required this.colors,
    required this.size,
    this.highlighted = const {},
    this.onTap,
  });

  /// Les 9 couleurs, ligne par ligne.
  final List<CubeColor?> colors;
  final double size;

  /// Cases (0..8) à entourer en rouge.
  final Set<int> highlighted;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    final cell = size / 3;
    final gap = (cell * 0.06).clamp(1.0, 4.0);
    return SizedBox.square(
      dimension: size,
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            Row(
              children: [
                for (var col = 0; col < 3; col++)
                  _cell(context, row * 3 + col, cell, gap),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int k, double cell, double gap) {
    final color = colors[k];
    final isHighlighted = highlighted.contains(k);
    final box = Container(
      width: cell - 2 * gap,
      height: cell - 2 * gap,
      margin: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: displayColor(color),
        borderRadius: BorderRadius.circular(cell * 0.12),
        border: Border.all(
          color: isHighlighted ? Colors.redAccent : Colors.black54,
          width: isHighlighted ? (cell * 0.08).clamp(2.0, 4.0) : 0.5,
        ),
      ),
      child: color == null && cell > 30
          ? Center(
              child: Text(
                '?',
                style: TextStyle(color: Colors.white, fontSize: cell * 0.35),
              ),
            )
          : null,
    );
    if (onTap == null) return box;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Case ${k + 1} : ${color?.label ?? 'vide'}',
      child: GestureDetector(onTap: () => onTap!(k), child: box),
    );
  }
}

/// Patron (vue « dépliée ») du cube, qui s'adapte à la largeur disponible.
class CubeNetView extends StatelessWidget {
  const CubeNetView({
    super.key,
    required this.colors,
    this.highlighted = const {},
    this.selectedFace,
    this.onFaceTap,
    this.maxCellSize = 24,
  });

  /// Les 54 couleurs.
  final List<CubeColor?> colors;

  /// Cases (0..53) à entourer en rouge.
  final Set<int> highlighted;
  final Face? selectedFace;
  final void Function(Face face)? onFaceTap;
  final double maxCellSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth / 12.6).clamp(8.0, maxCellSize);
        final faceSize = cell * 3;
        Widget face(Face f) {
          final selected = f == selectedFace;
          final grid = Container(
            margin: EdgeInsets.all(cell * 0.05),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: FaceGrid(
              colors: colors.sublist(f.index * 9, f.index * 9 + 9),
              size: faceSize,
              highlighted: {
                for (final i in highlighted)
                  if (i ~/ 9 == f.index) i % 9,
              },
            ),
          );
          if (onFaceTap == null) return grid;
          return Semantics(
            button: true,
            label: 'Face ${faceName(f)}',
            child: GestureDetector(onTap: () => onFaceTap!(f), child: grid),
          );
        }

        final empty = SizedBox.square(dimension: faceSize + cell * 0.1 + 4);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [empty, face(Face.U), empty, empty],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                face(Face.L),
                face(Face.F),
                face(Face.R),
                face(Face.B),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [empty, face(Face.D), empty, empty],
            ),
          ],
        );
      },
    );
  }
}
