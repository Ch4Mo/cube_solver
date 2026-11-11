import 'dart:math';

import 'definitions.dart';
import 'moves.dart';

/// Représentation du cube au niveau des pièces (« cubies ») :
/// permutation et orientation des 8 coins et des 12 arêtes.
///
/// `cp[i]` est le coin qui occupe la position `i`, `co[i]` son orientation
/// (0..2). Idem pour les arêtes avec `ep` / `eo` (0..1).
class CubieCube {
  CubieCube({List<int>? cp, List<int>? co, List<int>? ep, List<int>? eo})
    : cp = List.of(cp ?? List.generate(8, (i) => i)),
      co = List.of(co ?? List.filled(8, 0)),
      ep = List.of(ep ?? List.generate(12, (i) => i)),
      eo = List.of(eo ?? List.filled(12, 0));

  /// Le cube résolu.
  factory CubieCube.solved() => CubieCube();

  final List<int> cp;
  final List<int> co;
  final List<int> ep;
  final List<int> eo;

  CubieCube copy() => CubieCube(cp: cp, co: co, ep: ep, eo: eo);

  bool get isSolved {
    for (var i = 0; i < 8; i++) {
      if (cp[i] != i || co[i] != 0) return false;
    }
    for (var i = 0; i < 12; i++) {
      if (ep[i] != i || eo[i] != 0) return false;
    }
    return true;
  }

  /// Applique `b` après l'état courant (this = this * b).
  void multiply(CubieCube b) {
    final ncp = List<int>.filled(8, 0), nco = List<int>.filled(8, 0);
    for (var i = 0; i < 8; i++) {
      ncp[i] = cp[b.cp[i]];
      nco[i] = (co[b.cp[i]] + b.co[i]) % 3;
    }
    final nep = List<int>.filled(12, 0), neo = List<int>.filled(12, 0);
    for (var i = 0; i < 12; i++) {
      nep[i] = ep[b.ep[i]];
      neo[i] = (eo[b.ep[i]] + b.eo[i]) % 2;
    }
    cp.setAll(0, ncp);
    co.setAll(0, nco);
    ep.setAll(0, nep);
    eo.setAll(0, neo);
  }

  /// Applique un mouvement.
  void applyMove(Move move) {
    final basic = basicMoves[move.face.index];
    for (var i = 0; i < move.turns; i++) {
      multiply(basic);
    }
  }

  void applyMoves(Iterable<Move> moves) => moves.forEach(applyMove);

  /// Convertit en liste de 54 facettes (exprimées en faces).
  List<Face> toFacelets() {
    final f = List<Face>.filled(54, Face.U);
    for (final face in Face.values) {
      for (var k = 0; k < 9; k++) {
        f[face.index * 9 + k] = face;
      }
    }
    for (var i = 0; i < 8; i++) {
      final j = cp[i], ori = co[i];
      for (var n = 0; n < 3; n++) {
        f[cornerFacelets[i][(n + ori) % 3]] = cornerColors[j][n];
      }
    }
    for (var i = 0; i < 12; i++) {
      final j = ep[i], ori = eo[i];
      for (var n = 0; n < 2; n++) {
        f[edgeFacelets[i][(n + ori) % 2]] = edgeColors[j][n];
      }
    }
    return f;
  }

  // ---------------------------------------------------------------------
  // Invariants mathématiques (utilisés par la validation).
  // ---------------------------------------------------------------------

  int get cornerTwistSum => co.fold(0, (a, b) => a + b) % 3;
  int get edgeFlipSum => eo.fold(0, (a, b) => a + b) % 2;
  int get cornerParity => _parity(cp);
  int get edgeParity => _parity(ep);

  static int _parity(List<int> p) {
    var s = 0;
    for (var i = p.length - 1; i > 0; i--) {
      for (var j = i - 1; j >= 0; j--) {
        if (p[j] > p[i]) s++;
      }
    }
    return s % 2;
  }

  // ---------------------------------------------------------------------
  // Coordonnées pour l'algorithme à deux phases de Kociemba.
  // ---------------------------------------------------------------------

  /// Orientation des coins : 0..2186 (3^7).
  int get twist {
    var r = 0;
    for (var i = 0; i < 7; i++) {
      r = 3 * r + co[i];
    }
    return r;
  }

  set twist(int value) {
    var parity = 0;
    for (var i = 6; i >= 0; i--) {
      co[i] = value % 3;
      parity += co[i];
      value ~/= 3;
    }
    co[7] = (3 - parity % 3) % 3;
  }

  /// Orientation des arêtes : 0..2047 (2^11).
  int get flip {
    var r = 0;
    for (var i = 0; i < 11; i++) {
      r = 2 * r + eo[i];
    }
    return r;
  }

  set flip(int value) {
    var parity = 0;
    for (var i = 10; i >= 0; i--) {
      eo[i] = value % 2;
      parity += eo[i];
      value ~/= 2;
    }
    eo[11] = (2 - parity % 2) % 2;
  }

  /// Positions (sans ordre) des 4 arêtes de la tranche du milieu
  /// (FR, FL, BL, BR) : 0..494. Vaut 0 quand elles sont à leur place.
  int get slice {
    var a = 0, x = 0;
    for (var j = 11; j >= 0; j--) {
      if (ep[j] >= Edge.fr.index) {
        a += binomial(11 - j, x + 1);
        x++;
      }
    }
    return a;
  }

  set slice(int value) {
    final positions = _slicePositions[value];
    var other = 0, s = Edge.fr.index;
    for (var j = 0; j < 12; j++) {
      ep[j] = positions.contains(j) ? s++ : other++;
    }
  }

  /// Permutation des 8 coins : 0..40319.
  int get cornerPerm => _rankPerm(cp, 0, 8);
  set cornerPerm(int value) => _unrankPerm(cp, 0, 8, value);

  /// Permutation des 8 arêtes U/D (phase 2 uniquement) : 0..40319.
  int get udEdgePerm => _rankPerm(ep, 0, 8);
  set udEdgePerm(int value) => _unrankPerm(ep, 0, 8, value);

  /// Permutation des 4 arêtes de la tranche (phase 2 uniquement) : 0..23.
  int get slicePerm => _rankPerm(ep, 8, 4);
  set slicePerm(int value) => _unrankPerm(ep, 8, 4, value);

  // Rang de Lehmer de p[offset..offset+n), dont les valeurs sont
  // offset..offset+n-1.
  static int _rankPerm(List<int> p, int offset, int n) {
    var r = 0;
    for (var i = 0; i < n; i++) {
      var smaller = 0;
      for (var j = i + 1; j < n; j++) {
        if (p[offset + j] < p[offset + i]) smaller++;
      }
      r = r * (n - i) + smaller;
    }
    return r;
  }

  static void _unrankPerm(List<int> p, int offset, int n, int value) {
    final digits = List<int>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      digits[i] = value % (n - i);
      value ~/= (n - i);
    }
    final available = List.generate(n, (i) => offset + i);
    for (var i = 0; i < n; i++) {
      p[offset + i] = available.removeAt(digits[i]);
    }
  }

  static final List<Set<int>> _slicePositions = () {
    final result = List<Set<int>>.filled(495, const {});
    final cube = CubieCube();
    for (var a = 0; a < 12; a++) {
      for (var b = a + 1; b < 12; b++) {
        for (var c = b + 1; c < 12; c++) {
          for (var d = c + 1; d < 12; d++) {
            final pos = {a, b, c, d};
            var other = 0, s = 8;
            for (var j = 0; j < 12; j++) {
              cube.ep[j] = pos.contains(j) ? s++ : other++;
            }
            result[cube.slice] = pos;
          }
        }
      }
    }
    return result;
  }();

  /// Cube mélangé aléatoirement (état toujours résoluble).
  factory CubieCube.random([Random? random]) {
    final rnd = random ?? Random();
    final c = CubieCube();
    c.cornerPerm = rnd.nextInt(40320);
    // Permutation aléatoire des 12 arêtes de même parité que les coins.
    final edges = List.generate(12, (i) => i)..shuffle(rnd);
    c.ep.setAll(0, edges);
    if (c.edgeParity != c.cornerParity) {
      final t = c.ep[0];
      c.ep[0] = c.ep[1];
      c.ep[1] = t;
    }
    c.twist = rnd.nextInt(2187);
    c.flip = rnd.nextInt(2048);
    return c;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CubieCube) return false;
    for (var i = 0; i < 8; i++) {
      if (cp[i] != other.cp[i] || co[i] != other.co[i]) return false;
    }
    for (var i = 0; i < 12; i++) {
      if (ep[i] != other.ep[i] || eo[i] != other.eo[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([...cp, ...co, ...ep, ...eo]);
}

int binomial(int n, int k) {
  if (k < 0 || k > n) return 0;
  var r = 1;
  for (var i = 0; i < k; i++) {
    r = r * (n - i) ~/ (i + 1);
  }
  return r;
}

/// Les 6 quarts de tour de base, dans l'ordre U, R, F, D, L, B.
final List<CubieCube> basicMoves = [
  // U
  CubieCube(
    cp: [3, 0, 1, 2, 4, 5, 6, 7],
    ep: [3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11],
  ),
  // R
  CubieCube(
    cp: [4, 1, 2, 0, 7, 5, 6, 3],
    co: [2, 0, 0, 1, 1, 0, 0, 2],
    ep: [8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0],
  ),
  // F
  CubieCube(
    cp: [1, 5, 2, 3, 0, 4, 6, 7],
    co: [1, 2, 0, 0, 2, 1, 0, 0],
    ep: [0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11],
    eo: [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0],
  ),
  // D
  CubieCube(
    cp: [0, 1, 2, 3, 5, 6, 7, 4],
    ep: [0, 1, 2, 3, 5, 6, 7, 4, 8, 9, 10, 11],
  ),
  // L
  CubieCube(
    cp: [0, 2, 6, 3, 4, 1, 5, 7],
    co: [0, 1, 2, 0, 0, 2, 1, 0],
    ep: [0, 1, 10, 3, 4, 5, 9, 7, 8, 2, 6, 11],
  ),
  // B
  CubieCube(
    cp: [0, 1, 3, 7, 4, 5, 2, 6],
    co: [0, 0, 1, 2, 0, 0, 2, 1],
    ep: [0, 1, 2, 11, 4, 5, 6, 10, 8, 9, 3, 7],
    eo: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1],
  ),
];
