import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../ads/ad_banner.dart';
import '../cube/cube.dart';
import '../l10n/l10n_scope.dart';
import 'about_sheet.dart';
import 'cube_3d.dart';
import 'cube_widgets.dart';
import 'manual_input_page.dart';
import 'scan_page.dart';

/// Couleurs du dégradé de l'accueil (les mêmes que l'icône).
const Color brandViolet = Color(0xFF7C4DFF);
const Color brandBlue = Color(0xFF2979FF);
const Color brandCyan = Color(0xFF00B0FF);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tr;
    final language = L10nScope.controllerOf(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandViolet, brandBlue, brandCyan],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _Confetti())),
            ),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (language != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              showLanguagePicker(context, language),
                          icon: const Icon(Icons.language),
                          label: Text(t.language.name.toUpperCase()),
                        ),
                      IconButton(
                        tooltip: t.about,
                        color: Colors.white,
                        onPressed: () => showAboutSheet(context),
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedCube(
                                size: min(constraints.maxWidth * 0.6, 240),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cube Solver',
                                textAlign: TextAlign.center,
                                style: text.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.tagline,
                                textAlign: TextAlign.center,
                                style: text.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _Steps(),
                              const SizedBox(height: 32),
                              _BigButton(
                                icon: Icons.photo_camera_rounded,
                                label: t.scanMyCube,
                                filled: true,
                                onPressed: () =>
                                    _open(context, const ScanPage()),
                              ),
                              const SizedBox(height: 12),
                              _BigButton(
                                icon: Icons.grid_view_rounded,
                                label: t.enterColors,
                                filled: false,
                                onPressed: () =>
                                    _open(context, const ManualInputPage()),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const AdBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les trois étapes, en pastilles.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final steps = [
      (t.stepScan, CubeColor.yellow),
      (t.stepCheck, CubeColor.green),
      (t.stepSolve, CubeColor.orange),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (var i = 0; i < steps.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: displayColor(steps[i].$2),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    steps[i].$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 58)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        // Réduit le texte s'il ne tient pas (langues longues, grande police).
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: filled
          ? FilledButton(
              style: style.copyWith(
                backgroundColor: const WidgetStatePropertyAll(Colors.white),
                foregroundColor: const WidgetStatePropertyAll(
                  Color(0xFF3D2DB5),
                ),
                elevation: const WidgetStatePropertyAll(6),
                shadowColor: const WidgetStatePropertyAll(Colors.black45),
              ),
              onPressed: onPressed,
              child: child,
            )
          : OutlinedButton(
              style: style.copyWith(
                foregroundColor: const WidgetStatePropertyAll(Colors.white),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Colors.white70, width: 2),
                ),
              ),
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}

/// Cube qui enchaîne en boucle R U R' U' (6 fois = retour au cube résolu),
/// avec la flèche du mouvement en cours.
class AnimatedCube extends StatefulWidget {
  const AnimatedCube({super.key, required this.size});

  final double size;

  @override
  State<AnimatedCube> createState() => _AnimatedCubeState();
}

class _AnimatedCubeState extends State<AnimatedCube>
    with SingleTickerProviderStateMixin {
  static final _sequence = Move.parseSequence("R U R' U'");
  final _cube = CubieCube();
  int _index = 0;
  Timer? _timer;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _timer?.cancel();
      _timer = null;
      _float.stop();
    } else if (_timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
        setState(() {
          _cube.applyMove(_sequence[_index % _sequence.length]);
          _index++;
        });
      });
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [for (final f in _cube.toFacelets()) standardScheme[f]!];
    final next = _timer == null ? null : _sequence[_index % _sequence.length];
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_float.value)),
        child: child,
      ),
      child: ExcludeSemantics(
        child: Cube3DView(colors: colors, move: next, size: widget.size),
      ),
    );
  }
}

/// Autocollants colorés éparpillés en fond, à des positions fixes.
class _Confetti extends CustomPainter {
  const _Confetti();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    for (var i = 0; i < 22; i++) {
      final color = displayColor(CubeColor.values[i % 6]);
      final s = 14.0 + rnd.nextDouble() * 26;
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rnd.nextDouble() * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          Radius.circular(s * 0.22),
        ),
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti oldDelegate) => false;
}
