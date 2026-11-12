import 'package:material_ui/material_ui.dart';

import 'ads/ads.dart';
import 'l10n/l10n_scope.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final language = await LanguageController.load();
  runApp(CubeSolverApp(language: language));
  // Consentement et publicité, sans bloquer l'affichage.
  Ads.init();
}

class CubeSolverApp extends StatefulWidget {
  const CubeSolverApp({super.key, this.language});

  /// Choix de langue (par défaut : langue du téléphone).
  final LanguageController? language;

  @override
  State<CubeSolverApp> createState() => _CubeSolverAppState();
}

class _CubeSolverAppState extends State<CubeSolverApp> {
  late final LanguageController _language =
      widget.language ?? LanguageController();

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B4BE0);
    return ValueListenableBuilder<AppLanguage?>(
      valueListenable: _language,
      builder: (context, choice, _) => MaterialApp(
        title: 'Cube Solver',
        debugShowCheckedModeBanner: false,
        locale: choice == null ? null : Locale(choice.name),
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Langue du téléphone non disponible : anglais.
        localeResolutionCallback: (locale, supported) =>
            Locale(LanguageController.resolve(null, locale).name),
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed)),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.dark,
          ),
        ),
        builder: (context, child) => L10nScope(
          language:
              AppLanguage.fromCode(
                Localizations.localeOf(context).languageCode,
              ) ??
              AppLanguage.en,
          controller: _language,
          child: child!,
        ),
        home: const HomePage(),
      ),
    );
  }
}
