import 'package:flutter/foundation.dart' show compute;
import 'package:material_ui/material_ui.dart';

import '../cube/cube.dart';
import '../vision/color_classifier.dart';
import 'cube_3d.dart';
import 'cube_widgets.dart';
import 'scan_page.dart';

/// Résolution dans un isolate séparé pour ne pas bloquer l'interface
/// pendant la construction des tables du solveur.
List<String> _solveInIsolate(String facelets) =>
    Solver.instance.solveFacelets(facelets).map((m) => m.notation).toList();

/// Affiche la solution mouvement par mouvement.
class SolutionPage extends StatefulWidget {
  const SolutionPage({
    super.key,
    required this.start,
    required this.scheme,
    this.references,
  });

  final CubieCube start;

  /// Couleur du centre de chaque face.
  final Map<Face, CubeColor> scheme;

  /// Couleurs mesurées lors du scan (améliore la vérification par photo).
  final Map<CubeColor, Lab>? references;

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  List<Move>? _solution;
  String? _error;
  int _step = 0;
  bool _showNet = false;

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

  /// Photographie la face avant et la compare à l'état attendu.
  Future<void> _verify() async {
    final samples = await Navigator.of(context).push<List<Rgb>>(
      MaterialPageRoute(builder: (_) => const ScanPage(singleFace: Face.F)),
    );
    if (samples == null || !mounted) return;

    final colors = classifyFace(samples, widget.references);
    final faceOf = {for (final e in widget.scheme.entries) e.value: e.key};
    final observed = [for (final c in colors) faceOf[c]!];
    final check = checkFace(widget.start, _solution!, _step, Face.F, observed);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          check.matches ? Icons.check_circle : Icons.warning_amber,
          color: check.matches ? Colors.green : Colors.orange,
        ),
        title: Text(
          check.matches ? 'Tout va bien' : 'Le cube ne correspond pas',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(check.message),
            if (!check.matches) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LabeledFace('Attendu', _currentColors.sublist(18, 27)),
                  _LabeledFace(
                    'Photo',
                    colors,
                    highlighted: check.mismatchedFacelets.toSet(),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (check.matchingStep != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _step = check.matchingStep!);
              },
              child: Text("Aller à l'étape ${check.matchingStep! + 1}"),
            ),
          if (!check.matches && check.matchingStep == null) ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ignorer'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(this.context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const ScanPage()),
                );
              },
              child: const Text('Rescanner le cube'),
            ),
          ],
          if (check.matches)
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuer'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solution'),
        actions: [
          if (_solution != null && _solution!.isNotEmpty)
            IconButton(
              tooltip: 'Vérifier avec une photo',
              onPressed: _verify,
              icon: const Icon(Icons.fact_check),
            ),
        ],
      ),
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
    final colors = _currentColors;
    final move = done ? null : solution[_step];

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
        const SizedBox(height: 8),
        Center(
          child: Cube3DView(colors: colors, move: move, size: 220),
        ),
        if (solution.isEmpty)
          Text(
            'Le cube est déjà résolu !',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          )
        else if (done)
          Text(
            'Bravo, cube résolu en ${solution.length} mouvements !',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          )
        else ...[
          Text(
            move!.notation,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            describeMove(move, widget.scheme),
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
                iconSize: 32,
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _verify,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Vérifier mon cube avec une photo'),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _showNet = !_showNet),
          icon: Icon(_showNet ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _showNet ? 'Masquer toutes les faces' : 'Voir toutes les faces',
          ),
        ),
        if (_showNet) Center(child: CubeNetView(colors: colors)),
      ],
    );
  }
}

class _LabeledFace extends StatelessWidget {
  const _LabeledFace(this.label, this.colors, {this.highlighted = const {}});

  final String label;
  final List<CubeColor> colors;
  final Set<int> highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaceGrid(colors: colors, size: 84, highlighted: highlighted),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
