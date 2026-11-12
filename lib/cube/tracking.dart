import '../l10n/strings.dart';
import 'cubie_cube.dart';
import 'definitions.dart';
import 'moves.dart';

/// Résultat de la vérification d'une face pendant la résolution.
class ProgressCheck {
  const ProgressCheck({
    required this.expectedStep,
    required this.matches,
    required this.mismatchedFacelets,
    this.matchingStep,
  });

  /// Étape à laquelle l'utilisateur devrait être (nombre de mouvements faits).
  final int expectedStep;

  /// Vrai si la face observée correspond à l'état attendu.
  final bool matches;

  /// Positions (0..8 sur la face) qui ne correspondent pas.
  final List<int> mismatchedFacelets;

  /// Si la face ne correspond pas à l'étape attendue mais à une étape voisine,
  /// le numéro de cette étape (l'utilisateur a sauté ou répété un mouvement).
  final int? matchingStep;

  String get message {
    final t = Strings.current;
    if (matches) return t.progressOk;
    if (matchingStep != null) {
      final diff = matchingStep! - expectedStep;
      return diff < 0
          ? t.movesMissing(-diff, matchingStep! + 1)
          : t.movesExtra(diff, matchingStep! + 1);
    }
    return t.pieceMoved(mismatchedFacelets.length);
  }
}

/// État attendu (54 facettes) après les `step` premiers mouvements.
List<Face> expectedFacelets(CubieCube start, List<Move> moves, int step) {
  final c = start.copy()..applyMoves(moves.take(step));
  return c.toFacelets();
}

/// Compare une face observée (9 facettes, centre compris) avec l'état
/// attendu après `step` mouvements de la solution.
///
/// Si elle ne correspond pas, cherche une étape voisine (± [searchRadius])
/// qui correspondrait, pour aider l'utilisateur à se recaler.
ProgressCheck checkFace(
  CubieCube start,
  List<Move> moves,
  int step,
  Face face,
  List<Face> observed, {
  int searchRadius = 3,
}) {
  if (observed.length != 9) {
    throw ArgumentError('Une face doit contenir 9 cases.');
  }
  List<int> mismatches(int s) {
    final expected = expectedFacelets(start, moves, s);
    return [
      for (var k = 0; k < 9; k++)
        if (expected[face.index * 9 + k] != observed[k]) k,
    ];
  }

  final diff = mismatches(step);
  if (diff.isEmpty) {
    return ProgressCheck(
      expectedStep: step,
      matches: true,
      mismatchedFacelets: const [],
    );
  }
  int? matching;
  for (var r = 1; r <= searchRadius && matching == null; r++) {
    for (final s in [step - r, step + r]) {
      if (s >= 0 && s <= moves.length && mismatches(s).isEmpty) {
        matching = s;
        break;
      }
    }
  }
  return ProgressCheck(
    expectedStep: step,
    matches: false,
    mismatchedFacelets: diff,
    matchingStep: matching,
  );
}
