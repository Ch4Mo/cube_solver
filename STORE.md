# Publier Cube Solver

Ce guide liste tout ce qu'il reste à faire pour publier l'application et la
monétiser. Ce qui est déjà prêt dans le dépôt est marqué ✅.

| Élément | Où |
|---|---|
| ✅ Identifiant définitif : `io.github.ch4mo.cubesolver` | Android et iOS |
| ✅ Signature de publication (clé d'envoi) | `android/key.properties` (non commité) |
| ✅ App Bundle `.aab` | `flutter build appbundle` |
| ✅ Textes de la fiche (titre, descriptions, nouveautés) | `fastlane/metadata/android/fr-FR/` |
| ✅ Captures d'écran, bannière 1024×500, icône 512×512 | `fastlane/metadata/android/fr-FR/images/` |
| ✅ Politique de confidentialité | `docs/privacy-policy.md` |
| ✅ Publicité AdMob + formulaire de consentement RGPD | `lib/ads/` |
| ⬜ Comptes Google Play / AdMob / Apple | à créer par vous |
| ⬜ Vrais identifiants AdMob | voir § 2 |

---

## 1. La clé de signature (à conserver précieusement)

L'App Bundle est signé avec une **clé d'envoi** (`upload-keystore.jks`) et son
fichier de mots de passe (`key.properties`). Ces deux fichiers vous ont été
transmis à part : **ils ne doivent jamais être ajoutés au dépôt**, qui est
public.

- Rangez-les dans un endroit sûr (gestionnaire de mots de passe, clé USB…).
- Pour compiler sur votre machine : copiez `key.properties` dans `android/`
  et corrigez la ligne `storeFile=` avec le chemin du fichier `.jks`.
- Activez la **signature des applications par Google Play** (proposée par
  défaut à la création de l'application) : Google garde la clé finale et, si
  vous perdez la clé d'envoi, le support Google peut la réinitialiser.

Sans `android/key.properties`, la version release est signée avec la clé de
débogage : pratique pour tester, refusé par le Play Store.

## 2. Publicité (AdMob)

L'application affiche :
- une **bannière** en bas de l'accueil, de la saisie et de la solution ;
- une **annonce plein écran** au moment de lancer la résolution, au plus une
  fois toutes les 3 minutes.

Elle utilise pour l'instant les **identifiants de test de Google** : les
annonces portent la mention « Test Ad » et ne rapportent rien. Ne cliquez
jamais sur vos propres annonces réelles (risque de suspension du compte).

### Mettre vos identifiants

1. Créez un compte sur <https://admob.google.com> (gratuit), avec vos
   informations de paiement.
2. Ajoutez l'application (Android ; « pas encore publiée » au début).
   Vous obtenez un **ID d'application** `ca-app-pub-XXXX~YYYY`.
3. Créez deux **blocs d'annonces** : « Bannière » et « Interstitiel ».
   Vous obtenez deux IDs `ca-app-pub-XXXX/ZZZZ`.
4. Dans AdMob, **Confidentialité et messages → RGPD** : créez et publiez le
   message de consentement (obligatoire pour les utilisateurs européens ;
   l'application l'affiche automatiquement).
5. Remplacez l'ID d'application :
   - Android : `admobAppId=` dans `android/gradle.properties` ;
   - iOS : `GADApplicationIdentifier` dans `ios/Runner/Info.plist`
     (une app iOS distincte est à créer dans AdMob).
6. Compilez en passant les IDs des blocs :

```bash
flutter build appbundle --release --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/BBBB --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/IIII
```

7. Une fois l'application publiée, associez-la à sa fiche Play dans AdMob.
   Recommandé : publier un fichier `app-ads.txt` à la racine du site
   déclaré comme « site Web du développeur » sur le Play Store (par exemple
   un site GitHub Pages `ch4mo.github.io`). AdMob fournit son contenu exact.

### Ce qu'on peut en attendre

Les revenus dépendent surtout du nombre d'utilisateurs actifs. À titre
d'ordre de grandeur, une bannière rapporte de l'ordre de quelques dizaines de
centimes à 1 € pour 1 000 affichages en France, un interstitiel plusieurs
fois plus. Il faut donc des milliers d'utilisateurs réguliers pour des
revenus significatifs. AdMob paie à partir de 70 € cumulés.

## 3. Google Play

1. Créez un compte développeur : <https://play.google.com/console>
   (25 $, une seule fois, vérification d'identité).
2. **Créer une application** : nom « Cube Solver », langue français, jeu ou
   application → *Application*, gratuite.
3. **Configuration de l'application** (tableau de bord) :
   - *Politique de confidentialité* : l'URL de `docs/privacy-policy.md`
     (voir § 5).
   - *Annonces* : **Oui, l'application contient des annonces**.
   - *Accès à l'application* : toutes les fonctionnalités sont accessibles
     sans restriction.
   - *Classification du contenu* : questionnaire (aucune violence, etc.) →
     classification « Tout public / PEGI 3 » attendue.
   - *Public cible* : **13 ans et plus** (choisir des tranches plus jeunes
     impose le programme « Familles » et des annonces spécifiques).
   - *Sécurité des données* : voir § 4.
   - *Identifiant publicitaire* : **Oui**, utilisé pour la publicité.
4. **Fiche principale du Play Store** : copiez les textes et images de
   `fastlane/metadata/android/fr-FR/`.
5. **Tests → Test fermé** : envoyez `app-release.aab`.
   Pour un compte personnel récent, Google exige un test fermé avec au moins
   **12 testeurs pendant 14 jours** avant l'accès à la production
   (vérifiez les règles en vigueur dans la Play Console).
6. **Production** : demandez l'accès, puis publiez. L'examen prend de
   quelques heures à quelques jours.

## 4. Formulaire « Sécurité des données »

Les photos sont traitées uniquement sur l'appareil : elles ne comptent pas
comme des données collectées. Les données à déclarer viennent du SDK AdMob
(vérifiez la liste à jour sur la page de Google « Google Mobile Ads SDK –
Data disclosure ») :

| Type de données | Collectées | Partagées | Finalité |
|---|---|---|---|
| Identifiants de l'appareil (ID publicitaire) | Oui | Oui | Publicité, analyse, prévention de la fraude |
| Localisation approximative (via l'adresse IP) | Oui | Oui | Publicité, prévention de la fraude |
| Interactions avec l'application (annonces) | Oui | Oui | Publicité, analyse |
| Diagnostics, journaux de plantage | Oui | Oui | Analyse, prévention de la fraude |

- Données chiffrées pendant le transfert : **Oui**.
- L'utilisateur peut demander la suppression : sans objet (aucun compte).

## 5. Héberger la politique de confidentialité

L'adresse doit rester valide après publication. Deux options :

- **Simple** : l'adresse GitHub du fichier, après avoir fusionné la branche
  dans `main` :
  `https://github.com/Ch4Mo/cube_solver/blob/main/docs/privacy-policy.md`
- **Plus propre** : activer GitHub Pages (Settings → Pages → dossier `docs/`
  de `main`) : `https://ch4mo.github.io/cube_solver/privacy-policy`.

Mettez ensuite la même adresse dans `lib/app_info.dart`
(`privacyPolicyUrl`, lien affiché dans « À propos ») et recompilez.

## 6. App Store (iOS)

Le projet iOS est configuré (identifiant, icône, écran de lancement,
autorisation caméra, AdMob, chiffrement déclaré « aucun »). Il reste :

1. Un **compte Apple Developer** (99 $/an).
2. Un **Mac avec Xcode**, ou un service de compilation en ligne (Codemagic,
   GitHub Actions macOS) pour produire l'archive.
3. Dans App Store Connect : créer l'app (`io.github.ch4mo.cubesolver`),
   remplir la fiche (mêmes textes), les « étiquettes de confidentialité »
   (mêmes réponses qu'au § 4), captures iPhone 6,7" et 6,5".
4. Dans AdMob : créer l'app iOS, mettre ses IDs (§ 2) et activer le message
   « IDFA » (demande d'autorisation de suivi d'Apple).
5. Tester sur un vrai iPhone via TestFlight, puis soumettre à l'examen.

## 7. Compiler

```bash
flutter build appbundle --release
```

```bash
flutter build apk --release --target-platform android-arm,android-arm64
```

Pensez à augmenter `version:` dans `pubspec.yaml` à chaque envoi
(le nombre après `+` doit toujours augmenter).

Régénérer les visuels :

```bash
python3 tool/make_icon.py
```

```bash
dart run flutter_launcher_icons
```

```bash
dart run flutter_native_splash:create
```
