import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminFamilyCreateScreen extends StatefulWidget {
  const AdminFamilyCreateScreen({super.key});
  @override
  State<AdminFamilyCreateScreen> createState() =>
      _AdminFamilyCreateScreenState();
}

class _AdminFamilyCreateScreenState extends State<AdminFamilyCreateScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _nameError = '';
  String _descError = '';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() { _nameError = ''; _descError = ''; });
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = 'Ingresar nombre de la familia');
      ok = false;
    }
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _descError = 'Ingresar alguna descripción');
      ok = false;
    }
    return ok;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de crear la nueva familia?');
    if (!ok) return;

    setState(() => _loading = true);
    try {
      await AuthService.post('/admin/users/family/', data: {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      });
      AppToast.success('Familia creada correctamente', '');
      if (mounted) context.pop();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail =
            e.response?.data?['data']?['error_detail']?.toString() ?? '';
        AppToast.error('', detail);
      } else {
        AppToast.error('Error al crear la familia', '');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        Text('Nueva Familia',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, color: t.text)),
        const SizedBox(height: 20),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: t.secondBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormField(label: 'Nombre:', ctrl: _nameCtrl, t: t,
                  error: _nameError, onChanged: (_) => setState(() => _nameError = '')),
              _FormField(label: 'Descripción:', ctrl: _descCtrl, t: t,
                  error: _descError, onChanged: (_) => setState(() => _descError = '')),
              const SizedBox(height: 10),
              Center(
                child: TouchableButton(
                  title: 'Crear familia',
                  onPress: _handleSubmit,
                  loading: _loading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final AppThemeColors t;
  final String error;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.label, required this.ctrl, required this.t,
    required this.error, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(label, style: TextStyle(fontSize: 16, color: t.secondText)),
        ),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 16, color: t.text),
          onChanged: onChanged,
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: error.isNotEmpty ? t.inputError : t.text)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: error.isNotEmpty ? t.inputError : t.text,
                    width: 2)),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error,
                style: TextStyle(color: t.inputError, fontSize: 14)),
          ),
      ],
    );
  }
}
