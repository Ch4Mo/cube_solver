import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Gestion de la publicité : consentement (RGPD, via la plateforme de
/// consentement de Google), initialisation d'AdMob et annonces plein écran.
///
/// Tant que [init] n'a pas été appelé (tests, web), aucune annonce n'est
/// chargée et l'application fonctionne normalement.
class Ads {
  Ads._();

  /// Vrai quand les annonces peuvent être demandées (consentement réglé et
  /// SDK initialisé).
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  static bool _started = false;
  static InterstitialAd? _interstitial;
  static DateTime? _lastInterstitial;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// À appeler une fois au démarrage. Affiche le formulaire de consentement
  /// si nécessaire (utilisateurs européens), puis initialise AdMob.
  static Future<void> init() async {
    if (!_supported) return;
    // Consentement déjà donné lors d'une session précédente.
    if (await _canRequestAds()) unawaited(_start());

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('Consentement : ${error.message}');
        });
        if (await _canRequestAds()) await _start();
      },
      (error) => debugPrint('Consentement : ${error.message}'),
    );
  }

  static Future<bool> _canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } on Object {
      return false;
    }
  }

  static Future<void> _start() async {
    if (_started) return;
    _started = true;
    await MobileAds.instance.initialize();
    ready.value = true;
    _loadInterstitial();
  }

  /// Vrai si l'utilisateur doit pouvoir modifier ses choix de confidentialité
  /// (obligatoire en Europe dès qu'un formulaire de consentement existe).
  static Future<bool> privacyOptionsRequired() async {
    if (!_supported) return false;
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  /// Rouvre le formulaire de consentement.
  static Future<void> showPrivacyOptions() =>
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('Consentement : ${error.message}');
      });

  static void _loadInterstitial() {
    if (!ready.value) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Annonce plein écran : ${error.message}');
          _interstitial = null;
        },
      ),
    );
  }

  /// Affiche une annonce plein écran si une est prête et que la précédente
  /// date de plus de [AdConfig.interstitialInterval]. Se termine quand
  /// l'annonce est fermée (ou tout de suite s'il n'y en a pas).
  static Future<void> maybeShowInterstitial() async {
    final ad = _interstitial;
    final last = _lastInterstitial;
    if (ad == null ||
        (last != null &&
            DateTime.now().difference(last) < AdConfig.interstitialInterval)) {
      return;
    }
    _interstitial = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        closed.complete();
        _loadInterstitial();
      },
    );
    _lastInterstitial = DateTime.now();
    await ad.show();
    await closed.future;
  }
}
