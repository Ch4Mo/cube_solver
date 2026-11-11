import 'dart:math';

import '../cube/definitions.dart';

/// Une couleur mesurée sur une photo (composantes 0..255).
class Rgb {
  const Rgb(this.r, this.g, this.b);

  final int r, g, b;

  /// Conversion vers l'espace CIELAB (illuminant D65), plus proche de la
  /// perception humaine que le RGB.
  Lab toLab() {
    double lin(int c) {
      final v = c / 255.0;
      return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) as double;
    }

    final rl = lin(r), gl = lin(g), bl = lin(b);
    final x = (rl * 0.4124 + gl * 0.3576 + bl * 0.1805) / 0.95047;
    final y = (rl * 0.2126 + gl * 0.7152 + bl * 0.0722) / 1.0;
    final z = (rl * 0.0193 + gl * 0.1192 + bl * 0.9505) / 1.08883;
    double f(double t) =>
        t > 0.008856 ? pow(t, 1 / 3) as double : 7.787 * t + 16 / 116;
    final fx = f(x), fy = f(y), fz = f(z);
    return Lab(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  @override
  String toString() => 'Rgb($r, $g, $b)';
}

/// Couleur dans l'espace CIELAB.
class Lab {
  const Lab(this.l, this.a, this.b);

  final double l, a, b;

  double get chroma => sqrt(a * a + b * b);

  /// Teinte en degrés (0..360).
  double get hue => (atan2(b, a) * 180 / pi + 360) % 360;

  double distanceTo(Lab o) {
    final dl = l - o.l, da = a - o.a, db = b - o.b;
    return sqrt(dl * dl + da * da + db * db);
  }

  @override
  String toString() =>
      'Lab(${l.toStringAsFixed(1)}, ${a.toStringAsFixed(1)}, '
      '${b.toStringAsFixed(1)})';
}

/// Couleurs « idéales » des autocollants, utilisées pour nommer les centres.
const Map<CubeColor, Rgb> prototypeColors = {
  CubeColor.white: Rgb(235, 235, 235),
  CubeColor.yellow: Rgb(240, 220, 30),
  CubeColor.green: Rgb(20, 160, 70),
  CubeColor.blue: Rgb(20, 80, 200),
  CubeColor.red: Rgb(200, 25, 35),
  CubeColor.orange: Rgb(250, 120, 20),
};

/// Résultat de la classification des 54 cases.
class ClassificationResult {
  const ClassificationResult(this.colors, this.references, this.confidence);

  /// Couleur attribuée à chaque case.
  final List<CubeColor> colors;

  /// Couleur mesurée (Lab) de référence pour chaque couleur : celle du centre
  /// correspondant. Sert à reconnaître une face isolée plus tard.
  final Map<CubeColor, Lab> references;

  /// Pour chaque case, écart entre la meilleure et la deuxième couleur
  /// possible (plus c'est grand, plus la détection est sûre).
  final List<double> confidence;

  /// Cases dont la couleur est incertaine (à vérifier par l'utilisateur).
  List<int> get uncertain => [
    for (var i = 0; i < 54; i++)
      if (i % 9 != 4 && confidence[i] < 8) i,
  ];
}

/// Distance adaptée aux autocollants : on pondère moins la luminosité, très
/// sensible à l'éclairage, et davantage la teinte (rouge / orange).
double stickerDistance(Lab x, Lab y) {
  final dl = (x.l - y.l) * 0.5;
  final da = x.a - y.a, db = x.b - y.b;
  return sqrt(dl * dl + da * da + db * db);
}

/// Attribue une couleur aux 6 centres, en associant chaque centre à un
/// prototype différent (meilleure des 720 permutations).
Map<int, CubeColor> nameCenters(List<Lab> centers) {
  assert(centers.length == 6);
  final protos = [
    for (final c in CubeColor.values) prototypeColors[c]!.toLab(),
  ];
  var best = <int>[];
  var bestCost = double.infinity;
  void permute(List<int> current, List<bool> used, double cost) {
    if (cost >= bestCost) return;
    if (current.length == 6) {
      best = List.of(current);
      bestCost = cost;
      return;
    }
    final i = current.length;
    for (var p = 0; p < 6; p++) {
      if (used[p]) continue;
      used[p] = true;
      current.add(p);
      permute(current, used, cost + stickerDistance(centers[i], protos[p]));
      current.removeLast();
      used[p] = false;
    }
  }

  permute([], List.filled(6, false), 0);
  return {for (var i = 0; i < 6; i++) i: CubeColor.values[best[i]]};
}

/// Classe les 54 couleurs mesurées (dans l'ordre URFDLB de
/// `definitions.dart`).
///
/// Les centres servent de référence : chaque case est comparée aux couleurs
/// réellement mesurées des centres, dans les mêmes conditions d'éclairage.
/// L'attribution respecte la contrainte « 9 cases par couleur » : on
/// attribue d'abord les cases les plus sûres.
ClassificationResult classifyCube(List<Rgb> samples) {
  if (samples.length != 54) {
    throw ArgumentError('54 couleurs attendues, ${samples.length} reçues.');
  }
  final labs = [for (final s in samples) s.toLab()];
  final centerLabs = [for (final f in Face.values) labs[f.centerIndex]];
  final names = nameCenters(centerLabs);
  final refs = <CubeColor, Lab>{
    for (var i = 0; i < 6; i++) names[i]!: centerLabs[i],
  };

  final result = List<CubeColor?>.filled(54, null);
  final remaining = {for (final c in CubeColor.values) c: 8};
  for (final f in Face.values) {
    result[f.centerIndex] = names[f.index];
  }

  final confidence = List<double>.filled(54, 100);
  // Toutes les paires (case, couleur) triées par distance croissante.
  final pairs = <(double, int, CubeColor)>[];
  for (var i = 0; i < 54; i++) {
    if (i % 9 == 4) continue;
    final dists = [
      for (final c in CubeColor.values) (stickerDistance(labs[i], refs[c]!), c),
    ]..sort((x, y) => x.$1.compareTo(y.$1));
    confidence[i] = dists[1].$1 - dists[0].$1;
    for (final d in dists) {
      pairs.add((d.$1, i, d.$2));
    }
  }
  pairs.sort((x, y) => x.$1.compareTo(y.$1));
  for (final (_, i, c) in pairs) {
    if (result[i] != null || remaining[c] == 0) continue;
    result[i] = c;
    remaining[c] = remaining[c]! - 1;
  }

  return ClassificationResult(result.cast<CubeColor>(), refs, confidence);
}

/// Classe les 9 cases d'une seule face à l'aide de couleurs de référence
/// (mesurées lors du scan complet, ou prototypes par défaut).
List<CubeColor> classifyFace(List<Rgb> samples, [Map<CubeColor, Lab>? refs]) {
  final references =
      refs ?? {for (final e in prototypeColors.entries) e.key: e.value.toLab()};
  return [
    for (final s in samples)
      () {
        final lab = s.toLab();
        CubeColor? best;
        var bestD = double.infinity;
        for (final e in references.entries) {
          final d = stickerDistance(lab, e.value);
          if (d < bestD) {
            bestD = d;
            best = e.key;
          }
        }
        return best!;
      }(),
  ];
}
