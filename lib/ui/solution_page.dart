import 'package:flutter/foundation.dart' show compute;
import 'package:material_ui/material_ui.dart';

import '../cube/cube.dart';
import 'cube_widgets.dart';

/// Résolution dans un isolate séparé pour ne pas bloquer l'interface
/// pendant la construction des tables du solveur.
List<String> _solveInIsolate(String facelets) =>
    Solver.instance.solveFacelets(facelets).map((m) => m.notation).toList();

/// Affiche la solution mouvement par mouvement.
class SolutionPage extends StatefulWidget {
  const SolutionPage({super.key, required this.start, required this.scheme});

  final CubieCube start;

  /// Couleur du centre de chaque face.
  final Map<Face, CubeColor> scheme;

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  List<Move>? _solution;
  String? _error;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _solve();
  }

  Future<void> _solve() async {
    final facelets = widget.start.toFacelets().map((f) => f.letter).join();
    try {
      final moves = await compute(_solveInIsolate, facelets);
      if (mounted) setState(() => _solution = moves.map(Move.parse).toList());
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  List<CubeColor> get _currentColors {
    final c = widget.start.copy()..applyMoves(_solution!.take(_step));
    return [for (final f in c.toFacelets()) widget.scheme[f]!];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solution')),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final solution = _solution;
    if (solution == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calcul de la solution…'),
          ],
        ),
      );
    }

    final front = widget.scheme[Face.F]!.label.toLowerCase();
    final top = widget.scheme[Face.U]!.label.toLowerCase();
    final done = _step >= solution.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.pan_tool_alt),
            title: Text(
              'Gardez le centre $front face à vous et le centre $top en '
              'haut pendant toute la résolution.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: CubeNetView(colors: _currentColors)),
        const SizedBox(height: 20),
        if (solution.isEmpty)
          Text(
            'Le cube est déjà résolu !',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          )
        else if (done)
          Text(
            'Cube résolu en ${solution.length} mouvements !',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          )
        else ...[
          Text(
            solution[_step].notation,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            describeMove(solution[_step], widget.scheme),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
        if (solution.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                tooltip: 'Mouvement précédent',
                onPressed: _step > 0 ? () => setState(() => _step--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 16),
              Text('Étape ${_step + (done ? 0 : 1)} / ${solution.length}'),
              const SizedBox(width: 16),
              IconButton.filled(
                tooltip: 'Mouvement suivant',
                onPressed: !done ? () => setState(() => _step++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < solution.length; i++)
                ActionChip(
                  label: Text(solution[i].notation),
                  onPressed: () => setState(() => _step = i),
                  backgroundColor: i < _step
                      ? theme.colorScheme.surfaceContainerHighest
                      : i == _step
                      ? theme.colorScheme.primaryContainer
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
