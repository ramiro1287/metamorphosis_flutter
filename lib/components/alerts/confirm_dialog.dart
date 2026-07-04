import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_colors.dart';
import '../../context/gym_provider.dart';

// Equivalente a client/src/components/Alerts/ConfirmModalAlert.jsx
//
// En lugar de la API imperativa global de RN (showConfirmModalAlert),
// en Flutter usamos showDialog() que ya devuelve un Future<bool> nativamente.
// Uso:
//   final ok = await showConfirmDialog(context, '¿Estás seguro?');
//   if (!ok) return;

Future<bool> showConfirmDialog(
  BuildContext context,
  String message, {
  String cancelMsg = 'Cancelar',
  String confirmMsg = 'Continuar',
}) async {
  final result = await showDialog<bool>(
    context: context,
    // useRootNavigator: false evita que go_router interprete el cierre del
    // dialog como un pop de ruta y corrompa el stack de navegación.
    // showDialog usa useRootNavigator: true por defecto en Flutter.
    useRootNavigator: false,
    barrierDismissible: false,
    builder: (ctx) => _ConfirmDialog(
      message: message,
      cancelMsg: cancelMsg,
      confirmMsg: confirmMsg,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  final String message;
  final String cancelMsg;
  final String confirmMsg;

  const _ConfirmDialog({
    required this.message,
    required this.cancelMsg,
    required this.confirmMsg,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: t.secondBackground,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 17,
                  ),
                ),
              ),
              Divider(height: 0.5, color: isDarkMode ? buttonBorderDark : buttonBorderLight),
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Botón cancelar
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          cancelMsg,
                          style: TextStyle(
                            color: isDarkMode ? buttonTextCancelDark : buttonTextCancelLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: 0.5,
                      color: isDarkMode ? buttonBorderDark : buttonBorderLight,
                    ),
                    // Botón confirmar
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          confirmMsg,
                          style: TextStyle(
                            color: isDarkMode ? buttonTextConfirmDark : buttonTextConfirmLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
