import 'package:material_ui/material_ui.dart';

import 'ads/ads.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CubeSolverApp());
  // Consentement et publicité, sans bloquer l'affichage.
  Ads.init();
}

class CubeSolverApp extends StatelessWidget {
  const CubeSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cube Solver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4BE0)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B4BE0),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}
