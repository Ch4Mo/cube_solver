import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:material_ui/material_ui.dart';

import '../cube/cube.dart';
import '../vision/color_classifier.dart';
import '../vision/sampler.dart';
import 'cube_widgets.dart';
import 'manual_input_page.dart';

/// Couleur d'affichage approximative d'une mesure brute.
Color rgbColor(Rgb c) => Color.fromARGB(255, c.r, c.g, c.b);

/// Scan des 6 faces avec l'appareil photo.
///
/// Avec [singleFace], ne photographie qu'une face et renvoie ses 9 couleurs
/// mesurées (`Navigator.pop`) : sert à vérifier le cube pendant la
/// résolution.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.singleFace});

  final Face? singleFace;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _cameraError;
  bool _busy = false;
  bool _torch = false;
  int _faceStep = 0;

  /// Couleurs mesurées pour chaque face (dans l'ordre de [inputOrder]).
  final Map<Face, List<Rgb>> _samples = {};

  Face get _face => widget.singleFace ?? inputOrder[_faceStep];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && controller == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'Aucun appareil photo disponible.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } on CameraException {
        // Appareil sans flash : sans importance.
      }
      _torch = false;
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      setState(
        () => _cameraError = switch (e.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' =>
            "L'accès à l'appareil photo a été refusé. Autorisez-le dans les "
                "réglages du téléphone, ou saisissez les couleurs à la main.",
          _ => "Impossible d'ouvrir l'appareil photo (${e.code}).",
        },
      );
    }
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } on CameraException {
      // Pas de lampe sur cet appareil : on ignore.
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _busy || !c.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      final samples = await compute(sampleFacePhoto, SampleRequest(bytes));
      if (!mounted) return;
      if (widget.singleFace != null) {
        Navigator.of(context).pop(samples);
        return;
      }

      final warning = _similarCenterWarning(samples[4]);
      setState(() {
        _samples[_face] = samples;
        final next = inputOrder.indexWhere((f) => !_samples.containsKey(f));
        if (next >= 0) _faceStep = next;
      });
      if (warning != null) _showMessage(warning);
    } on Object catch (e) {
      _showMessage('La photo a échoué : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Avertit si le centre ressemble beaucoup à celui d'une face déjà scannée
  /// (l'utilisateur a peut-être oublié de tourner le cube).
  String? _similarCenterWarning(Rgb center) {
    final lab = center.toLab();
    for (final e in _samples.entries) {
      if (e.key == _face) continue;
      if (stickerDistance(lab, e.value[4].toLab()) < 10) {
        return 'Le centre de cette face ressemble à celui de la face '
            '${faceName(e.key)}. Avez-vous bien tourné le cube ?';
      }
    }
    return null;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _analyze() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final all = <Rgb>[];
    for (final f in Face.values) {
      all.addAll(_samples[f]!);
    }
    final result = classifyCube(all);
    final input = CubeInput();
    for (var i = 0; i < 54; i++) {
      input[i] = result.colors[i];
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManualInputPage(
          initial: input,
          uncertain: result.uncertain.toSet(),
          references: result.references,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = _samples.length == 6;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.singleFace != null
              ? 'Vérification'
              : 'Scanner : face ${_faceStep + 1}/6',
        ),
        actions: [
          if (_controller != null)
            IconButton(
              tooltip: _torch ? 'Éteindre la lampe' : 'Allumer la lampe',
              onPressed: _toggleTorch,
              icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = constraints.maxWidth.clamp(0.0, 480.0) - 32;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Face ${faceName(_face)}',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.singleFace != null
                      ? 'Photographiez la face qui est face à vous, sans '
                            'tourner le cube.'
                      : scanInstruction(_face),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Center(child: _preview(previewSize)),
                const SizedBox(height: 8),
                Text(
                  'Placez la face dans la grille, bien de face, sans reflet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Center(
                  child: complete
                      ? FilledButton.icon(
                          onPressed: _analyze,
                          icon: const Icon(Icons.check),
                          label: const Text('Analyser les couleurs'),
                        )
                      : FilledButton.icon(
                          onPressed: _controller == null || _busy
                              ? null
                              : _capture,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt),
                          label: const Text('Prendre la photo'),
                        ),
                ),
                if (widget.singleFace == null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Faces scannées (touchez une face pour la refaire)',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < 6; i++) _thumbnail(i, theme),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _preview(double size) {
    final controller = _controller;
    Widget content;
    if (_cameraError != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _cameraError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } else if (controller == null || !controller.value.isInitialized) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      // L'aperçu est recadré en carré centré, comme la photo analysée.
      final ratio = controller.value.aspectRatio; // largeur / hauteur (paysage)
      content = ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size,
              height: size * ratio,
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ],
      ),
    );
  }

  Widget _thumbnail(int i, ThemeData theme) {
    final face = inputOrder[i];
    final samples = _samples[face];
    final selected = i == _faceStep;
    return Semantics(
      button: true,
      label: 'Face ${faceName(face)}',
      child: GestureDetector(
        onTap: () => setState(() => _faceStep = i),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 42,
                child: samples == null
                    ? FaceGrid(colors: List.filled(9, null), size: 42)
                    : _RawFace(samples: samples, size: 42),
              ),
              Text(faceName(face), style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les 9 couleurs brutes mesurées sur une photo.
class _RawFace extends StatelessWidget {
  const _RawFace({required this.samples, required this.size});

  final List<Rgb> samples;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cell = size / 3;
    return Column(
      children: [
        for (var r = 0; r < 3; r++)
          Row(
            children: [
              for (var c = 0; c < 3; c++)
                Container(
                  width: cell - 2,
                  height: cell - 2,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: rgbColor(samples[r * 3 + c]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Grille de visée 3×3, de côté [gridFraction] × taille de l'aperçu.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * gridFraction;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    // Assombrit l'extérieur de la grille.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    canvas.drawPath(outside, Paint()..color = Colors.black45);

    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      line,
    );
    final cell = side / 3;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(rect.left + cell * i, rect.top),
        Offset(rect.left + cell * i, rect.bottom),
        line,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top + cell * i),
        Offset(rect.right, rect.top + cell * i),
        line,
      );
    }
    // Zones réellement mesurées (centre de chaque case).
    final dot = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final center = Offset(
          rect.left + cell * (c + 0.5),
          rect.top + cell * (r + 0.5),
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: cell * 0.5,
            height: cell * 0.5,
          ),
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
