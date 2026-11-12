import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../ads/ad_banner.dart';
import '../ads/ads.dart';
import '../cube/cube.dart';
import '../vision/color_classifier.dart';
import 'cube_widgets.dart';
import 'solution_page.dart';

/// Saisie manuelle des couleurs, face par face.
///
/// Sert aussi à vérifier et corriger les couleurs détectées sur les photos.
class ManualInputPage extends StatefulWidget {
  const ManualInputPage({
    super.key,
    this.initial,
    this.uncertain,
    this.references,
  });

  /// Saisie de départ (par ex. issue des photos). Par défaut, seuls les
  /// centres sont remplis.
  final CubeInput? initial;

  /// Cases dont la détection est incertaine (scan). `null` si la saisie ne
  /// vient pas d'un scan.
  final Set<int>? uncertain;

  /// Couleurs de référence mesurées pendant le scan, transmises à l'écran de
  /// solution pour vérifier le cube en cours de route.
  final Map<CubeColor, Lab>? references;

  bool get fromScan => uncertain != null;

  @override
  State<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends State<ManualInputPage> {
  late CubeInput _input = widget.initial ?? CubeInput();
  int _faceStep = 0;
  CubeColor _selected = CubeColor.white;
  late final Set<int> _uncertain = {...?widget.uncertain};

  Face get _face => inputOrder[_faceStep];

  void _paint(int k) {
    setState(() {
      _input[_face.index * 9 + k] = _selected;
      _uncertain.remove(_face.index * 9 + k);
    });
  }

  void _goToFace(Face face) {
    setState(() => _faceStep = inputOrder.indexOf(face));
  }

  Future<void> _onMenu(String action) async {
    switch (action) {
      case 'clear':
        setState(() {
          _input.clear();
          _uncertain.clear();
        });
      case 'random':
        setState(() {
          _uncertain.clear();
          _input = CubeInput.fromCube(CubieCube.random(Random()));
          _faceStep = 0;
        });
    }
  }

  Future<void> _solve(ValidationResult v) async {
    // Annonce plein écran éventuelle (au plus une toutes les 3 minutes).
    await Ads.maybeShowInterstitial();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolutionPage(
          start: v.cube!,
          scheme: v.colorScheme!,
          references: widget.references,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validation = _input.validate();
    final overused = _input.overusedColors.toSet();
    final highlighted = <int>{
      for (final e in validation?.errors ?? const <CubeError>[]) ...e.facelets,
      for (var i = 0; i < 54; i++)
        if (overused.contains(_input[i])) i,
    };
    final counts = _input.colorCounts;

    return Scaffold(
      bottomNavigationBar: const AdBanner(),
      appBar: AppBar(
        title: const Text('Saisie des couleurs'),
        actions: [
          PopupMenuButton<String>(
            tooltip: "Plus d'options",
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Tout effacer')),
              PopupMenuItem(
                value: 'random',
                child: Text('Remplir avec un cube mélangé'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gridSize = min(constraints.maxWidth - 32, 280.0);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.fromScan)
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _uncertain.isEmpty
                            ? 'Couleurs détectées. Vérifiez chaque face et '
                                  'corrigez si besoin.'
                            : 'Couleurs détectées. Vérifiez chaque face : '
                                  '${_uncertain.length} case(s) incertaine(s) '
                                  'sont entourées en orange.',
                      ),
                    ),
                  ),
                if (widget.fromScan) const SizedBox(height: 12),
                Text(
                  'Face ${_faceStep + 1}/6 : ${faceName(_face)}',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _input.orientationHint(_face),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Face précédente',
                      onPressed: _faceStep > 0
                          ? () => setState(() => _faceStep--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: FaceGrid(
                          colors: _input.face(_face),
                          size: max(gridSize - 96, 150),
                          highlighted: {
                            for (final i in highlighted)
                              if (i ~/ 9 == _face.index) i % 9,
                          },
                          warned: {
                            for (final i in _uncertain)
                              if (i ~/ 9 == _face.index) i % 9,
                          },
                          onTap: _paint,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Face suivante',
                      onPressed: _faceStep < 5
                          ? () => setState(() => _faceStep++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Palette(
                  selected: _selected,
                  counts: counts,
                  onSelected: (c) => setState(() => _selected = c),
                ),
                const SizedBox(height: 20),
                Text(
                  'Vue d\'ensemble (touchez une face pour la modifier)',
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Center(
                  child: CubeNetView(
                    colors: _input.colors,
                    highlighted: highlighted,
                    warned: _uncertain,
                    selectedFace: _face,
                    onFaceTap: _goToFace,
                  ),
                ),
                const SizedBox(height: 16),
                _StatusCard(
                  input: _input,
                  validation: validation,
                  overused: overused,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: validation?.isValid == true
                      ? () => _solve(validation!)
                      : null,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Résoudre'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final CubeColor selected;
  final Map<CubeColor, int> counts;
  final ValueChanged<CubeColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in CubeColor.values)
          Semantics(
            button: true,
            selected: c == selected,
            excludeSemantics: true,
            label: '${c.label}, ${counts[c]} sur 9',
            child: GestureDetector(
              onTap: () => onSelected(c),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: displayColor(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == selected
                            ? theme.colorScheme.primary
                            : Colors.black26,
                        width: c == selected ? 4 : 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${counts[c]}/9',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: counts[c]! > 9 ? Colors.red : null,
                      fontWeight: counts[c] == 9 ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.input,
    required this.validation,
    required this.overused,
  });

  final CubeInput input;
  final ValidationResult? validation;
  final Set<CubeColor> overused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> lines;
    final IconData icon;
    final Color color;

    if (validation == null) {
      final remaining = 54 - input.filledCount;
      lines = [
        '$remaining case(s) restante(s).',
        for (final c in overused)
          '${c.label} : plus de 9 cases, vérifiez cette couleur.',
      ];
      icon = overused.isEmpty ? Icons.edit : Icons.warning_amber;
      color = overused.isEmpty
          ? theme.colorScheme.onSurfaceVariant
          : Colors.red;
    } else if (validation!.isValid) {
      lines = ['Cube valide, prêt à être résolu.'];
      icon = Icons.check_circle;
      color = Colors.green.shade700;
    } else {
      lines = [for (final e in validation!.errors) e.message];
      icon = validation!.errors.any((e) => e.isPhysicalTampering)
          ? Icons.build
          : Icons.error;
      color = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(l, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
