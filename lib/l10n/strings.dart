/// Textes de l'application en français, anglais et espagnol.
///
/// Pur Dart (sans Flutter) : utilisable par la logique du cube (messages de
/// validation, consignes…) comme par l'interface. La langue active est
/// [Strings.current], mise à jour par l'application (voir `l10n_scope.dart`).
library;

import '../cube/definitions.dart';

/// Langues disponibles.
enum AppLanguage {
  fr('Français'),
  en('English'),
  es('Español');

  const AppLanguage(this.nativeName);

  /// Nom de la langue dans cette langue (pour le sélecteur).
  final String nativeName;

  /// Langue correspondant à un code (« fr », « en-US »…), ou `null`.
  static AppLanguage? fromCode(String? code) {
    if (code == null) return null;
    final short = code.split(RegExp('[-_]')).first.toLowerCase();
    for (final l in values) {
      if (l.name == short) return l;
    }
    return null;
  }
}

abstract class Strings {
  const Strings();

  /// Langue active. Le français est la langue par défaut (et celle des tests).
  static Strings current = const StringsFr();

  static Strings of(AppLanguage language) => switch (language) {
    AppLanguage.fr => const StringsFr(),
    AppLanguage.en => const StringsEn(),
    AppLanguage.es => const StringsEs(),
  };

  AppLanguage get language;

  // --- Vocabulaire du cube --------------------------------------------------

  /// Nom d'une couleur, avec majuscule (« Rouge »).
  String colorName(CubeColor c);

  /// Nom d'une face (« avant », « front »…), sans article.
  String faceName(Face f);

  /// Couleur en minuscules, accordée au mot « centre ».
  String centerColor(CubeColor c) => colorName(c).toLowerCase();

  // --- Accueil ---------------------------------------------------------------

  String get tagline;
  String get stepScan;
  String get stepCheck;
  String get stepSolve;
  String get scanMyCube;
  String get enterColors;
  String get about;
  String get languageLabel;

  /// Libellé du choix « langue du téléphone ».
  String get systemLanguage;

  // --- À propos ---------------------------------------------------------------

  String get appDescription;
  String version(String v);
  String get privacyPolicy;
  String get adPreferences;
  String get adPreferencesSubtitle;
  String get licenses;

  // --- Saisie ------------------------------------------------------------------

  String get inputTitle;
  String get moreOptions;
  String get clearAll;
  String get fillRandom;
  String get detectedAllGood;
  String detectedUncertain(int n);
  String faceProgress(int index, Face f);
  String orientationHint(CubeColor center, CubeColor top);
  String get previousFace;
  String get nextFace;
  String get overviewHint;
  String get solve;
  String paletteLabel(CubeColor c, int count);
  String cellsRemaining(int n);
  String colorOverused(CubeColor c);
  String get cubeValid;
  String cellLabel(int k, CubeColor? c);
  String faceLabel(Face f);

  // --- Messages de validation ---------------------------------------------------

  String wrongFaceletCount(int n);
  String wrongColorCount(String detail);
  String duplicateCenter(String a, String b, CubeColor c);
  String invalidCorner(String position);
  String invalidEdge(String position);
  String duplicateCorner(String name, int n);
  String duplicateEdge(String name, int n);
  String twistedCorner({required bool clockwise});
  String get flippedEdge;
  String get swappedPieces;
  String get noSolutionInTime;

  // --- Scan ---------------------------------------------------------------------

  String scanTitle(int index);
  String get verifyTitle;
  String faceTitle(Face f);
  String scanInstruction(Face f);
  String get verifyInstruction;
  String get placeInGrid;
  String get analyzeColors;
  String get takePhoto;
  String get scannedFaces;
  String get retry;
  String get torchOn;
  String get torchOff;
  String get noCamera;
  String get cameraDenied;
  String cameraError(String code);
  String photoFailed(String error);
  String similarCenter(Face f);

  // --- Solution -----------------------------------------------------------------

  String get solutionTitle;
  String get computing;
  String holdCube(CubeColor front, CubeColor top);
  String get alreadySolved;
  String solvedIn(int n);
  String describeMove(Face f, int turns, CubeColor? color);
  String stepOf(int step, int total);
  String get previousMove;
  String get nextMove;
  String get verifyWithPhoto;
  String get verifyMyCube;
  String get showAllFaces;
  String get hideAllFaces;
  String get allGood;
  String get cubeMismatch;
  String get expected;
  String get photo;
  String goToStep(int step);
  String get ignore;
  String get rescan;
  String get continueLabel;
  String get progressOk;
  String movesMissing(int n, int step);
  String movesExtra(int n, int step);
  String pieceMoved(int cells);
  String cube3dLabel(String? move);
}

// =============================================================================
// Français
// =============================================================================

class StringsFr extends Strings {
  const StringsFr();

  @override
  AppLanguage get language => AppLanguage.fr;

  @override
  String colorName(CubeColor c) => switch (c) {
    CubeColor.white => 'Blanc',
    CubeColor.yellow => 'Jaune',
    CubeColor.green => 'Vert',
    CubeColor.blue => 'Bleu',
    CubeColor.red => 'Rouge',
    CubeColor.orange => 'Orange',
  };

  @override
  String faceName(Face f) => switch (f) {
    Face.U => 'haut',
    Face.D => 'bas',
    Face.F => 'avant',
    Face.B => 'arrière',
    Face.R => 'droite',
    Face.L => 'gauche',
  };

  @override
  String get tagline =>
      'Scannez votre cube 3×3,\nsuivez le guide, il est résolu.';
  @override
  String get stepScan => 'Scannez';
  @override
  String get stepCheck => 'Vérifiez';
  @override
  String get stepSolve => 'Résolvez';
  @override
  String get scanMyCube => 'Scanner mon cube';
  @override
  String get enterColors => 'Saisir les couleurs';
  @override
  String get about => 'À propos';
  @override
  String get languageLabel => 'Langue';
  @override
  String get systemLanguage => 'Langue du téléphone';

  @override
  String get appDescription => 'Aide à la résolution du cube 3×3';
  @override
  String version(String v) => 'Version $v';
  @override
  String get privacyPolicy => 'Politique de confidentialité';
  @override
  String get adPreferences => 'Préférences publicitaires';
  @override
  String get adPreferencesSubtitle => 'Modifier votre consentement';
  @override
  String get licenses => 'Licences des logiciels utilisés';

  @override
  String get inputTitle => 'Saisie des couleurs';
  @override
  String get moreOptions => "Plus d'options";
  @override
  String get clearAll => 'Tout effacer';
  @override
  String get fillRandom => 'Remplir avec un cube mélangé';
  @override
  String get detectedAllGood =>
      'Couleurs détectées. Vérifiez chaque face et corrigez si besoin.';
  @override
  String detectedUncertain(int n) =>
      'Couleurs détectées. Vérifiez chaque face : $n case(s) incertaine(s) '
      'sont entourées en orange.';
  @override
  String faceProgress(int index, Face f) => 'Face $index/6 : ${faceName(f)}';
  @override
  String orientationHint(CubeColor center, CubeColor top) =>
      'Centre ${centerColor(center)} face à vous, '
      'centre ${centerColor(top)} en haut.';
  @override
  String get previousFace => 'Face précédente';
  @override
  String get nextFace => 'Face suivante';
  @override
  String get overviewHint =>
      "Vue d'ensemble (touchez une face pour la modifier)";
  @override
  String get solve => 'Résoudre';
  @override
  String paletteLabel(CubeColor c, int count) =>
      '${colorName(c)}, $count sur 9';
  @override
  String cellsRemaining(int n) => '$n case(s) restante(s).';
  @override
  String colorOverused(CubeColor c) =>
      '${colorName(c)} : plus de 9 cases, vérifiez cette couleur.';
  @override
  String get cubeValid => 'Cube valide, prêt à être résolu.';
  @override
  String cellLabel(int k, CubeColor? c) =>
      'Case $k : ${c == null ? 'vide' : colorName(c)}';
  @override
  String faceLabel(Face f) => 'Face ${faceName(f)}';

  @override
  String wrongFaceletCount(int n) =>
      'Il faut 54 cases (6 faces × 9), $n reçues.';
  @override
  String wrongColorCount(String detail) =>
      'Chaque couleur doit apparaître 9 fois ($detail). Vérifiez les couleurs.';
  @override
  String duplicateCenter(String a, String b, CubeColor c) =>
      'Les faces $a et $b ont le même centre (${colorName(c)}).';
  @override
  String invalidCorner(String position) =>
      'Le coin en position $position a une combinaison de couleurs '
      'impossible. Vérifiez les couleurs.';
  @override
  String invalidEdge(String position) =>
      "L'arête en position $position a une combinaison de couleurs "
      'impossible. Vérifiez les couleurs.';
  @override
  String duplicateCorner(String name, int n) =>
      'Le coin $name apparaît $n fois.';
  @override
  String duplicateEdge(String name, int n) => "L'arête $name apparaît $n fois.";
  @override
  String twistedCorner({required bool clockwise}) =>
      'Un coin a été tourné sur lui-même (dans le sens '
      '${clockwise ? 'horaire' : 'anti-horaire'}). Le cube ne peut pas être '
      "résolu tant que ce coin n'est pas remis dans le bon sens.";
  @override
  String get flippedEdge =>
      'Une arête a été retournée. Le cube ne peut pas être résolu tant '
      "qu'elle n'est pas remise dans le bon sens.";
  @override
  String get swappedPieces =>
      'Deux pièces ont été échangées (cube démonté ou autocollants '
      "déplacés). Le cube ne peut pas être résolu en l'état.";
  @override
  String get noSolutionInTime =>
      'Aucune solution trouvée dans le temps imparti.';

  @override
  String scanTitle(int index) => 'Scanner : face $index/6';
  @override
  String get verifyTitle => 'Vérification';
  @override
  String faceTitle(Face f) => 'Face ${faceName(f)}';
  @override
  String scanInstruction(Face f) => switch (f) {
    Face.F =>
      'Tenez le cube avec le centre vert face à vous et le centre '
          'blanc en haut.',
    Face.R =>
      "Tournez le cube d'un quart de tour vers la gauche : centre "
          'rouge face à vous, blanc toujours en haut.',
    Face.B =>
      'Encore un quart de tour vers la gauche : centre bleu face à '
          'vous, blanc en haut.',
    Face.L =>
      'Encore un quart de tour vers la gauche : centre orange face à '
          'vous, blanc en haut.',
    Face.U =>
      'Revenez au vert face à vous, puis basculez le haut du cube vers '
          'vous : centre blanc face à vous, bleu en haut.',
    Face.D =>
      'Revenez au vert face à vous, puis basculez le bas du cube vers '
          'vous : centre jaune face à vous, vert en haut.',
  };
  @override
  String get verifyInstruction =>
      'Photographiez la face qui est face à vous, sans tourner le cube.';
  @override
  String get placeInGrid =>
      'Placez la face dans la grille, bien de face, sans reflet.';
  @override
  String get analyzeColors => 'Analyser les couleurs';
  @override
  String get takePhoto => 'Prendre la photo';
  @override
  String get scannedFaces =>
      'Faces scannées (touchez une face pour la refaire)';
  @override
  String get retry => 'Réessayer';
  @override
  String get torchOn => 'Allumer la lampe';
  @override
  String get torchOff => 'Éteindre la lampe';
  @override
  String get noCamera => 'Aucun appareil photo disponible.';
  @override
  String get cameraDenied =>
      "L'accès à l'appareil photo a été refusé. Autorisez-le dans les "
      'réglages du téléphone, ou saisissez les couleurs à la main.';
  @override
  String cameraError(String code) =>
      "Impossible d'ouvrir l'appareil photo ($code).";
  @override
  String photoFailed(String error) => 'La photo a échoué : $error';
  @override
  String similarCenter(Face f) =>
      'Le centre de cette face ressemble à celui de la face ${faceName(f)}. '
      'Avez-vous bien tourné le cube ?';

  @override
  String get solutionTitle => 'Solution';
  @override
  String get computing => 'Calcul de la solution…';
  @override
  String holdCube(CubeColor front, CubeColor top) =>
      'Gardez le centre ${centerColor(front)} face à vous et le centre '
      '${centerColor(top)} en haut pendant toute la résolution.';
  @override
  String get alreadySolved => 'Le cube est déjà résolu !';
  @override
  String solvedIn(int n) => 'Bravo, cube résolu en $n mouvements !';
  @override
  String describeMove(Face f, int turns, CubeColor? color) {
    final face = color == null
        ? 'la face ${faceName(f)}'
        : 'la face ${faceName(f)} (${centerColor(color)})';
    final turn = switch (turns) {
      1 => "d'un quart de tour dans le sens horaire",
      2 => "d'un demi-tour",
      _ => "d'un quart de tour dans le sens anti-horaire",
    };
    return 'Tournez $face $turn.';
  }

  @override
  String stepOf(int step, int total) => 'Étape $step / $total';
  @override
  String get previousMove => 'Mouvement précédent';
  @override
  String get nextMove => 'Mouvement suivant';
  @override
  String get verifyWithPhoto => 'Vérifier avec une photo';
  @override
  String get verifyMyCube => 'Vérifier mon cube avec une photo';
  @override
  String get showAllFaces => 'Voir toutes les faces';
  @override
  String get hideAllFaces => 'Masquer toutes les faces';
  @override
  String get allGood => 'Tout va bien';
  @override
  String get cubeMismatch => 'Le cube ne correspond pas';
  @override
  String get expected => 'Attendu';
  @override
  String get photo => 'Photo';
  @override
  String goToStep(int step) => "Aller à l'étape $step";
  @override
  String get ignore => 'Ignorer';
  @override
  String get rescan => 'Rescanner le cube';
  @override
  String get continueLabel => 'Continuer';
  @override
  String get progressOk => 'Tout est correct, continuez !';
  @override
  String movesMissing(int n, int step) =>
      "Il semble manquer $n mouvement(s) : reprenez à l'étape $step.";
  @override
  String movesExtra(int n, int step) =>
      "Il semble y avoir $n mouvement(s) en trop : reprenez à l'étape $step.";
  @override
  String pieceMoved(int cells) =>
      'Le cube ne correspond plus à la solution ($cells case(s) '
      'différente(s)). Une pièce a probablement été bougée : scannez à '
      'nouveau le cube pour recalculer une solution.';
  @override
  String cube3dLabel(String? move) =>
      move == null ? 'Vue 3D du cube' : 'Vue 3D du cube, mouvement $move';
}

// =============================================================================
// English
// =============================================================================

class StringsEn extends Strings {
  const StringsEn();

  @override
  AppLanguage get language => AppLanguage.en;

  @override
  String colorName(CubeColor c) => switch (c) {
    CubeColor.white => 'White',
    CubeColor.yellow => 'Yellow',
    CubeColor.green => 'Green',
    CubeColor.blue => 'Blue',
    CubeColor.red => 'Red',
    CubeColor.orange => 'Orange',
  };

  @override
  String faceName(Face f) => switch (f) {
    Face.U => 'top',
    Face.D => 'bottom',
    Face.F => 'front',
    Face.B => 'back',
    Face.R => 'right',
    Face.L => 'left',
  };

  @override
  String get tagline => 'Scan your 3×3 cube,\nfollow the guide, it’s solved.';
  @override
  String get stepScan => 'Scan';
  @override
  String get stepCheck => 'Check';
  @override
  String get stepSolve => 'Solve';
  @override
  String get scanMyCube => 'Scan my cube';
  @override
  String get enterColors => 'Enter the colours';
  @override
  String get about => 'About';
  @override
  String get languageLabel => 'Language';
  @override
  String get systemLanguage => 'Phone language';

  @override
  String get appDescription => '3×3 cube solving helper';
  @override
  String version(String v) => 'Version $v';
  @override
  String get privacyPolicy => 'Privacy policy';
  @override
  String get adPreferences => 'Ad preferences';
  @override
  String get adPreferencesSubtitle => 'Change your consent';
  @override
  String get licenses => 'Open-source licences';

  @override
  String get inputTitle => 'Cube colours';
  @override
  String get moreOptions => 'More options';
  @override
  String get clearAll => 'Clear all';
  @override
  String get fillRandom => 'Fill with a scrambled cube';
  @override
  String get detectedAllGood =>
      'Colours detected. Check each face and correct if needed.';
  @override
  String detectedUncertain(int n) =>
      'Colours detected. Check each face: $n uncertain '
      '${n == 1 ? 'square is' : 'squares are'} circled in orange.';
  @override
  String faceProgress(int index, Face f) => 'Face $index/6: ${faceName(f)}';
  @override
  String orientationHint(CubeColor center, CubeColor top) =>
      '${colorName(center)} centre facing you, '
      '${centerColor(top)} centre on top.';
  @override
  String get previousFace => 'Previous face';
  @override
  String get nextFace => 'Next face';
  @override
  String get overviewHint => 'Overview (tap a face to edit it)';
  @override
  String get solve => 'Solve';
  @override
  String paletteLabel(CubeColor c, int count) => '${colorName(c)}, $count of 9';
  @override
  String cellsRemaining(int n) => '$n ${n == 1 ? 'square' : 'squares'} left.';
  @override
  String colorOverused(CubeColor c) =>
      '${colorName(c)}: more than 9 squares, check this colour.';
  @override
  String get cubeValid => 'Valid cube, ready to be solved.';
  @override
  String cellLabel(int k, CubeColor? c) =>
      'Square $k: ${c == null ? 'empty' : colorName(c)}';
  @override
  String faceLabel(Face f) => '${_cap(faceName(f))} face';

  @override
  String wrongFaceletCount(int n) =>
      '54 squares are needed (6 faces × 9), $n received.';
  @override
  String wrongColorCount(String detail) =>
      'Each colour must appear 9 times ($detail). Check the colours.';
  @override
  String duplicateCenter(String a, String b, CubeColor c) =>
      'Faces $a and $b have the same centre (${colorName(c)}).';
  @override
  String invalidCorner(String position) =>
      'The corner at position $position has an impossible colour '
      'combination. Check the colours.';
  @override
  String invalidEdge(String position) =>
      'The edge at position $position has an impossible colour '
      'combination. Check the colours.';
  @override
  String duplicateCorner(String name, int n) =>
      'Corner $name appears $n times.';
  @override
  String duplicateEdge(String name, int n) => 'Edge $name appears $n times.';
  @override
  String twistedCorner({required bool clockwise}) =>
      'A corner has been twisted in place '
      '(${clockwise ? 'clockwise' : 'counter-clockwise'}). The cube cannot '
      'be solved until this corner is turned back.';
  @override
  String get flippedEdge =>
      'An edge has been flipped. The cube cannot be solved until it is '
      'flipped back.';
  @override
  String get swappedPieces =>
      'Two pieces have been swapped (cube taken apart or stickers moved). '
      'The cube cannot be solved as it is.';
  @override
  String get noSolutionInTime => 'No solution found in the allowed time.';

  @override
  String scanTitle(int index) => 'Scan: face $index/6';
  @override
  String get verifyTitle => 'Check';
  @override
  String faceTitle(Face f) => '${_cap(faceName(f))} face';
  @override
  String scanInstruction(Face f) => switch (f) {
    Face.F =>
      'Hold the cube with the green centre facing you and the white '
          'centre on top.',
    Face.R =>
      'Turn the cube a quarter turn to the left: red centre facing '
          'you, white still on top.',
    Face.B =>
      'Another quarter turn to the left: blue centre facing you, '
          'white on top.',
    Face.L =>
      'Another quarter turn to the left: orange centre facing you, '
          'white on top.',
    Face.U =>
      'Go back to green facing you, then tilt the top of the cube '
          'towards you: white centre facing you, blue on top.',
    Face.D =>
      'Go back to green facing you, then tilt the bottom of the cube '
          'towards you: yellow centre facing you, green on top.',
  };
  @override
  String get verifyInstruction =>
      'Take a photo of the face in front of you, without turning the cube.';
  @override
  String get placeInGrid =>
      'Fit the face in the grid, straight on, without glare.';
  @override
  String get analyzeColors => 'Analyse the colours';
  @override
  String get takePhoto => 'Take the photo';
  @override
  String get scannedFaces => 'Scanned faces (tap a face to redo it)';
  @override
  String get retry => 'Retry';
  @override
  String get torchOn => 'Turn on the light';
  @override
  String get torchOff => 'Turn off the light';
  @override
  String get noCamera => 'No camera available.';
  @override
  String get cameraDenied =>
      'Camera access was denied. Allow it in the phone settings, or enter '
      'the colours by hand.';
  @override
  String cameraError(String code) => 'Could not open the camera ($code).';
  @override
  String photoFailed(String error) => 'The photo failed: $error';
  @override
  String similarCenter(Face f) =>
      'The centre of this face looks like the ${faceName(f)} face. '
      'Did you turn the cube?';

  @override
  String get solutionTitle => 'Solution';
  @override
  String get computing => 'Computing the solution…';
  @override
  String holdCube(CubeColor front, CubeColor top) =>
      'Keep the ${centerColor(front)} centre facing you and the '
      '${centerColor(top)} centre on top for the whole solve.';
  @override
  String get alreadySolved => 'The cube is already solved!';
  @override
  String solvedIn(int n) => 'Well done, cube solved in $n moves!';
  @override
  String describeMove(Face f, int turns, CubeColor? color) {
    final face = color == null
        ? 'the ${faceName(f)} face'
        : 'the ${faceName(f)} face (${centerColor(color)})';
    final turn = switch (turns) {
      1 => 'a quarter turn clockwise',
      2 => 'a half turn',
      _ => 'a quarter turn counter-clockwise',
    };
    return 'Turn $face $turn.';
  }

  @override
  String stepOf(int step, int total) => 'Step $step / $total';
  @override
  String get previousMove => 'Previous move';
  @override
  String get nextMove => 'Next move';
  @override
  String get verifyWithPhoto => 'Check with a photo';
  @override
  String get verifyMyCube => 'Check my cube with a photo';
  @override
  String get showAllFaces => 'Show all faces';
  @override
  String get hideAllFaces => 'Hide all faces';
  @override
  String get allGood => 'All good';
  @override
  String get cubeMismatch => 'The cube does not match';
  @override
  String get expected => 'Expected';
  @override
  String get photo => 'Photo';
  @override
  String goToStep(int step) => 'Go to step $step';
  @override
  String get ignore => 'Ignore';
  @override
  String get rescan => 'Rescan the cube';
  @override
  String get continueLabel => 'Continue';
  @override
  String get progressOk => 'Everything is correct, carry on!';
  @override
  String movesMissing(int n, int step) =>
      'It looks like $n ${n == 1 ? 'move is' : 'moves are'} missing: '
      'resume at step $step.';
  @override
  String movesExtra(int n, int step) =>
      'It looks like $n extra ${n == 1 ? 'move was' : 'moves were'} made: '
      'resume at step $step.';
  @override
  String pieceMoved(int cells) =>
      'The cube no longer matches the solution ($cells different '
      '${cells == 1 ? 'square' : 'squares'}). A piece was probably moved: '
      'scan the cube again to compute a new solution.';
  @override
  String cube3dLabel(String? move) =>
      move == null ? '3D view of the cube' : '3D view of the cube, move $move';
}

// =============================================================================
// Español
// =============================================================================

class StringsEs extends Strings {
  const StringsEs();

  @override
  AppLanguage get language => AppLanguage.es;

  @override
  String colorName(CubeColor c) => switch (c) {
    CubeColor.white => 'Blanco',
    CubeColor.yellow => 'Amarillo',
    CubeColor.green => 'Verde',
    CubeColor.blue => 'Azul',
    CubeColor.red => 'Rojo',
    CubeColor.orange => 'Naranja',
  };

  @override
  String faceName(Face f) => switch (f) {
    Face.U => 'superior',
    Face.D => 'inferior',
    Face.F => 'frontal',
    Face.B => 'trasera',
    Face.R => 'derecha',
    Face.L => 'izquierda',
  };

  @override
  String get tagline =>
      'Escanea tu cubo 3×3,\nsigue la guía y quedará resuelto.';
  @override
  String get stepScan => 'Escanea';
  @override
  String get stepCheck => 'Verifica';
  @override
  String get stepSolve => 'Resuelve';
  @override
  String get scanMyCube => 'Escanear mi cubo';
  @override
  String get enterColors => 'Introducir los colores';
  @override
  String get about => 'Acerca de';
  @override
  String get languageLabel => 'Idioma';
  @override
  String get systemLanguage => 'Idioma del teléfono';

  @override
  String get appDescription => 'Ayuda para resolver el cubo 3×3';
  @override
  String version(String v) => 'Versión $v';
  @override
  String get privacyPolicy => 'Política de privacidad';
  @override
  String get adPreferences => 'Preferencias de anuncios';
  @override
  String get adPreferencesSubtitle => 'Cambiar tu consentimiento';
  @override
  String get licenses => 'Licencias de software';

  @override
  String get inputTitle => 'Colores del cubo';
  @override
  String get moreOptions => 'Más opciones';
  @override
  String get clearAll => 'Borrar todo';
  @override
  String get fillRandom => 'Rellenar con un cubo mezclado';
  @override
  String get detectedAllGood =>
      'Colores detectados. Revisa cada cara y corrige si es necesario.';
  @override
  String detectedUncertain(int n) =>
      'Colores detectados. Revisa cada cara: $n '
      '${n == 1 ? 'casilla dudosa está rodeada' : 'casillas dudosas están rodeadas'}'
      ' en naranja.';
  @override
  String faceProgress(int index, Face f) => 'Cara $index/6: ${faceName(f)}';
  @override
  String orientationHint(CubeColor center, CubeColor top) =>
      'Centro ${centerColor(center)} hacia ti, '
      'centro ${centerColor(top)} arriba.';
  @override
  String get previousFace => 'Cara anterior';
  @override
  String get nextFace => 'Cara siguiente';
  @override
  String get overviewHint => 'Vista general (toca una cara para editarla)';
  @override
  String get solve => 'Resolver';
  @override
  String paletteLabel(CubeColor c, int count) => '${colorName(c)}, $count de 9';
  @override
  String cellsRemaining(int n) =>
      n == 1 ? 'Queda 1 casilla.' : 'Quedan $n casillas.';
  @override
  String colorOverused(CubeColor c) =>
      '${colorName(c)}: más de 9 casillas, revisa este color.';
  @override
  String get cubeValid => 'Cubo válido, listo para resolver.';
  @override
  String cellLabel(int k, CubeColor? c) =>
      'Casilla $k: ${c == null ? 'vacía' : colorName(c)}';
  @override
  String faceLabel(Face f) => 'Cara ${faceName(f)}';

  @override
  String wrongFaceletCount(int n) =>
      'Se necesitan 54 casillas (6 caras × 9), se recibieron $n.';
  @override
  String wrongColorCount(String detail) =>
      'Cada color debe aparecer 9 veces ($detail). Revisa los colores.';
  @override
  String duplicateCenter(String a, String b, CubeColor c) =>
      'Las caras $a y $b tienen el mismo centro (${colorName(c)}).';
  @override
  String invalidCorner(String position) =>
      'La esquina en la posición $position tiene una combinación de colores '
      'imposible. Revisa los colores.';
  @override
  String invalidEdge(String position) =>
      'La arista en la posición $position tiene una combinación de colores '
      'imposible. Revisa los colores.';
  @override
  String duplicateCorner(String name, int n) =>
      'La esquina $name aparece $n veces.';
  @override
  String duplicateEdge(String name, int n) =>
      'La arista $name aparece $n veces.';
  @override
  String twistedCorner({required bool clockwise}) =>
      'Una esquina ha sido girada sobre sí misma (en sentido '
      '${clockwise ? 'horario' : 'antihorario'}). El cubo no se puede '
      'resolver hasta que la esquina vuelva a su orientación correcta.';
  @override
  String get flippedEdge =>
      'Una arista ha sido volteada. El cubo no se puede resolver hasta que '
      'vuelva a su orientación correcta.';
  @override
  String get swappedPieces =>
      'Dos piezas han sido intercambiadas (cubo desmontado o pegatinas '
      'movidas). El cubo no se puede resolver tal como está.';
  @override
  String get noSolutionInTime =>
      'No se encontró ninguna solución en el tiempo previsto.';

  @override
  String scanTitle(int index) => 'Escanear: cara $index/6';
  @override
  String get verifyTitle => 'Verificación';
  @override
  String faceTitle(Face f) => 'Cara ${faceName(f)}';
  @override
  String scanInstruction(Face f) => switch (f) {
    Face.F =>
      'Sujeta el cubo con el centro verde hacia ti y el centro blanco '
          'arriba.',
    Face.R =>
      'Gira el cubo un cuarto de vuelta hacia la izquierda: centro '
          'rojo hacia ti, blanco siempre arriba.',
    Face.B =>
      'Otro cuarto de vuelta hacia la izquierda: centro azul hacia '
          'ti, blanco arriba.',
    Face.L =>
      'Otro cuarto de vuelta hacia la izquierda: centro naranja '
          'hacia ti, blanco arriba.',
    Face.U =>
      'Vuelve al verde hacia ti y después inclina la parte superior '
          'del cubo hacia ti: centro blanco hacia ti, azul arriba.',
    Face.D =>
      'Vuelve al verde hacia ti y después inclina la parte inferior '
          'del cubo hacia ti: centro amarillo hacia ti, verde arriba.',
  };
  @override
  String get verifyInstruction =>
      'Fotografía la cara que tienes delante, sin girar el cubo.';
  @override
  String get placeInGrid =>
      'Encaja la cara en la cuadrícula, de frente y sin reflejos.';
  @override
  String get analyzeColors => 'Analizar los colores';
  @override
  String get takePhoto => 'Hacer la foto';
  @override
  String get scannedFaces => 'Caras escaneadas (toca una cara para repetirla)';
  @override
  String get retry => 'Reintentar';
  @override
  String get torchOn => 'Encender la linterna';
  @override
  String get torchOff => 'Apagar la linterna';
  @override
  String get noCamera => 'No hay ninguna cámara disponible.';
  @override
  String get cameraDenied =>
      'Se ha denegado el acceso a la cámara. Permítelo en los ajustes del '
      'teléfono o introduce los colores a mano.';
  @override
  String cameraError(String code) => 'No se pudo abrir la cámara ($code).';
  @override
  String photoFailed(String error) => 'La foto ha fallado: $error';
  @override
  String similarCenter(Face f) =>
      'El centro de esta cara se parece al de la cara ${faceName(f)}. '
      '¿Has girado el cubo?';

  @override
  String get solutionTitle => 'Solución';
  @override
  String get computing => 'Calculando la solución…';
  @override
  String holdCube(CubeColor front, CubeColor top) =>
      'Mantén el centro ${centerColor(front)} hacia ti y el centro '
      '${centerColor(top)} arriba durante toda la resolución.';
  @override
  String get alreadySolved => '¡El cubo ya está resuelto!';
  @override
  String solvedIn(int n) => '¡Enhorabuena, cubo resuelto en $n movimientos!';
  @override
  String describeMove(Face f, int turns, CubeColor? color) {
    final face = color == null
        ? 'la cara ${faceName(f)}'
        : 'la cara ${faceName(f)} (${centerColor(color)})';
    final turn = switch (turns) {
      1 => 'un cuarto de vuelta en sentido horario',
      2 => 'media vuelta',
      _ => 'un cuarto de vuelta en sentido antihorario',
    };
    return 'Gira $face $turn.';
  }

  @override
  String stepOf(int step, int total) => 'Paso $step / $total';
  @override
  String get previousMove => 'Movimiento anterior';
  @override
  String get nextMove => 'Movimiento siguiente';
  @override
  String get verifyWithPhoto => 'Verificar con una foto';
  @override
  String get verifyMyCube => 'Verificar mi cubo con una foto';
  @override
  String get showAllFaces => 'Ver todas las caras';
  @override
  String get hideAllFaces => 'Ocultar todas las caras';
  @override
  String get allGood => 'Todo bien';
  @override
  String get cubeMismatch => 'El cubo no coincide';
  @override
  String get expected => 'Esperado';
  @override
  String get photo => 'Foto';
  @override
  String goToStep(int step) => 'Ir al paso $step';
  @override
  String get ignore => 'Ignorar';
  @override
  String get rescan => 'Volver a escanear';
  @override
  String get continueLabel => 'Continuar';
  @override
  String get progressOk => '¡Todo correcto, sigue así!';
  @override
  String movesMissing(int n, int step) =>
      'Parece que ${n == 1 ? 'falta 1 movimiento' : 'faltan $n movimientos'}'
      ': continúa en el paso $step.';
  @override
  String movesExtra(int n, int step) =>
      'Parece que ${n == 1 ? 'sobra 1 movimiento' : 'sobran $n movimientos'}'
      ': continúa en el paso $step.';
  @override
  String pieceMoved(int cells) =>
      'El cubo ya no coincide con la solución ($cells '
      '${cells == 1 ? 'casilla diferente' : 'casillas diferentes'}). '
      'Probablemente se ha movido una pieza: vuelve a escanear el cubo para '
      'calcular una nueva solución.';
  @override
  String cube3dLabel(String? move) => move == null
      ? 'Vista 3D del cubo'
      : 'Vista 3D del cubo, movimiento $move';
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
