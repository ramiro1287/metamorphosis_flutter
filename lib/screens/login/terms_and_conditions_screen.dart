import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/environment.dart';
import '../../components/buttons/touchable_button.dart';
import '../../components/containers/form_container.dart';
import '../../components/toast/app_toast.dart';
import '../../services/auth_service.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _accepted = false;
  bool _loading = false;

  Future<void> _handleAccept() async {
    if (!_accepted) return;
    setState(() => _loading = true);
    try {
      await AuthService.post('/users/accept-terms/');
      if (mounted) {
        context.read<GymProvider>().markTermsAccepted();
      }
    } catch (_) {
      AppToast.error('Error', 'No se pudieron aceptar los términos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleReject() async {
    await context.read<GymProvider>().handleLogout();
  }

  void _openTerms() {
    launchUrl(
      Uri.parse('$baseServerUrl/static/docs/MetamorphosisGym_TyCs.pdf'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Scaffold(
      backgroundColor: t.background,
      body: FormContainer(
        children: [
          const SizedBox(height: 60),
          // Logo
          Image.asset(
            isDarkMode ? 'assets/logo.png' : 'assets/logo_color.png',
            width: 300,
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 30),
          // Título
          Text(
            'Términos y Condiciones',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
          const SizedBox(height: 20),
          // Descripción con links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: t.secondText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Para continuar usando la aplicación, debés aceptar nuestros ',
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openTerms,
                      child: Text(
                        'Términos & Condiciones',
                        style: TextStyle(
                          color: t.secondText,
                          fontSize: 18,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' y '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openTerms,
                      child: Text(
                        'Políticas de Privacidad',
                        style: TextStyle(
                          color: t.secondText,
                          fontSize: 18,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Checkbox
          GestureDetector(
            onTap: () => setState(() => _accepted = !_accepted),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox manual (igual al de RN)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.buttonBorder, width: 2),
                      color: _accepted ? t.buttonBackground : Colors.transparent,
                    ),
                    child: _accepted
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: isDarkMode ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Acepto los Términos & Condiciones y Políticas de Privacidad',
                      style: TextStyle(fontSize: 15, color: t.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TouchableButton(
                title: 'Aceptar',
                onPress: _handleAccept,
                loading: _loading,
                disabled: !_accepted,
              ),
              const SizedBox(width: 12),
              TouchableButton(
                title: 'No Aceptar',
                onPress: _handleReject,
                variant: ButtonVariant.error,
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
