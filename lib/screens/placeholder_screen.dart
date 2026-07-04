import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../context/gym_provider.dart';

// Widget placeholder genérico para screens aún no migradas.
// Se irá reemplazando pantalla a pantalla.

class PlaceholderScreen extends StatelessWidget {
  final String name;
  const PlaceholderScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    return Scaffold(
      backgroundColor: t.background,
      body: Center(
        child: Text(
          name,
          style: TextStyle(color: t.secondText, fontSize: 18),
        ),
      ),
    );
  }
}
