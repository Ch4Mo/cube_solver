import 'package:material_ui/material_ui.dart';

import 'manual_input_page.dart';
import 'scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cube Solver')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Résolvez votre Rubik\'s Cube',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scannez ou saisissez les couleurs de chaque face : '
              'l\'application vérifie que le cube est valide, puis vous guide '
              'mouvement par mouvement.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Scanner le cube'),
                subtitle: const Text(
                  'Photographiez les 6 faces, les couleurs sont détectées',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ScanPage()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Saisir les couleurs'),
                subtitle: const Text('Face par face, en touchant les cases'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManualInputPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
