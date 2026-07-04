import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_theme.dart';
import '../../components/containers/form_container.dart';
import '../../components/buttons/touchable_button.dart';
import '../../components/toast/app_toast.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _new2Ctrl = TextEditingController();

  String _oldError = '';
  String _newError = '';
  String _new2Error = '';
  bool _showOld = false;
  bool _showNew = false;
  bool _showNew2 = false;
  bool _loading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _new2Ctrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _oldError = '';
      _newError = '';
      _new2Error = '';
    });

    if (_oldCtrl.text.trim().isEmpty) {
      setState(() => _oldError = 'Ingresa tu contraseña actual');
      ok = false;
    }

    if (_newCtrl.text.trim().isEmpty) {
      setState(() => _newError = 'Ingresa tu nueva contraseña');
      ok = false;
    } else if (_newCtrl.text.trim().length < 6) {
      setState(() => _newError = 'La contraseña debe tener 6 caracteres');
      ok = false;
    }

    if (_new2Ctrl.text.trim().isEmpty) {
      setState(() => _new2Error = 'Repita la contraseña');
      ok = false;
    } else if (_new2Ctrl.text.trim().length < 6) {
      setState(() => _new2Error = 'La contraseña debe tener 6 caracteres');
      ok = false;
    }

    if (!ok) return false;

    if (_newCtrl.text != _new2Ctrl.text) {
      setState(() => _new2Error = 'Las contraseñas nuevas no coinciden');
      return false;
    }

    if (_newCtrl.text == _oldCtrl.text) {
      setState(() => _oldError = 'La nueva contraseña es igual a la vieja contraseña');
      return false;
    }

    return true;
  }

  Future<void> _handleChangePassword() async {
    if (!_validate()) return;
    setState(() => _loading = true);

    try {
      await AuthService.post(
        '/users/password/',
        data: {
          'old_password': _oldCtrl.text.trim(),
          'new_password': _newCtrl.text.trim(),
        },
      );
      if (mounted) {
        AppToast.success('Contraseña actualizada', '');
        context.pop();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail =
            e.response?.data?['data']?['error_detail']?.toString() ?? '';
        AppToast.error(detail, '');
      } else {
        AppToast.error('Error', 'No se pudo cambiar tu contraseña');
      }
    } catch (_) {
      AppToast.error('Error', 'Error de conexión');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _oldCtrl.clear();
          _newCtrl.clear();
          _new2Ctrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return FormContainer(
      children: [
        _SectionTitle('Contraseña Actual', t),
        _PasswordField(
          controller: _oldCtrl,
          placeholder: 'Contraseña Actual',
          show: _showOld,
          hasError: _oldError.isNotEmpty,
          t: t,
          onToggle: () => setState(() => _showOld = !_showOld),
          onChanged: (_) => setState(() => _oldError = ''),
        ),
        if (_oldError.isNotEmpty) _ErrorText(_oldError, t),

        _SectionTitle('Nueva Contraseña', t),
        _PasswordField(
          controller: _newCtrl,
          placeholder: 'Nueva Contraseña',
          show: _showNew,
          hasError: _newError.isNotEmpty,
          t: t,
          onToggle: () => setState(() => _showNew = !_showNew),
          onChanged: (_) => setState(() => _newError = ''),
        ),
        if (_newError.isNotEmpty) _ErrorText(_newError, t),

        _SectionTitle('Repita Contraseña', t),
        _PasswordField(
          controller: _new2Ctrl,
          placeholder: 'Repita Contraseña',
          show: _showNew2,
          hasError: _new2Error.isNotEmpty,
          t: t,
          onToggle: () => setState(() => _showNew2 = !_showNew2),
          onChanged: (_) => setState(() => _new2Error = ''),
          onSubmitted: (_) => _handleChangePassword(),
        ),
        if (_new2Error.isNotEmpty) _ErrorText(_new2Error, t),

        const SizedBox(height: 20),
        TouchableButton(
          title: 'Cambiar Contraseña',
          onPress: _handleChangePassword,
          loading: _loading,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _SectionTitle(this.text, this.t);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: t.text)),
        ),
      );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool show;
  final bool hasError;
  final AppThemeColors t;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.placeholder,
    required this.show,
    required this.hasError,
    required this.t,
    required this.onToggle,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextField(
        controller: controller,
        obscureText: !show,
        style: TextStyle(fontSize: 18, color: t.text),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: t.text.withAlpha(153)),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: hasError ? t.inputError : t.text),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: hasError ? t.inputError : t.text, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              show ? Icons.visibility : Icons.visibility_off,
              color: t.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _ErrorText(this.text, this.t);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: TextStyle(color: t.inputError, fontSize: 16)),
        ),
      );
}
