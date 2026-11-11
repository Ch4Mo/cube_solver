import 'definitions.dart';

/// Un mouvement du cube : une face tournée de 1, 2 ou 3 quarts de tour
/// dans le sens horaire (3 quarts = un quart anti-horaire, noté « ' »).
class Move {
  const Move(this.face, this.turns) : assert(turns >= 1 && turns <= 3);

  /// Construit un mouvement à partir de son index 0..17 (`3 * face + turns - 1`).
  factory Move.fromIndex(int index) =>
      Move(Face.values[index ~/ 3], index % 3 + 1);

  final Face face;
  final int turns;

  int get index => face.index * 3 + turns - 1;

  /// Le mouvement inverse (R → R', R2 → R2).
  Move get inverse => Move(face, 4 - turns);

  /// Notation standard : U, U2, U'.
  String get notation => switch (turns) {
    1 => face.letter,
    2 => '${face.letter}2',
    _ => "${face.letter}'",
  };

  /// Analyse un mouvement en notation standard (« R », « R2 », « R' »).
  static Move parse(String text) {
    final t = text.trim();
    if (t.isEmpty || t.length > 2) {
      throw FormatException('Mouvement invalide : "$text"');
    }
    final face = Face.values.where((f) => f.letter == t[0]);
    if (face.isEmpty) throw FormatException('Mouvement invalide : "$text"');
    if (t.length == 1) return Move(face.first, 1);
    return switch (t[1]) {
      '2' => Move(face.first, 2),
      "'" || '’' => Move(face.first, 3),
      _ => throw FormatException('Mouvement invalide : "$text"'),
    };
  }

  /// Analyse une séquence séparée par des espaces (« R U R' U' »).
  static List<Move> parseSequence(String text) =>
      text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).map(parse).toList();

  static String formatSequence(Iterable<Move> moves) =>
      moves.map((m) => m.notation).join(' ');

  @override
  bool operator ==(Object other) =>
      other is Move && other.face == face && other.turns == turns;

  @override
  int get hashCode => index;

  @override
  String toString() => notation;
}
