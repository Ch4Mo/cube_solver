import 'dart:typed_data';

import 'cubie_cube.dart';
import 'definitions.dart';
import 'moves.dart';
import 'validation.dart';

/// Solveur basé sur l'algorithme à deux phases de Herbert Kociemba.
///
/// Phase 1 : amener le cube dans le sous-groupe G1 = `<U, D, R2, L2, F2, B2>`
/// (orientations correctes et arêtes du milieu dans la tranche du milieu).
/// Phase 2 : résoudre le cube en n'utilisant que les mouvements de G1.
///
/// Les tables (environ 6 Mo) sont calculées une seule fois, au premier appel
/// de [Solver.instance]. Cela prend une à deux secondes : sur mobile, il faut
/// le faire dans un isolate (voir `compute` dans Flutter).
class Solver {
  Solver._() {
    _buildMoveTables();
    _buildPruningTables();
  }

  static Solver? _instance;

  /// Le solveur partagé (les tables sont construites au premier accès).
  static Solver get instance => _instance ??= Solver._();

  static const int _nTwist = 2187;
  static const int _nFlip = 2048;
  static const int _nSlice = 495;
  static const int _nPerm8 = 40320;
  static const int _nSlicePerm = 24;
  static const int _nMoves = 18;

  /// Mouvements autorisés en phase 2 : U, U2, U', D, D2, D', R2, L2, F2, B2.
  static final List<int> _phase2Moves = [
    for (var m = 0; m < _nMoves; m++)
      if (_isPhase2Move(m)) m,
  ];

  static bool _isPhase2Move(int m) {
    final face = m ~/ 3;
    return face == Face.U.index || face == Face.D.index || m % 3 == 1;
  }

  late final Uint16List _twistMove;
  late final Uint16List _flipMove;
  late final Uint16List _sliceMove;
  late final Uint16List _cornerPermMove;
  late final Uint16List _udEdgePermMove;
  late final Uint8List _slicePermMove;

  late final Uint8List _sliceTwistPrune;
  late final Uint8List _sliceFlipPrune;
  late final Uint8List _sliceCornerPrune;
  late final Uint8List _sliceEdgePrune;

  // ---------------------------------------------------------------------
  // Construction des tables.
  // ---------------------------------------------------------------------

  void _buildMoveTables() {
    Uint16List build(
      int n,
      void Function(CubieCube, int) set,
      int Function(CubieCube) get, {
      bool phase2Only = false,
    }) {
      final table = Uint16List(n * _nMoves);
      final cube = CubieCube();
      for (var i = 0; i < n; i++) {
        for (var face = 0; face < 6; face++) {
          set(cube, i);
          for (var t = 0; t < 3; t++) {
            cube.multiply(basicMoves[face]);
            final m = face * 3 + t;
            if (phase2Only && !_isPhase2Move(m)) continue;
            table[i * _nMoves + m] = get(cube);
          }
        }
      }
      return table;
    }

    _twistMove = build(_nTwist, (c, v) => c.twist = v, (c) => c.twist);
    _flipMove = build(_nFlip, (c, v) => c.flip = v, (c) => c.flip);
    _sliceMove = build(_nSlice, (c, v) => c.slice = v, (c) => c.slice);
    _cornerPermMove = build(
      _nPerm8,
      (c, v) => c.cornerPerm = v,
      (c) => c.cornerPerm,
    );
    _udEdgePermMove = build(
      _nPerm8,
      (c, v) {
        c.ep.setAll(0, List.generate(12, (i) => i));
        c.udEdgePerm = v;
      },
      (c) => c.udEdgePerm,
      phase2Only: true,
    );
    _slicePermMove = Uint8List.fromList(
      build(
        _nSlicePerm,
        (c, v) {
          c.ep.setAll(0, List.generate(12, (i) => i));
          c.slicePerm = v;
        },
        (c) => c.slicePerm,
        phase2Only: true,
      ),
    );
  }

  /// Parcours en largeur sur le produit de deux coordonnées.
  Uint8List _bfs(
    int nA,
    int nB,
    int Function(int, int) moveA,
    int Function(int, int) moveB,
    List<int> moves,
  ) {
    final size = nA * nB;
    final table = Uint8List(size)..fillRange(0, size, 255);
    table[0] = 0;
    var done = 1, depth = 0;
    while (done < size) {
      for (var i = 0; i < size; i++) {
        if (table[i] != depth) continue;
        final a = i ~/ nB, b = i % nB;
        for (final m in moves) {
          final j = moveA(a, m) * nB + moveB(b, m);
          if (table[j] == 255) {
            table[j] = depth + 1;
            done++;
          }
        }
      }
      depth++;
    }
    return table;
  }

  void _buildPruningTables() {
    final all = List.generate(_nMoves, (m) => m);
    int slice(int s, int m) => _sliceMove[s * _nMoves + m];
    _sliceTwistPrune = _bfs(
      _nSlice,
      _nTwist,
      slice,
      (t, m) => _twistMove[t * _nMoves + m],
      all,
    );
    _sliceFlipPrune = _bfs(
      _nSlice,
      _nFlip,
      slice,
      (f, m) => _flipMove[f * _nMoves + m],
      all,
    );

    int slicePerm(int s, int m) => _slicePermMove[s * _nMoves + m];
    _sliceCornerPrune = _bfs(
      _nSlicePerm,
      _nPerm8,
      slicePerm,
      (c, m) => _cornerPermMove[c * _nMoves + m],
      _phase2Moves,
    );
    _sliceEdgePrune = _bfs(
      _nSlicePerm,
      _nPerm8,
      slicePerm,
      (e, m) => _udEdgePermMove[e * _nMoves + m],
      _phase2Moves,
    );
  }

  // ---------------------------------------------------------------------
  // Recherche.
  // ---------------------------------------------------------------------

  /// Résout un cube donné sous forme de pièces.
  ///
  /// Cherche une solution d'au plus [targetLength] mouvements, en s'arrêtant
  /// au bout de [timeout] avec la meilleure solution trouvée.
  List<Move> solveCubie(
    CubieCube cube, {
    int targetLength = 21,
    Duration timeout = const Duration(seconds: 3),
  }) {
    if (cube.isSolved) return const [];
    final search = _Search(this, cube, targetLength, timeout);
    final result = search.run();
    if (result == null) {
      throw StateError('Aucune solution trouvée dans le temps imparti.');
    }
    return result;
  }

  /// Résout un cube décrit par 54 couleurs. Lève [UnsolvableCubeException]
  /// si le cube n'est pas valide.
  List<Move> solveColors(
    List<CubeColor> colors, {
    int targetLength = 21,
    Duration timeout = const Duration(seconds: 3),
  }) {
    final v = validateColors(colors);
    if (!v.isValid) throw UnsolvableCubeException(v.errors);
    return solveCubie(v.cube!, targetLength: targetLength, timeout: timeout);
  }

  /// Résout un cube décrit par une chaîne de 54 lettres URFDLB.
  List<Move> solveFacelets(
    String facelets, {
    int targetLength = 21,
    Duration timeout = const Duration(seconds: 3),
  }) {
    final v = validateFaceletString(facelets);
    if (!v.isValid) throw UnsolvableCubeException(v.errors);
    return solveCubie(v.cube!, targetLength: targetLength, timeout: timeout);
  }
}

class UnsolvableCubeException implements Exception {
  UnsolvableCubeException(this.errors);
  final List<CubeError> errors;

  @override
  String toString() => errors.map((e) => e.message).join('\n');
}

class _Search {
  _Search(this.s, this.cube, this.targetLength, Duration timeout)
    : deadline = DateTime.now().add(timeout),
      softDeadline = DateTime.now().add(_minSearchTime);

  /// Temps minimal de recherche : même si une solution assez courte est
  /// trouvée tout de suite, on continue un peu pour l'améliorer (utile pour
  /// les cubes presque résolus).
  static const Duration _minSearchTime = Duration(milliseconds: 100);

  final Solver s;
  final CubieCube cube;
  final int targetLength;
  final DateTime deadline;
  final DateTime softDeadline;

  static const int _maxLength = 30;
  final List<int> _path = List.filled(_maxLength + 1, -1);
  List<int>? _best;
  int _nodes = 0;
  bool _stop = false;

  List<Move>? run() {
    final twist = cube.twist, flip = cube.flip, slice = cube.slice;
    for (var depth1 = 0; depth1 <= _maxLength; depth1++) {
      if (_best != null && depth1 >= _best!.length) break;
      if (_phase1(twist, flip, slice, 0, depth1)) break;
      if (_stop) break;
    }
    return _best?.map(Move.fromIndex).toList();
  }

  static bool _skip(int move, int prev) {
    if (prev < 0) return false;
    final f = move ~/ 3, p = prev ~/ 3;
    // Même face, ou faces opposées dans l'ordre inverse (D puis U = U puis D).
    return f == p || f + 3 == p;
  }

  bool _checkTime() {
    if ((++_nodes & 0x3FF) == 0) _updateStop();
    return _stop;
  }

  void _updateStop() {
    final best = _best;
    if (best == null) return; // On ne s'arrête jamais sans solution.
    final now = DateTime.now();
    _stop =
        best.length <= 1 ||
        now.isAfter(deadline) ||
        (best.length <= targetLength && now.isAfter(softDeadline));
  }

  /// Retourne vrai pour arrêter toute la recherche.
  bool _phase1(int twist, int flip, int slice, int depth, int maxDepth) {
    if (depth == maxDepth) {
      if (twist != 0 || flip != 0 || slice != 0) return false;
      // Le dernier mouvement de la phase 1 ne doit pas être un mouvement de
      // la phase 2, sinon cette solution a déjà été examinée plus tôt.
      if (depth > 0 && Solver._isPhase2Move(_path[depth - 1])) return false;
      return _startPhase2(depth);
    }
    for (var m = 0; m < 18; m++) {
      if (_skip(m, depth > 0 ? _path[depth - 1] : -1)) continue;
      final t = s._twistMove[twist * 18 + m];
      final f = s._flipMove[flip * 18 + m];
      final sl = s._sliceMove[slice * 18 + m];
      final h1 = s._sliceTwistPrune[sl * Solver._nTwist + t];
      final h2 = s._sliceFlipPrune[sl * Solver._nFlip + f];
      if ((h1 > h2 ? h1 : h2) > maxDepth - depth - 1) continue;
      _path[depth] = m;
      if (_phase1(t, f, sl, depth + 1, maxDepth)) return true;
      if (_checkTime()) return true;
    }
    return false;
  }

  bool _startPhase2(int depth1) {
    final c = cube.copy();
    for (var i = 0; i < depth1; i++) {
      c.applyMove(Move.fromIndex(_path[i]));
    }
    final cp = c.cornerPerm, ep = c.udEdgePerm, sp = c.slicePerm;
    final limit = (_best?.length ?? _maxLength + 1) - 1 - depth1;
    for (var depth2 = 0; depth2 <= limit; depth2++) {
      if (_phase2(cp, ep, sp, depth1, depth1, depth1 + depth2)) {
        _best = _path.sublist(0, depth1 + depth2);
        _updateStop();
        return _stop;
      }
    }
    return false;
  }

  bool _phase2(int cp, int ep, int sp, int depth1, int depth, int maxDepth) {
    final h1 = s._sliceCornerPrune[sp * Solver._nPerm8 + cp];
    final h2 = s._sliceEdgePrune[sp * Solver._nPerm8 + ep];
    if ((h1 > h2 ? h1 : h2) > maxDepth - depth) return false;
    if (depth == maxDepth) return true; // h == 0 → résolu
    for (final m in Solver._phase2Moves) {
      if (_skip(m, depth > 0 ? _path[depth - 1] : -1)) continue;
      _path[depth] = m;
      if (_phase2(
        s._cornerPermMove[cp * 18 + m],
        s._udEdgePermMove[ep * 18 + m],
        s._slicePermMove[sp * 18 + m],
        depth1,
        depth + 1,
        maxDepth,
      )) {
        return true;
      }
    }
    return false;
  }
}
