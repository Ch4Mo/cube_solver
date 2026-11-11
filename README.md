# Cube Solver

Application Android / iOS (Flutter) d'aide à la résolution du Rubik's Cube :
on photographie les 6 faces, l'application détecte les couleurs, vérifie que le
cube est valide (et signale une pièce manipulée), puis guide la résolution
mouvement par mouvement.

## Installer sur Android

Scannez ce QR code avec le téléphone, téléchargez le fichier puis ouvrez-le :

![QR code d'installation](dist/qr-code.png)

Lien direct :
<https://raw.githubusercontent.com/Ch4Mo/cube_solver/claude/pensive-hopper-1ljwb5/dist/cube-solver.apk>

Android demande d'autoriser l'installation d'applications « de sources
inconnues » pour le navigateur : c'est normal pour une application installée
hors du Play Store. Android 7.0 minimum.

L'APK est signé avec une clé de développement : pour installer une future
version, il faudra peut-être d'abord désinstaller celle-ci.

**iOS** : le code est prêt (autorisation caméra, icône), mais une installation
sur iPhone nécessite un Mac avec Xcode et un compte Apple Developer
(TestFlight ou installation directe depuis Xcode).

## Utilisation

1. **Accueil** : scanner le cube, saisir les couleurs à la main, ou essayer
   avec un cube mélangé au hasard.
2. **Scan** : 6 photos, dans l'ordre avant, droite, arrière, gauche, haut, bas.
   Une consigne indique comment tenir le cube pour chaque face. On place la
   face dans la grille, puis « Prendre la photo ». Les miniatures montrent les
   couleurs mesurées ; touchez-en une pour refaire la face. Une lampe peut être
   allumée en cas de faible éclairage. Si une face ressemble à une face déjà
   prise, l'application prévient (cube pas tourné ?).
3. **Vérification des couleurs** : les couleurs détectées s'affichent dans
   l'écran de saisie. Les cases incertaines sont entourées en orange, les
   erreurs en rouge. On corrige en choisissant une couleur dans la palette puis
   en touchant la case.
4. **Solution** : vue 3D du cube avec une flèche indiquant le mouvement à
   faire, notation (R, U'…) et explication en clair (« Tournez la face droite
   (rouge) d'un quart de tour dans le sens horaire »).
5. **Vérifier mon cube** : à tout moment, une photo de la face avant permet de
   contrôler que le cube correspond à l'étape en cours. L'application détecte
   un mouvement oublié ou en trop (et propose de se recaler), ou une pièce
   bougée (et propose de rescanner).

## Ce que la validation détecte

- une couleur qui n'apparaît pas exactement 9 fois (mauvaise détection) ;
- deux centres identiques ;
- un coin ou une arête aux couleurs impossibles (autocollant déplacé) ;
- une pièce en double ;
- **un coin tourné sur lui-même** (somme des orientations ≠ 0 mod 3) ;
- **une arête retournée** (somme des orientations impaire) ;
- **deux pièces échangées** (parités coins / arêtes différentes).

Les trois dernières erreurs sont des manipulations physiques
(`CubeError.isPhysicalTampering`) : le cube est alors impossible à résoudre par
des rotations normales.

## Détection des couleurs

- Chaque photo est recadrée sur la grille de visée (70 % du petit côté). Pour
  chaque case, on prend la médiane des pixels de sa zone centrale, ce qui
  ignore les bords noirs et les petits reflets.
- Les couleurs sont comparées dans l'espace CIELAB, en donnant moins de poids
  à la luminosité (sensible à l'éclairage).
- Les 6 centres servent de référence : chaque case est comparée aux centres
  mesurés dans les mêmes conditions. Les noms des centres sont déduits de leur
  couleur, donc les cubes à schéma de couleurs non standard fonctionnent.
- L'attribution respecte la contrainte « 9 cases par couleur » : les cases les
  plus sûres sont attribuées en premier.

## Solveur

Algorithme à deux phases de Kociemba. Les tables (~6 Mo) sont calculées au
premier appel (1 à 2 s), dans un isolate pour ne pas figer l'interface. Les
solutions font environ 20 coups en moyenne, 21 au maximum dans les tests.

## Structure

```
lib/cube/              Cœur logique en pur Dart (sans Flutter)
  definitions.dart     Faces, couleurs, numérotation des 54 cases
  moves.dart           Mouvements et notation (R, U2, F'…)
  cubie_cube.dart      Représentation par pièces + coordonnées
  validation.dart      Vérifie qu'un cube est réel et résoluble
  solver.dart          Algorithme à deux phases de Kociemba
  tracking.dart        Vérifie une face pendant la résolution
  cube_input.dart      Saisie en cours, consignes, textes en français
lib/vision/            Détection des couleurs
  sampler.dart         Mesure des 9 cases sur une photo
  color_classifier.dart Classification (Lab, centres de référence)
lib/ui/                Écrans Flutter (accueil, scan, saisie, solution, 3D)
test/                  Tests unitaires et d'interface
dist/                  APK Android et QR code d'installation
```

## Développement

```bash
flutter test
```

```bash
flutter run
```

Reconstruire l'APK (ARM 32 et 64 bits, soit la quasi-totalité des téléphones) :

```bash
flutter build apk --release --target-platform android-arm,android-arm64
```
