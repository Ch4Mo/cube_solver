# Cube Solver

Application Android / iOS (Flutter) d'aide à la résolution du Rubik's Cube :
on photographie les 6 faces, l'application détecte les couleurs, vérifie que le
cube est valide (et signale une pièce manipulée), puis affiche la solution pas
à pas.

## Avancement

| Étape | État |
|---|---|
| 1. Modèle du cube, validation, solveur, suivi | ✅ fait |
| 2. Saisie manuelle des couleurs | à faire |
| 3. Capture photo + détection des couleurs | à faire |
| 4. Affichage de la solution en 3D | à faire |
| 5. Vérification en cours de résolution (photo) | logique faite, écran à faire |

L'écran actuel est une démo : « Mélanger » génère un cube aléatoire, et
« Résoudre » calcule la solution, que l'on peut parcourir étape par étape.

## Structure

```
lib/cube/            Cœur logique en pur Dart (sans Flutter)
  definitions.dart   Faces, couleurs, numérotation des 54 cases
  moves.dart         Mouvements et notation (R, U2, F'…)
  cubie_cube.dart    Représentation par pièces + coordonnées
  validation.dart    Vérifie qu'un cube scanné est réel et résoluble
  solver.dart        Algorithme à deux phases de Kociemba
  tracking.dart      Vérifie une face pendant la résolution
lib/main.dart        Écran de démo
test/                Tests unitaires
```

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

Pendant la résolution, `checkFace` compare une face photographiée avec l'état
attendu : il indique si l'utilisateur a oublié ou ajouté un mouvement, ou si une
pièce a été bougée.

## Solveur

Algorithme à deux phases de Kociemba. Les tables (~6 Mo) sont calculées au
premier appel (1 à 2 s), dans un isolate pour ne pas figer l'interface. Les
solutions font environ 20 coups en moyenne, 21 au maximum dans les tests.

## Commandes

```bash
flutter test
```

```bash
flutter run
```
