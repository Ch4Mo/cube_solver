import 'package:material_ui/material_ui.dart';

import 'ui/home_page.dart';

void main() {
  runApp(const CubeSolverApp());
}

class CubeSolverApp extends StatelessWidget {
  const CubeSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cube Solver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}
