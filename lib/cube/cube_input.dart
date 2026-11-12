import '../l10n/strings.dart';
import 'cubie_cube.dart';
import 'definitions.dart';
import 'moves.dart';
import 'validation.dart';

/// Ordre dans lequel l'utilisateur saisit (ou photographie) les faces :
/// on tourne d'abord le cube autour de l'axe vertical, puis on le bascule.
const List<Face> inputOrder = [Face.F, Face.R, Face.B, Face.L, Face.U, Face.D];

/// Schéma de couleurs le plus courant (« occidental ») : blanc en haut,
/// vert devant.
const Map<Face, CubeColor> standardScheme = {
  Face.U: CubeColor.white,
  Face.R: CubeColor.red,
  Face.F: CubeColor.green,
  Face.D: CubeColor.yellow,
  Face.L: CubeColor.orange,
  Face.B: CubeColor.blue,
};

/// Nom d'une face dans la langue active (« avant », « front »…).
String faceName(Face face) => Strings.current.faceName(face);

/// Face qui doit se trouver en haut de l'image quand on regarde [face]
/// (convention de numérotation, voir `definitions.dart`).
Face topNeighbor(Face face) => switch (face) {
  Face.U => Face.B,
  Face.D => Face.F,
  _ => Face.U,
};

/// Saisie en cours des 54 cases. Une case vaut `null` tant qu'elle n'a pas
/// été renseignée.
class CubeInput {
  CubeInput() : _colors = List<CubeColor?>.filled(54, null) {
    for (final face in Face.values) {
      _colors[face.centerIndex] = standardScheme[face];
    }
  }

  /// Saisie pré-remplie à partir d'un état de cube.
  factory CubeInput.fromCube(
    CubieCube cube, [
    Map<Face, CubeColor> scheme = standardScheme,
  ]) {
    final input = CubeInput();
    final facelets = cube.toFacelets();
    for (var i = 0; i < 54; i++) {
      input._colors[i] = scheme[facelets[i]];
    }
    return input;
  }

  final List<CubeColor?> _colors;

  List<CubeColor?> get colors => List.unmodifiable(_colors);

  CubeColor? operator [](int index) => _colors[index];

  void operator []=(int index, CubeColor? color) => _colors[index] = color;

  /// Les 9 cases d'une face.
  List<CubeColor?> face(Face face) =>
      _colors.sublist(face.index * 9, face.index * 9 + 9);

  /// Efface tout sauf les centres.
  void clear() {
    for (var i = 0; i < 54; i++) {
      if (i % 9 != 4) _colors[i] = null;
    }
  }

  int get filledCount => _colors.where((c) => c != null).length;

  bool get isComplete => filledCount == 54;

  bool isFaceComplete(Face face) => this.face(face).every((c) => c != null);

  /// Nombre de cases de chaque couleur.
  Map<CubeColor, int> get colorCounts {
    final counts = {for (final c in CubeColor.values) c: 0};
    for (final c in _colors) {
      if (c != null) counts[c] = counts[c]! + 1;
    }
    return counts;
  }

  /// Consigne pour tenir le cube correctement lors de la saisie d'une face.
  String orientationHint(Face face) {
    final center = _colors[face.centerIndex];
    final top = _colors[topNeighbor(face).centerIndex];
    if (center == null || top == null) {
      return Strings.current.faceLabel(face);
    }
    return Strings.current.orientationHint(center, top);
  }

  /// Valide la saisie, ou retourne `null` tant qu'elle est incomplète
  /// (voir [overusedColors] pour les erreurs visibles avant la fin).
  ValidationResult? validate() {
    if (!isComplete) return null;
    return validateColors(_colors.cast<CubeColor>());
  }

  /// Couleurs utilisées plus de 9 fois (erreur visible avant la fin).
  List<CubeColor> get overusedColors => [
    for (final e in colorCounts.entries)
      if (e.value > 9) e.key,
  ];
}

/// Consigne pour photographier une face pendant le scan (schéma standard :
/// blanc en haut, vert devant). Suit l'ordre de [inputOrder].
String scanInstruction(Face face) => Strings.current.scanInstruction(face);

/// Explication d'un mouvement dans la langue active, par ex. « Tournez la face droite
/// (rouge) d'un quart de tour dans le sens horaire ».
///
/// Le sens horaire s'entend en regardant la face concernée.
String describeMove(Move move, [Map<Face, CubeColor>? scheme]) =>
    Strings.current.describeMove(move.face, move.turns, scheme?[move.face]);
