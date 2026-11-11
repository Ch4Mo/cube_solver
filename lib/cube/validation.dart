import 'cubie_cube.dart';
import 'definitions.dart';

/// Type de problème détecté dans un cube scanné.
enum CubeErrorType {
  /// Il n'y a pas exactement 54 facettes.
  wrongFaceletCount,

  /// Une couleur n'apparaît pas exactement 9 fois (erreur de détection
  /// probable, ou autocollant remplacé).
  wrongColorCount,

  /// Deux faces ont le même centre.
  duplicateCenter,

  /// Une combinaison de couleurs ne correspond à aucun coin réel.
  invalidCorner,

  /// Une combinaison de couleurs ne correspond à aucune arête réelle.
  invalidEdge,

  /// Le même coin apparaît deux fois.
  duplicateCorner,

  /// La même arête apparaît deux fois.
  duplicateEdge,

  /// Un coin a été tourné sur lui-même (somme des orientations ≢ 0 mod 3).
  twistedCorner,

  /// Une arête a été retournée (somme des orientations impaire).
  flippedEdge,

  /// Deux pièces ont été échangées (parités coins / arêtes différentes).
  swappedPieces,
}

/// Un problème détecté, avec un message en français destiné à l'utilisateur.
class CubeError {
  const CubeError(this.type, this.message, {this.facelets = const []});

  final CubeErrorType type;
  final String message;

  /// Facettes concernées (index 0..53), pour les mettre en évidence à l'écran.
  final List<int> facelets;

  /// Vrai si l'erreur vient sûrement d'une manipulation physique du cube
  /// (pièce tournée, retournée ou échangée) plutôt que d'une mauvaise
  /// détection des couleurs.
  bool get isPhysicalTampering => const {
    CubeErrorType.twistedCorner,
    CubeErrorType.flippedEdge,
    CubeErrorType.swappedPieces,
  }.contains(type);

  @override
  String toString() => message;
}

/// Résultat de la validation.
class ValidationResult {
  const ValidationResult._(this.errors, this.cube, this.colorScheme);

  final List<CubeError> errors;

  /// L'état du cube, si les pièces ont pu être identifiées (même si le cube
  /// n'est pas résoluble).
  final CubieCube? cube;

  /// Couleur du centre de chaque face, si les centres sont valides.
  final Map<Face, CubeColor>? colorScheme;

  bool get isValid => errors.isEmpty;
}

/// Vérifie qu'un cube scanné (54 couleurs, voir l'ordre dans
/// `definitions.dart`) est un cube réel et résoluble.
ValidationResult validateColors(List<CubeColor> colors) {
  if (colors.length != 54) {
    return ValidationResult._(
      [
        CubeError(
          CubeErrorType.wrongFaceletCount,
          'Il faut 54 cases (6 faces × 9), ${colors.length} reçues.',
        ),
      ],
      null,
      null,
    );
  }

  // 1. Chaque couleur exactement 9 fois.
  final counts = {for (final c in CubeColor.values) c: 0};
  for (final c in colors) {
    counts[c] = counts[c]! + 1;
  }
  final badCounts = counts.entries.where((e) => e.value != 9).toList();
  if (badCounts.isNotEmpty) {
    final detail = badCounts
        .map((e) => '${e.key.label} : ${e.value}')
        .join(', ');
    return ValidationResult._(
      [
        CubeError(
          CubeErrorType.wrongColorCount,
          'Chaque couleur doit apparaître 9 fois ($detail). '
          'Vérifiez les couleurs détectées.',
          facelets: [
            for (var i = 0; i < 54; i++)
              if (counts[colors[i]] != 9) i,
          ],
        ),
      ],
      null,
      null,
    );
  }

  // 2. Six centres différents.
  final scheme = <CubeColor, Face>{};
  for (final face in Face.values) {
    final c = colors[face.centerIndex];
    if (scheme.containsKey(c)) {
      return ValidationResult._(
        [
          CubeError(
            CubeErrorType.duplicateCenter,
            'Les faces ${scheme[c]!.letter} et ${face.letter} ont le même '
            'centre (${c.label}).',
            facelets: [scheme[c]!.centerIndex, face.centerIndex],
          ),
        ],
        null,
        null,
      );
    }
    scheme[c] = face;
  }

  final facelets = [for (final c in colors) scheme[c]!];
  final result = validateFacelets(facelets);
  return ValidationResult._(result.errors, result.cube, {
    for (final e in scheme.entries) e.value: e.key,
  });
}

/// Valide une chaîne de 54 lettres URFDLB (format standard de Kociemba).
ValidationResult validateFaceletString(String s) {
  if (s.length != 54) {
    return ValidationResult._(
      [
        CubeError(
          CubeErrorType.wrongFaceletCount,
          'Il faut 54 cases (6 faces × 9), ${s.length} reçues.',
        ),
      ],
      null,
      null,
    );
  }
  // On passe par des couleurs arbitraires pour réutiliser les contrôles.
  final colors = [
    for (final ch in s.split('')) CubeColor.values[Face.fromLetter(ch).index],
  ];
  return validateColors(colors);
}

/// Valide 54 facettes exprimées en faces (le centre de chaque face doit
/// correspondre à la face).
ValidationResult validateFacelets(List<Face> f) {
  final errors = <CubeError>[];
  final cube = CubieCube();

  // 3. Identification des coins.
  var piecesOk = true;
  for (var i = 0; i < 8; i++) {
    final fl = cornerFacelets[i];
    var ori = 0;
    while (ori < 3 && f[fl[ori]] != Face.U && f[fl[ori]] != Face.D) {
      ori++;
    }
    final found = ori < 3
        ? _findCorner(f[fl[(ori + 1) % 3]], f[fl[(ori + 2) % 3]])
        : -1;
    if (found < 0 || cornerColors[found][0] != f[fl[ori]]) {
      piecesOk = false;
      errors.add(
        CubeError(
          CubeErrorType.invalidCorner,
          'Le coin en position ${cornerName(i)} a une combinaison de couleurs '
          'impossible. Vérifiez les couleurs détectées.',
          facelets: fl,
        ),
      );
      continue;
    }
    cube.cp[i] = found;
    cube.co[i] = ori;
  }

  // 4. Identification des arêtes.
  for (var i = 0; i < 12; i++) {
    final a = f[edgeFacelets[i][0]], b = f[edgeFacelets[i][1]];
    var found = false;
    for (var j = 0; j < 12; j++) {
      if (edgeColors[j][0] == a && edgeColors[j][1] == b) {
        cube.ep[i] = j;
        cube.eo[i] = 0;
        found = true;
      } else if (edgeColors[j][0] == b && edgeColors[j][1] == a) {
        cube.ep[i] = j;
        cube.eo[i] = 1;
        found = true;
      }
    }
    if (!found) {
      piecesOk = false;
      errors.add(
        CubeError(
          CubeErrorType.invalidEdge,
          "L'arête en position ${edgeName(i)} a une combinaison de couleurs "
          'impossible. Vérifiez les couleurs détectées.',
          facelets: edgeFacelets[i],
        ),
      );
    }
  }
  if (!piecesOk) return ValidationResult._(errors, null, null);

  // 5. Chaque pièce présente une seule fois.
  for (var j = 0; j < 8; j++) {
    final where = [
      for (var i = 0; i < 8; i++)
        if (cube.cp[i] == j) i,
    ];
    if (where.length > 1) {
      errors.add(
        CubeError(
          CubeErrorType.duplicateCorner,
          'Le coin ${cornerName(j)} apparaît ${where.length} fois.',
          facelets: [for (final i in where) ...cornerFacelets[i]],
        ),
      );
    }
  }
  for (var j = 0; j < 12; j++) {
    final where = [
      for (var i = 0; i < 12; i++)
        if (cube.ep[i] == j) i,
    ];
    if (where.length > 1) {
      errors.add(
        CubeError(
          CubeErrorType.duplicateEdge,
          "L'arête ${edgeName(j)} apparaît ${where.length} fois.",
          facelets: [for (final i in where) ...edgeFacelets[i]],
        ),
      );
    }
  }
  if (errors.isNotEmpty) return ValidationResult._(errors, null, null);

  // 6. Invariants : une pièce a-t-elle été manipulée à la main ?
  final twist = cube.cornerTwistSum;
  if (twist != 0) {
    errors.add(
      CubeError(
        CubeErrorType.twistedCorner,
        'Un coin a été tourné sur lui-même (dans le sens '
        '${twist == 1 ? 'horaire' : 'anti-horaire'}). Le cube ne peut pas être '
        'résolu tant que ce coin n\'est pas remis dans le bon sens.',
      ),
    );
  }
  if (cube.edgeFlipSum != 0) {
    errors.add(
      const CubeError(
        CubeErrorType.flippedEdge,
        'Une arête a été retournée. Le cube ne peut pas être résolu tant '
        'qu\'elle n\'est pas remise dans le bon sens.',
      ),
    );
  }
  if (cube.cornerParity != cube.edgeParity) {
    errors.add(
      const CubeError(
        CubeErrorType.swappedPieces,
        'Deux pièces ont été échangées (cube démonté ou autocollants '
        'déplacés). Le cube ne peut pas être résolu en l\'état.',
      ),
    );
  }

  return ValidationResult._(errors, cube, null);
}

int _findCorner(Face a, Face b) {
  for (var j = 0; j < 8; j++) {
    if (cornerColors[j][1] == a && cornerColors[j][2] == b) return j;
  }
  return -1;
}
