import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

// Equivalente a client/src/components/Toast/Toast.js
// Usa ScaffoldMessengerKey global para mostrar toasts sin contexto.

enum _ToastType { success, error, info }

/// Clave global para acceder al ScaffoldMessenger desde cualquier lugar.
/// Se asigna al MaterialApp en main.dart.
class AppToast {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // isDarkMode se actualiza desde GymProvider cada vez que cambia el tema
  static bool _isDarkMode = false;

  static void updateTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  // -------------------------------------------------------
  // API pública (equivalente a toastSuccess/Error/Info de Toast.js)
  // -------------------------------------------------------

  static void success(String title, String message) =>
      _show(title, message, _ToastType.success);

  static void error(String title, String message) =>
      _show(title, message, _ToastType.error);

  static void info(String title, String message) =>
      _show(title, message, _ToastType.info);

  // -------------------------------------------------------
  // Implementación interna
  // -------------------------------------------------------

  static void _show(String title, String message, _ToastType type) {
    final state = messengerKey.currentState;
    if (state == null) return;
    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        content: _ToastContent(
          title: title,
          message: message,
          type: type,
          isDarkMode: _isDarkMode,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
      ),
    );
  }
}

class _ToastContent extends StatelessWidget {
  final String title;
  final String message;
  final _ToastType type;
  final bool isDarkMode;

  const _ToastContent({
    required this.title,
    required this.message,
    required this.type,
    required this.isDarkMode,
  });

  Color get _borderColor {
    switch (type) {
      case _ToastType.success:
        return isDarkMode ? buttonTextConfirmDark : buttonTextConfirmLight;
      case _ToastType.error:
        return isDarkMode ? errorButtonTextDark : errorButtonTextLight;
      case _ToastType.info:
        return isDarkMode ? buttonBackgroundDark : buttonBackgroundLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    return Container(
      decoration: BoxDecoration(
        color: t.secondBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _borderColor, width: 5),
          top: BorderSide(color: _borderColor, width: 0.5),
          right: BorderSide(color: _borderColor, width: 0.5),
          bottom: BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: t.text),
            ),
          ],
        ],
      ),
    );
  }
}
