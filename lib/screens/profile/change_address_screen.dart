import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_theme.dart';
import '../../components/containers/form_container.dart';
import '../../components/buttons/touchable_button.dart';
import '../../components/alerts/confirm_dialog.dart';
import '../../components/picker/picker_select.dart';
import '../../components/toast/app_toast.dart';
import '../../services/auth_service.dart';

class ChangeAddressScreen extends StatefulWidget {
  const ChangeAddressScreen({super.key});

  @override
  State<ChangeAddressScreen> createState() => _ChangeAddressScreenState();
}

class _ChangeAddressScreenState extends State<ChangeAddressScreen> {
  String _state = 'AR-X';
  final _cityCtrl = TextEditingController(text: 'Cruz Del Eje');
  final _addressCtrl = TextEditingController();

  String _cityError = '';
  String _addressError = '';
  bool _loading = false;

  @override
  void dispose() {
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _cityError = '';
      _addressError = '';
    });
    if (_cityCtrl.text.trim().isEmpty) {
      setState(() => _cityError = 'Ingresa tu ciudad');
      ok = false;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() => _addressError = 'Ingresa tu dirección');
      ok = false;
    }
    return ok;
  }

  Future<void> _handleChangeAddress() async {
    if (!_validate()) return;

    final ok = await showConfirmDialog(
      context,
      '¿Estás seguro de cambiar tu dirección?',
    );
    if (!ok) return;

    setState(() => _loading = true);
    try {
      await AuthService.put('/users/me/', data: {
        'address': {
          'state': _state,
          'city': _cityCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
        },
      });
      if (mounted) {
        context.read<GymProvider>().refreshUser();
        AppToast.success('Dirección actualizada', '');
        context.pop();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail =
            e.response?.data?['data']?['error_detail']?.toString() ?? '';
        AppToast.error(detail, '');
      } else {
        AppToast.error('Error', 'No se pudo cambiar tu dirección');
      }
    } catch (_) {
      AppToast.error('Error', 'Error de conexión');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _state = 'AR-X';
          _cityCtrl.text = 'Cruz Del Eje';
          _addressCtrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);

    // gymInfo.states es Map<String, String>: {'AR-X': 'Córdoba', 'AR-B': 'Buenos Aires', ...}
    final stateItems = _buildStateItems(gymProvider.gymInfo?.states ?? {});

    return FormContainer(
      children: [
        // ---- Provincia ----
        _SectionTitle('Provincia', t),
        PickerSelect(
          value: _state,
          onValueChange: (val) => setState(() => _state = val.toString()),
          items: stateItems,
        ),
        const SizedBox(height: 8),

        // ---- Ciudad ----
        _SectionTitle('Ciudad', t),
        _StyledInput(
          controller: _cityCtrl,
          placeholder: 'Escribe tu ciudad...',
          hasError: _cityError.isNotEmpty,
          t: t,
          onChanged: (_) => setState(() => _cityError = ''),
        ),
        if (_cityError.isNotEmpty) _ErrorText(_cityError, t),

        // ---- Dirección ----
        _SectionTitle('Dirección', t),
        _StyledInput(
          controller: _addressCtrl,
          placeholder: 'Escribe tu dirección...',
          hasError: _addressError.isNotEmpty,
          t: t,
          onChanged: (_) => setState(() => _addressError = ''),
        ),
        if (_addressError.isNotEmpty) _ErrorText(_addressError, t),

        const SizedBox(height: 25),
        TouchableButton(
          title: 'Cambiar Dirección',
          onPress: _handleChangeAddress,
          loading: _loading,
        ),
      ],
    );
  }

  List<PickerItem> _buildStateItems(Map<String, dynamic> states) {
    return states.entries
        .map((e) => PickerItem(label: e.value.toString(), value: e.key))
        .toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _SectionTitle(this.text, this.t);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 6),
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

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool hasError;
  final AppThemeColors t;
  final ValueChanged<String>? onChanged;

  const _StyledInput({
    required this.controller,
    required this.placeholder,
    required this.hasError,
    required this.t,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 18, color: t.text),
        onChanged: onChanged,
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(color: t.inputError, fontSize: 16)),
      );
}
