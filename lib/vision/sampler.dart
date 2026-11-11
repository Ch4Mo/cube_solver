import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'color_classifier.dart';

/// Taille du carré de visée, en fraction du plus petit côté de l'image.
/// Doit correspondre à la grille dessinée par-dessus l'aperçu de la caméra.
const double gridFraction = 0.7;

/// Paramètres d'échantillonnage, transmissibles à un isolate.
class SampleRequest {
  const SampleRequest(this.bytes, {this.fraction = gridFraction});

  /// Image encodée (JPEG, PNG…), telle que renvoyée par la caméra.
  final Uint8List bytes;
  final double fraction;
}

/// Décode une photo et mesure la couleur des 9 cases de la grille de visée.
///
/// À lancer dans un isolate (`compute(sampleFacePhoto, request)`) : le
/// décodage d'une photo prend quelques centaines de millisecondes.
List<Rgb> sampleFacePhoto(SampleRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) {
    throw const FormatException('Impossible de lire la photo.');
  }
  // Applique l'orientation EXIF (photo prise en portrait).
  final image = img.bakeOrientation(decoded);
  return sampleGrid(image, fraction: request.fraction);
}

/// Mesure les 9 cases d'une grille 3×3 centrée, de côté
/// `fraction × min(largeur, hauteur)`.
///
/// Pour chaque case, on prend la médiane des pixels de sa zone centrale
/// (la moitié de la case), ce qui ignore les bords noirs et la plupart des
/// reflets.
List<Rgb> sampleGrid(img.Image image, {double fraction = gridFraction}) {
  final side =
      fraction * (image.width < image.height ? image.width : image.height);
  final left = (image.width - side) / 2;
  final top = (image.height - side) / 2;
  final cell = side / 3;
  // Échantillonne au plus ~400 pixels par case pour rester rapide.
  final zone = cell * 0.5;
  final step = (zone / 20).clamp(1, 1000).toInt();

  final result = <Rgb>[];
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      final cx = left + cell * (col + 0.5);
      final cy = top + cell * (row + 0.5);
      final rs = <int>[], gs = <int>[], bs = <int>[];
      for (var y = (cy - zone / 2).round(); y < cy + zone / 2; y += step) {
        for (var x = (cx - zone / 2).round(); x < cx + zone / 2; x += step) {
          if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
            continue;
          }
          final p = image.getPixel(x, y);
          rs.add(p.r.toInt());
          gs.add(p.g.toInt());
          bs.add(p.b.toInt());
        }
      }
      result.add(Rgb(_median(rs), _median(gs), _median(bs)));
    }
  }
  return result;
}

int _median(List<int> values) {
  if (values.isEmpty) return 0;
  values.sort();
  return values[values.length ~/ 2];
}
