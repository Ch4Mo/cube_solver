import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ads.dart';
import '../app_info.dart';
import '../l10n/l10n_scope.dart';

/// Feuille « À propos » : version, confidentialité, préférences publicitaires.
Future<void> showAboutSheet(BuildContext context) async {
  final results = await Future.wait([
    PackageInfo.fromPlatform()
        .then<String?>((i) => '${i.version} (${i.buildNumber})')
        .catchError((_) => null),
    Ads.privacyOptionsRequired(),
  ]);
  if (!context.mounted) return;
  final t = context.tr;
  final version = results[0] as String?;
  final privacyOptions = results[1] as bool;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppInfo.name),
            subtitle: Text(
              version == null ? t.appDescription : t.version(version),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(t.privacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse(AppInfo.privacyPolicyUrl(t.language)),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (privacyOptions)
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(t.adPreferences),
              subtitle: Text(t.adPreferencesSubtitle),
              onTap: () {
                Navigator.pop(context);
                Ads.showPrivacyOptions();
              },
            ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(t.licenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: version,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
