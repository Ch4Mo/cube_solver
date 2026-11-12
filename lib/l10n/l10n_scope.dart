import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

export 'strings.dart';

/// Langues proposées, dans l'ordre du sélecteur.
const supportedLocales = [Locale('fr'), Locale('en'), Locale('es')];

/// Choix de langue de l'utilisateur, mémorisé entre deux lancements.
/// `null` = suivre la langue du téléphone.
class LanguageController extends ValueNotifier<AppLanguage?> {
  LanguageController([super.value]);

  static const _key = 'language';

  /// Charge le choix enregistré (sans erreur si le stockage est indisponible).
  static Future<LanguageController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return LanguageController(AppLanguage.fromCode(prefs.getString(_key)));
    } on Object {
      return LanguageController();
    }
  }

  Future<void> select(AppLanguage? language) async {
    value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (language == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, language.name);
      }
    } on Object {
      // Le choix reste valable pour cette session.
    }
  }

  /// Langue effective : le choix de l'utilisateur, sinon celle du téléphone
  /// si elle est disponible, sinon l'anglais.
  static AppLanguage resolve(AppLanguage? choice, Locale? deviceLocale) =>
      choice ??
      AppLanguage.fromCode(deviceLocale?.languageCode) ??
      AppLanguage.en;
}

/// Rend la langue active disponible dans l'arbre de widgets. Les widgets qui
/// lisent [BuildContext.tr] sont reconstruits quand elle change.
class L10nScope extends InheritedWidget {
  L10nScope({
    super.key,
    required this.language,
    this.controller,
    required super.child,
  }) {
    // Les messages produits par la logique du cube (validation, consignes…)
    // utilisent aussi la langue active.
    Strings.current = Strings.of(language);
  }

  final AppLanguage language;

  /// Permet de changer de langue (absent dans certains tests).
  final LanguageController? controller;

  static L10nScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<L10nScope>();

  static LanguageController? controllerOf(BuildContext context) =>
      _of(context)?.controller;

  @override
  bool updateShouldNotify(L10nScope oldWidget) =>
      oldWidget.language != language;
}

extension L10nContext on BuildContext {
  /// Textes dans la langue active.
  Strings get tr {
    final scope = L10nScope._of(this);
    return scope == null ? Strings.current : Strings.of(scope.language);
  }
}

/// Feuille de choix de la langue.
Future<void> showLanguagePicker(
  BuildContext context,
  LanguageController controller,
) {
  final t = context.tr;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: RadioGroup<AppLanguage?>(
        groupValue: controller.value,
        onChanged: (value) {
          controller.select(value);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                t.languageLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioListTile<AppLanguage?>(
              value: null,
              title: Text(t.systemLanguage),
            ),
            for (final l in AppLanguage.values)
              RadioListTile<AppLanguage?>(value: l, title: Text(l.nativeName)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
