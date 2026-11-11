import 'dart:math';

import 'package:flutter/foundation.dart' show compute;
import 'package:material_ui/material_ui.dart';

import 'cube/cube.dart';

void main() {
  runApp(const CubeSolverApp());
}

class CubeSolverApp extends StatelessWidget {
  const CubeSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cube Solver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const DemoPage(),
    );
  }
}

/// Couleurs d'affichage, pour le schéma standard
/// (U blanc, R rouge, F vert, D jaune, L orange, B bleu).
const Map<Face, Color> faceColors = {
  Face.U: Colors.white,
  Face.R: Color(0xFFC62828),
  Face.F: Color(0xFF2E7D32),
  Face.D: Color(0xFFFDD835),
  Face.L: Color(0xFFEF6C00),
  Face.B: Color(0xFF1565C0),
};

/// Résolution dans un isolate séparé pour ne pas bloquer l'interface
/// pendant la construction des tables du solveur.
List<String> _solveInIsolate(String facelets) =>
    Solver.instance.solveFacelets(facelets).map((m) => m.notation).toList();

/// Écran de démonstration : mélange aléatoire, puis résolution pas à pas.
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  CubieCube _start = CubieCube();
  List<Move> _solution = const [];
  int _step = 0;
  bool _solving = false;
  String? _message;

  CubieCube get _current => _start.copy()..applyMoves(_solution.take(_step));

  void _scramble() {
    setState(() {
      _start = CubieCube.random(Random());
      _solution = const [];
      _step = 0;
      _message = null;
    });
  }

  Future<void> _solve() async {
    setState(() {
      _solving = true;
      _message = null;
    });
    final facelets = _start.toFacelets().map((f) => f.letter).join();
    try {
      final moves = await compute(_solveInIsolate, facelets);
      setState(() {
        _solution = moves.map(Move.parse).toList();
        _step = 0;
        _message = _solution.isEmpty
            ? 'Le cube est déjà résolu.'
            : 'Solution en ${_solution.length} mouvements.';
      });
    } on Object catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _solving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cube Solver — démo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: CubeNet(facelets: _current.toFacelets())),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: _solving ? null : _scramble,
                  child: const Text('Mélanger'),
                ),
                FilledButton(
                  onPressed: _solving ? null : _solve,
                  child: _solving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Résoudre'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
            if (_solution.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _solution.length; i++)
                    Chip(
                      label: Text(_solution[i].notation),
                      backgroundColor: i < _step
                          ? theme.colorScheme.surfaceContainerHighest
                          : i == _step
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _step > 0 ? () => setState(() => _step--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Étape $_step / ${_solution.length}'),
                  IconButton(
                    onPressed: _step < _solution.length
                        ? () => setState(() => _step++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Patron (vue « dépliée ») du cube.
class CubeNet extends StatelessWidget {
  const CubeNet({super.key, required this.facelets, this.cellSize = 22});

  final List<Face> facelets;
  final double cellSize;

  Widget _face(Face face) {
    return SizedBox.square(
      dimension: cellSize * 3,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          for (var k = 0; k < 9; k++)
            Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: faceColors[facelets[face.index * 9 + k]],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black54, width: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox.square(dimension: cellSize * 3);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [gap, _face(Face.U), gap, gap],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _face(Face.L),
            _face(Face.F),
            _face(Face.R),
            _face(Face.B),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [gap, _face(Face.D), gap, gap],
        ),
      ],
    );
  }
}
