import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ads.dart';
import '../app_info.dart';

/// Feuille « À propos » : version, confidentialité, préférences publicitaires.
Future<void> showAboutSheet(BuildContext context) async {
  final results = await Future.wait([
    PackageInfo.fromPlatform()
        .then<String?>((i) => '${i.version} (${i.buildNumber})')
        .catchError((_) => null),
    Ads.privacyOptionsRequired(),
  ]);
  if (!context.mounted) return;
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
              version == null
                  ? 'Aide à la résolution du cube 3×3'
                  : 'Version $version',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse(AppInfo.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (privacyOptions)
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Préférences publicitaires'),
              subtitle: const Text('Modifier votre consentement'),
              onTap: () {
                Navigator.pop(context);
                Ads.showPrivacyOptions();
              },
            ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licences des logiciels utilisés'),
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
