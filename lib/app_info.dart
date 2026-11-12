import 'l10n/strings.dart';

/// Informations générales sur l'application.
class AppInfo {
  static const name = 'Cube Solver';

  /// Dossier des politiques de confidentialité (exigées par les stores et
  /// par AdMob). À mettre à jour si les fichiers changent d'adresse (par
  /// exemple après fusion dans `main` ou avec GitHub Pages).
  static const _docs =
      'https://github.com/Ch4Mo/cube_solver/blob/claude/pensive-hopper-1ljwb5/docs';

  /// Politique de confidentialité dans la langue demandée.
  static String privacyPolicyUrl(AppLanguage language) => switch (language) {
    AppLanguage.fr => '$_docs/privacy-policy.md',
    AppLanguage.en => '$_docs/privacy-policy.en.md',
    AppLanguage.es => '$_docs/privacy-policy.es.md',
  };
}
