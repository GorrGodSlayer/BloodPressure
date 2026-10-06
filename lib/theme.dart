import 'package:flutter/material.dart';

const _seed = Color(0xFF1E88E5);
const _gradientTop = Color(0xFFFFFFFF);
const _gradientBottom = Color(0xFF90CAF9);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seed);
  final glass = Colors.white.withValues(alpha: 0.8);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // Screens draw their own gradient via [GradientBackground].
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: glass,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: glass),
  );
}

/// White-to-blue backdrop placed behind each screen's [Scaffold].
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_gradientTop, _gradientBottom],
        ),
      ),
      child: child,
    );
  }
}
