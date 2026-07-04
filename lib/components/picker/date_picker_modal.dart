import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../context/gym_provider.dart';

// Equivalente a client/src/components/Picker/DatePickerModal.jsx
// Usa el DatePicker nativo de Flutter (Material) que funciona en todas las plataformas.
// La API es más simple que el equivalente RN ya que showDatePicker() devuelve un Future<DateTime?>.

/// Muestra un date picker temado y devuelve la fecha seleccionada (o null si se canceló).
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final isDarkMode = context.read<GymProvider>().isDarkMode;
  final t = getThemeColors(isDarkMode);

  return showDatePicker(
    context: context,
    // useRootNavigator: false evita que go_router interprete el cierre
    // del dialog como un cambio de ruta y corrompa el stack de navegación.
    // showDatePicker usa true por defecto, lo sobreescribimos explícitamente.
    useRootNavigator: false,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
    builder: (ctx, child) {
      // Aplicamos los colores del tema de la app al DatePicker de Flutter
      return Theme(
        data: ThemeData(
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          colorScheme: isDarkMode
              ? ColorScheme.dark(
                  primary: t.buttonBackground,
                  onPrimary: t.buttonText,
                  surface: t.secondBackground,
                  onSurface: t.text,
                )
              : ColorScheme.light(
                  primary: t.buttonBackground,
                  onPrimary: t.buttonText,
                  surface: t.secondBackground,
                  onSurface: t.text,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: t.secondBackground,
          ),
        ),
        child: child!,
      );
    },
  );
}
