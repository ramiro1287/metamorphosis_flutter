import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/users.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/picker/picker_select.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});
  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  late Map<String, dynamic> _form;
  final Map<String, String> _errors = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final gymInfo = context.read<GymProvider>().gymInfo;
    _form = {
      'id_number': '',
      'first_name': '',
      'last_name': '',
      'email': '',
      'phone': '',
      'country': 'AR',
      'is_retired': false,
      'role': traineeRole,
      'plan_id': (gymInfo?.plans.isNotEmpty ?? false) ? gymInfo!.plans[0]['id'] : null,
    };
  }

  bool _validate() {
    _errors.clear();
    final idNum = _form['id_number']?.toString() ?? '';
    if (idNum.isEmpty) {
      _errors['id_number'] = 'Ingresar DNI';
    } else if (!RegExp(r'^\d+$').hasMatch(idNum)) {
      _errors['id_number'] = 'El DNI debe ser un número entero';
    }
    if ((_form['first_name']?.toString() ?? '').isEmpty) {
      _errors['first_name'] = 'Ingresar nombre';
    }
    if ((_form['last_name']?.toString() ?? '').isEmpty) {
      _errors['last_name'] = 'Ingresar apellido';
    }
    if (_form['role'] == traineeRole && _form['plan_id'] == null) {
      _errors['plan_id'] = 'Un cliente debe tener un plan';
    }
    final email = _form['email']?.toString() ?? '';
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _errors['email'] = 'El email debe ser válido';
    }
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de crear el nuevo usuario?');
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final payload = Map<String, dynamic>.from(_form);
      if ((payload['phone'] as String? ?? '').isEmpty) payload['phone'] = null;
      await AuthService.post('/admin/users/create-user/', data: payload);
      AppToast.success('Usuario creado correctamente', '');
      if (mounted) context.pop();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        AppToast.error('',
            e.response?.data?['data']?['error_detail']?.toString() ?? '');
      } else {
        AppToast.error('Error al crear el usuario', '');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);
    final gymInfo = gymProvider.gymInfo;

    final planItems = [
      const PickerItem(label: 'Sin plan', value: null),
      ...(gymInfo?.plans ?? [])
          .map((p) => PickerItem(label: p['name']?.toString() ?? '', value: p['id'])),
    ];
    final countryItems = (gymInfo?.countries ?? {})
        .entries
        .map((e) => PickerItem(label: e.value.toString(), value: e.key))
        .toList();

    return ScrollContainer(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Nuevo Usuario',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, color: t.text)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
              color: t.secondBackground,
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('DNI', 'id_number', t,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10),
              _buildTextField('Email', 'email', t,
                  keyboardType: TextInputType.emailAddress,
                  placeholder: 'Sin e-mail'),
              _buildTextField('Nombre', 'first_name', t),
              _buildTextField('Apellido', 'last_name', t),
              _buildTextField('Teléfono', 'phone', t, placeholder: 'Sin teléfono'),

              // País del teléfono
              _Label('País del Teléfono:', t),
              PickerSelect(
                value: _form['country'],
                onValueChange: (v) => setState(() => _form['country'] = v),
                items: countryItems,
              ),
              const SizedBox(height: 12),

              // Plan
              _Label('Plan:', t),
              PickerSelect(
                value: _form['plan_id'],
                onValueChange: (v) {
                  setState(() {
                    _form['plan_id'] = v;
                    _errors.remove('plan_id');
                  });
                },
                items: planItems,
              ),
              if (_errors['plan_id'] != null)
                _ErrorText(_errors['plan_id']!, t),
              const SizedBox(height: 12),

              // ¿Es jubilado?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('¿Es jubilado?',
                      style: TextStyle(color: t.secondText, fontSize: 16)),
                  Switch(
                    value: _form['is_retired'] as bool,
                    onChanged: (v) => setState(() => _form['is_retired'] = v),
                    activeColor: buttonTextConfirmDark,
                    inactiveThumbColor: errorButtonTextDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Center(
                child: TouchableButton(
                  title: 'Crear usuario',
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

  Widget _buildTextField(String label, String key, AppThemeColors t,
      {TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      int? maxLength,
      String? placeholder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('$label:', t),
        TextField(
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: TextStyle(fontSize: 16, color: t.text),
          onChanged: (v) => setState(() {
            _form[key] = v;
            _errors.remove(key);
          }),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: t.secondText),
            counterText: '',
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: _errors[key] != null ? t.inputError : t.text)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: _errors[key] != null ? t.inputError : t.text,
                    width: 2)),
          ),
        ),
        if (_errors[key] != null) _ErrorText(_errors[key]!, t),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _Label(this.text, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(color: t.secondText, fontSize: 16)),
      );
}

class _ErrorText extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _ErrorText(this.text, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(text,
            style: TextStyle(color: t.inputError, fontSize: 14)),
      );
}
