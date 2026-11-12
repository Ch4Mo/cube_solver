/// Définitions de base du cube 3×3.
///
/// Conventions (identiques à celles de l'algorithme de Kociemba) :
///
/// Les 54 facettes sont numérotées face par face dans l'ordre
/// U (haut), R (droite), F (devant), D (bas), L (gauche), B (derrière).
/// Chaque face est lue ligne par ligne, de gauche à droite, en la regardant
/// de face :
///
/// ```
///              |U0 U1 U2|
///              |U3 U4 U5|
///              |U6 U7 U8|
///  |L36 L37 L38|F18 F19 F20|R9  R10 R11|B45 B46 B47|
///  |L39 L40 L41|F21 F22 F23|R12 R13 R14|B48 B49 B50|
///  |L42 L43 L44|F24 F25 F26|R15 R16 R17|B51 B52 B53|
///              |D27 D28 D29|
///              |D30 D31 D32|
///              |D33 D34 D35|
/// ```
///
/// - U est vue de dessus, avec B en haut de l'image.
/// - R, F, L, B sont vues de face, avec U en haut de l'image.
/// - D est vue de dessous, avec F en haut de l'image.
library;

import '../l10n/strings.dart';

/// Les six faces du cube.
enum Face {
  U('U'),
  R('R'),
  F('F'),
  D('D'),
  L('L'),
  B('B');

  const Face(this.letter);
  final String letter;

  /// Index de la facette centrale de cette face (0..53).
  int get centerIndex => index * 9 + 4;

  static Face fromLetter(String letter) => Face.values.firstWhere(
    (f) => f.letter == letter,
    orElse: () => throw ArgumentError('Face inconnue : $letter'),
  );
}

/// Couleurs physiques des autocollants.
enum CubeColor {
  white,
  yellow,
  green,
  blue,
  red,
  orange;

  /// Nom de la couleur dans la langue active (« Rouge », « Red »…).
  String get label => Strings.current.colorName(this);
}

/// Les 8 coins : URF, UFL, ULB, UBR, DFR, DLF, DBL, DRB.
enum Corner { urf, ufl, ulb, ubr, dfr, dlf, dbl, drb }

/// Les 12 arêtes : UR, UF, UL, UB, DR, DF, DL, DB, FR, FL, BL, BR.
enum Edge { ur, uf, ul, ub, dr, df, dl, db, fr, fl, bl, br }

// Index de facettes, pour la lisibilité des tables ci-dessous.
const int _u = 0, _r = 9, _f = 18, _d = 27, _l = 36, _b = 45;

/// Pour chaque position de coin, les trois facettes qui la composent, dans le
/// sens horaire en partant de la facette U ou D.
const List<List<int>> cornerFacelets = [
  [_u + 8, _r + 0, _f + 2], // URF
  [_u + 6, _f + 0, _l + 2], // UFL
  [_u + 0, _l + 0, _b + 2], // ULB
  [_u + 2, _b + 0, _r + 2], // UBR
  [_d + 2, _f + 8, _r + 6], // DFR
  [_d + 0, _l + 8, _f + 6], // DLF
  [_d + 6, _b + 8, _l + 6], // DBL
  [_d + 8, _r + 8, _b + 6], // DRB
];

/// Pour chaque position d'arête, ses deux facettes.
const List<List<int>> edgeFacelets = [
  [_u + 5, _r + 1], // UR
  [_u + 7, _f + 1], // UF
  [_u + 3, _l + 1], // UL
  [_u + 1, _b + 1], // UB
  [_d + 5, _r + 7], // DR
  [_d + 1, _f + 7], // DF
  [_d + 3, _l + 7], // DL
  [_d + 7, _b + 7], // DB
  [_f + 5, _r + 3], // FR
  [_f + 3, _l + 5], // FL
  [_b + 5, _l + 3], // BL
  [_b + 3, _r + 5], // BR
];

/// Couleurs (exprimées en faces) de chaque coin, dans le même ordre que
/// [cornerFacelets].
const List<List<Face>> cornerColors = [
  [Face.U, Face.R, Face.F],
  [Face.U, Face.F, Face.L],
  [Face.U, Face.L, Face.B],
  [Face.U, Face.B, Face.R],
  [Face.D, Face.F, Face.R],
  [Face.D, Face.L, Face.F],
  [Face.D, Face.B, Face.L],
  [Face.D, Face.R, Face.B],
];

/// Couleurs (exprimées en faces) de chaque arête.
const List<List<Face>> edgeColors = [
  [Face.U, Face.R],
  [Face.U, Face.F],
  [Face.U, Face.L],
  [Face.U, Face.B],
  [Face.D, Face.R],
  [Face.D, Face.F],
  [Face.D, Face.L],
  [Face.D, Face.B],
  [Face.F, Face.R],
  [Face.F, Face.L],
  [Face.B, Face.L],
  [Face.B, Face.R],
];

/// Nom lisible d'un coin, par ex. « UFL ».
String cornerName(int c) => Corner.values[c].name.toUpperCase();

/// Nom lisible d'une arête, par ex. « FR ».
String edgeName(int e) => Edge.values[e].name.toUpperCase();
