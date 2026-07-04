import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../context/gym_provider.dart';

// Equivalente a client/src/components/Loading/LoadingScreen.jsx

class LoadingScreen extends StatelessWidget {
  final Color? backgroundColor;

  const LoadingScreen({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor ?? t.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: isDarkMode ? defaultButtonTextLight : defaultButtonTextDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 20,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
