import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../cube/cube.dart';
import 'manual_input_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open(CubeInput? initial) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManualInputPage(initial: initial),
      ),
    );

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
              'Indiquez les couleurs de chaque face : l\'application vérifie '
              'que le cube est valide, puis vous guide mouvement par '
              'mouvement.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Saisir les couleurs'),
                subtitle: const Text('Face par face, en touchant les cases'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(null),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shuffle),
                title: const Text('Essayer avec un cube mélangé'),
                subtitle: const Text('Un mélange aléatoire, déjà rempli'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    open(CubeInput.fromCube(CubieCube.random(Random()))),
              ),
            ),
            const Card(
              child: ListTile(
                enabled: false,
                leading: Icon(Icons.photo_camera),
                title: Text('Scanner avec l\'appareil photo'),
                subtitle: Text('Bientôt disponible'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
