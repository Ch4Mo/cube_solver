import 'package:flutter/foundation.dart';

/// Identifiants des blocs d'annonces AdMob.
///
/// Par défaut, ce sont les identifiants de TEST fournis par Google : ils
/// affichent des annonces « Test Ad » et ne rapportent rien. Pour une version
/// publiée, passez vos propres identifiants à la compilation :
///
/// ```
/// flutter build appbundle \
///   --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/zzz
/// ```
///
/// L'identifiant de l'APPLICATION (ca-app-pub-xxx~nnn) se règle séparément :
/// `android/app/build.gradle.kts` (propriété `admobAppId`) et
/// `ios/Runner/Info.plist` (`GADApplicationIdentifier`). Voir STORE.md.
class AdConfig {
  static const _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/9214589741',
  );
  static const _bannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2435281174',
  );
  static const _interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const _interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get bannerId => _ios ? _bannerIos : _bannerAndroid;

  static String get interstitialId =>
      _ios ? _interstitialIos : _interstitialAndroid;

  /// Délai minimal entre deux annonces plein écran.
  static const interstitialInterval = Duration(minutes: 3);
}
