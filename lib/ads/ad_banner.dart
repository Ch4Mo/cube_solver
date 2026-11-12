import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

import 'ad_config.dart';
import 'ads.dart';

/// Bannière publicitaire adaptative, en bas d'écran.
///
/// N'occupe aucune place tant qu'aucune annonce n'est chargée (pas de
/// consentement, pas de réseau, tests…).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Ads.ready.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  @override
  void dispose() {
    Ads.ready.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _maybeLoad() async {
    if (!Ads.ready.value || _loading || _ad != null || !mounted) return;
    _loading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) {
      _loading = false;
      return;
    }
    _ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Bannière : ${error.message}');
          ad.dispose();
          _ad = null;
          _loading = false;
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
