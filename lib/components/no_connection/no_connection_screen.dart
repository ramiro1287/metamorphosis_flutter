import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../context/gym_provider.dart';
import '../buttons/touchable_button.dart';

// Equivalente a client/src/components/NoConnection/NoConnectionScreen.jsx

class NoConnectionScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoConnectionScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Scaffold(
      backgroundColor: t.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: t.secondText),
              const SizedBox(height: 15),
              Text(
                'Sin conexión',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No se pudo conectar al servidor. Verificá tu conexión a internet e intentá de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: t.secondText),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: TouchableButton(
                  title: 'Reintentar',
                  onPress: onRetry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
