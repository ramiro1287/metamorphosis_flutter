import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/environment.dart';
import '../../components/buttons/touchable_button.dart';
import '../../components/containers/form_container.dart';
import '../../components/toast/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _usernameError = '';
  String _passwordError = '';
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _usernameError = '';
      _passwordError = '';
    });

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Ingresa tu DNI');
      ok = false;
    } else if (!RegExp(r'^\d+$').hasMatch(username)) {
      setState(() => _usernameError = 'El DNI debe ser un número válido');
      ok = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Ingresa tu contraseña');
      ok = false;
    }

    return ok;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      // Usamos Dio directo (sin auth) para el endpoint de login
      final dio = Dio(BaseOptions(baseUrl: baseServerUrl));
      final response = await dio.post(
        '/auth/login/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        },
      );

      final access = response.data['access'] as String?;
      final refresh = response.data['refresh'] as String?;

      if (access != null && refresh != null && mounted) {
        await context.read<GymProvider>().handleLogin(access, refresh);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail = e.response?.data?['data']?['error_detail']?.toString()
            ?? 'Credenciales incorrectas';
        AppToast.error(detail, '');
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    } catch (_) {
      AppToast.error('Error', 'Error al iniciar sesión');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            'Iniciar sesión',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
          const SizedBox(height: 20),
          // Campo DNI
          SizedBox(
            width: '80%'.isEmpty ? double.infinity : MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: _usernameCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 18, color: t.text),
              decoration: _inputDecoration(
                placeholder: 'DNI',
                hasError: _usernameError.isNotEmpty,
                t: t,
              ),
              onChanged: (_) => setState(() => _usernameError = ''),
            ),
          ),
          if (_usernameError.isNotEmpty)
            _ErrorText(_usernameError, t),
          const SizedBox(height: 4),
          // Campo Contraseña
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              style: TextStyle(fontSize: 18, color: t.text),
              decoration: _inputDecoration(
                placeholder: 'Contraseña',
                hasError: _passwordError.isNotEmpty,
                t: t,
              ).copyWith(
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: t.text,
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _passwordError = ''),
              onSubmitted: (_) => _handleLogin(),
            ),
          ),
          if (_passwordError.isNotEmpty)
            _ErrorText(_passwordError, t),
          const SizedBox(height: 20),
          // Botón ingresar
          TouchableButton(
            title: 'Ingresar',
            onPress: _handleLogin,
            loading: _loading,
          ),
          const SizedBox(height: 20),
          // Texto de T&C
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: t.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'Al usar esta aplicación, aceptás nuestros '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openTerms,
                      child: Text(
                        'Términos & Condiciones',
                        style: TextStyle(
                          color: t.text,
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
                          color: t.text,
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
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String placeholder,
    required bool hasError,
    required AppThemeColors t,
  }) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: TextStyle(color: t.text.withAlpha(153)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: hasError ? t.inputError : t.text),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: hasError ? t.inputError : t.text, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _ErrorText(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
        child: Text(text, style: TextStyle(color: t.inputError, fontSize: 16)),
      ),
    );
  }
}
