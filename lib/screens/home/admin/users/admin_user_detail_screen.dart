import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/users.dart';
import '../../../../components/loading/loading_screen.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/picker/picker_select.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String idNumber;
  const AdminUserDetailScreen({super.key, required this.idNumber});
  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  Map<String, dynamic>? _userDetail;
  bool _connectionError = false;
  late String _currentIdNumber;

  @override
  void initState() {
    super.initState();
    _currentIdNumber = widget.idNumber;
    _load();
  }

  Future<void> _load([String? overrideId]) async {
    final id = overrideId ?? _currentIdNumber;
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get('/admin/users/detail/$id/');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _userDetail = data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  void _openEdit(String field) {
    dynamic initialValue;
    switch (field) {
      case 'full_name':
        initialValue = {
          'first_name': _userDetail!['first_name'] ?? '',
          'last_name': _userDetail!['last_name'] ?? '',
        };
        break;
      case 'plan':
        initialValue = _userDetail!['plan']?['id'];
        break;
      case 'is_retired':
        initialValue = (_userDetail!['is_retired'] as bool? ?? false) ? 1 : 0;
        break;
      default:
        initialValue = _userDetail![field] ?? '';
    }

    final isDarkMode = context.read<GymProvider>().isDarkMode;
    final gymInfo = context.read<GymProvider>().gymInfo;
    final t = getThemeColors(isDarkMode);

    // ----------------------------------------------------------------
    // Controllers creados UNA SOLA VEZ fuera de buildInput.
    // Si se crean dentro de buildInput, cada llamada a setS() recrea el
    // controller reseteando la posición del cursor → texto "espejado".
    // ----------------------------------------------------------------
    final initialMap = field == 'full_name'
        ? initialValue as Map<String, dynamic>
        : <String, dynamic>{};
    final firstNameCtrl =
        TextEditingController(text: initialMap['first_name']?.toString() ?? '');
    final lastNameCtrl =
        TextEditingController(text: initialMap['last_name']?.toString() ?? '');
    final textCtrl = TextEditingController(
        text: field != 'full_name' ? initialValue?.toString() ?? '' : '');

    // ----------------------------------------------------------------
    // buildInput ya NO toma curVal: lee initialValue y los controllers
    // directamente desde el closure de _openEdit.
    // ----------------------------------------------------------------
    Widget buildInput(dynamic curErr, void Function(void Function()) setS) {
      if (field == 'plan') {
        final plans = gymInfo?.plans ?? [];
        return PickerSelect(
          value: initialValue,
          onValueChange: (v) => setS(() => initialValue = v),
          items: [
            const PickerItem(label: 'Sin plan', value: null),
            ...plans.map((p) => PickerItem(
                label: p['name']?.toString() ?? '', value: p['id'])),
          ],
        );
      }
      if (field == 'is_retired') {
        return PickerSelect(
          value: initialValue,
          onValueChange: (v) => setS(() => initialValue = v),
          items: const [
            PickerItem(label: 'No', value: 0),
            PickerItem(label: 'Sí', value: 1),
          ],
        );
      }
      if (field == 'status') {
        return PickerSelect(
          value: initialValue,
          onValueChange: (v) => setS(() => initialValue = v),
          items: const [
            PickerItem(label: 'Activo', value: statusActive),
            PickerItem(label: 'Inactivo', value: statusDeleted),
          ],
        );
      }
      if (field == 'role') {
        return PickerSelect(
          value: initialValue,
          onValueChange: (v) => setS(() => initialValue = v),
          items: const [
            PickerItem(label: 'Cliente', value: traineeRole),
            PickerItem(label: 'Entrenador', value: coachRole),
            PickerItem(label: 'Administrador', value: adminRole),
          ],
        );
      }
      if (field == 'full_name') {
        final errMap = curErr as Map<String, String>?;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: firstNameCtrl,
            // NO setS en onChanged: evita reconstrucción del dialog
            onChanged: (v) {
              final m = Map<String, dynamic>.from(initialValue as Map);
              m['first_name'] = v;
              initialValue = m;
            },
            style: TextStyle(color: t.text),
            decoration: _inputDeco('Nombre', t),
          ),
          if (errMap?['first_name'] != null)
            Text(errMap!['first_name']!,
                style: TextStyle(color: t.inputError, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: lastNameCtrl,
            onChanged: (v) {
              final m = Map<String, dynamic>.from(initialValue as Map);
              m['last_name'] = v;
              initialValue = m;
            },
            style: TextStyle(color: t.text),
            decoration: _inputDeco('Apellido', t),
          ),
          if (errMap?['last_name'] != null)
            Text(errMap!['last_name']!,
                style: TextStyle(color: t.inputError, fontSize: 13)),
        ]);
      }
      // Default: TextField (texto libre)
      return Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: textCtrl,
          // NO setS: el TextField gestiona su propio display
          onChanged: (v) => initialValue = v,
          style: TextStyle(color: t.text),
          decoration: _inputDeco(
              field == 'phone'
                  ? 'Sin teléfono...'
                  : 'Editar ${_fieldLabel(field)}',
              t),
        ),
        if (curErr is String)
          Text(curErr, style: TextStyle(color: t.inputError, fontSize: 13)),
      ]);
    }

    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        dynamic curErr;
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            backgroundColor: t.secondBackground,
            title: Text('Editar ${_fieldLabel(field)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.text, fontSize: 18)),
            content: SingleChildScrollView(
                child: buildInput(curErr, setS)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancelar',
                    style: TextStyle(color: t.buttonTextCancel)),
              ),
              TextButton(
                onPressed: () {
                  // Para full_name: sync desde controllers antes de validar
                  if (field == 'full_name') {
                    initialValue = {
                      'first_name': firstNameCtrl.text,
                      'last_name': lastNameCtrl.text,
                    };
                    final fn = firstNameCtrl.text.trim();
                    final ln = lastNameCtrl.text.trim();
                    final err = <String, String>{};
                    if (fn.isEmpty) err['first_name'] = 'El nombre no puede estar vacío';
                    if (ln.isEmpty) err['last_name'] = 'El apellido no puede estar vacío';
                    if (err.isNotEmpty) { setS(() => curErr = err); return; }
                  } else if (field == 'email') {
                    final v = (initialValue as String? ?? '').trim();
                    if (v.isNotEmpty &&
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                      setS(() => curErr = 'El email no es válido');
                      return;
                    }
                  }
                  Navigator.of(ctx).pop();
                  _performSave(field, initialValue);
                },
                child: Text('Guardar',
                    style: TextStyle(color: t.buttonTextConfirm)),
              ),
            ],
          );
        });
      },
    ).then((_) {
      // Dispose controllers al cerrar el dialog
      firstNameCtrl.dispose();
      lastNameCtrl.dispose();
      textCtrl.dispose();
    });
  }

  InputDecoration _inputDeco(String hint, AppThemeColors t) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.secondText),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: t.text, width: 2)),
      );

  Future<void> _performSave(String field, dynamic value) async {
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de actualizar el campo del usuario?');
    if (!ok) return;

    final payload = <String, dynamic>{};
    if (field == 'full_name') {
      payload['first_name'] = (value['first_name'] as String? ?? '').trim();
      payload['last_name'] = (value['last_name'] as String? ?? '').trim();
    } else if (field == 'email') {
      payload['email'] = (value as String).trim();
    } else if (field == 'plan') {
      payload['plan_id'] = value;
    } else if (field == 'phone') {
      final v = (value as String? ?? '').trim();
      payload['phone'] = v.isEmpty ? null : v;
      if (v.isNotEmpty) payload['country'] = 'AR';
    } else if (field == 'is_retired') {
      payload['is_retired'] = value == 1;
    } else {
      payload[field] = value;
    }

    try {
      await AuthService.put('/admin/users/update-user/$_currentIdNumber/', data: payload);
      AppToast.success('Campo actualizado correctamente', '');
      if (field == 'id_number') {
        _currentIdNumber = value.toString();
        _load(_currentIdNumber);
      } else {
        _load();
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error(detail.isNotEmpty ? detail : 'Error',
          'No se pudo actualizar el campo');
    }
  }

  Future<void> _handleResetPassword() async {
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de restablecer la contraseña del usuario?');
    if (!ok) return;
    try {
      await AuthService.post(
          '/admin/users/reset-user-password/$_currentIdNumber/');
      AppToast.success('Contraseña restablecida', '');
    } on DioException catch (_) {
      AppToast.error('Error', 'Error de conexión');
    }
  }

  String _fieldLabel(String field) {
    const map = {
      'full_name': 'nombre completo',
      'status': 'estado',
      'is_retired': 'si es jubilado',
      'phone': 'teléfono',
      'plan': 'tipo de plan',
      'id_number': 'DNI',
    };
    return map[field] ?? field;
  }

  bool _canEdit(String field, Map<String, dynamic> loggedUser,
      Map<String, dynamic> target) {
    final myRole = loggedUser['role'] as String? ?? '';
    final targetRole = target['role'] as String? ?? '';
    final isTrainee = targetRole == traineeRole;
    final isSelf = loggedUser['id_number'] == target['id_number'];

    switch (field) {
      case 'role':
        return myRole == adminRole;
      case 'status':
        return (myRole == coachRole && isTrainee) ||
            (myRole == adminRole && !isSelf);
      default:
        return (myRole == coachRole && isTrainee) || myRole == adminRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);
    if (_userDetail == null) return const LoadingScreen();

    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);
    final loggedUser = gymProvider.user!.toJson();
    final u = _userDetail!;

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        // ---- Profile card ----
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: t.secondBackground,
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.account_circle, size: 120, color: t.icon),
              // Nombre
              _EditableTitle(
                text: '${u['first_name']} ${u['last_name']}',
                t: t,
                fontSize: 22,
                canEdit: _canEdit('full_name', loggedUser, u),
                onEdit: () => _openEdit('full_name'),
              ),
              const SizedBox(height: 4),
              // DNI
              _EditableTitle(
                text: u['id_number']?.toString() ?? '',
                t: t,
                fontSize: 16,
                color: t.secondText,
                canEdit: _canEdit('id_number', loggedUser, u),
                onEdit: () => _openEdit('id_number'),
              ),
              const SizedBox(height: 16),

              _EditableRow('Apodo', _val(u['nickname']), t,
                  canEdit: _canEdit('nickname', loggedUser, u),
                  onEdit: () => _openEdit('nickname')),
              _EditableRow('Email', _val(u['email']), t,
                  canEdit: _canEdit('email', loggedUser, u),
                  onEdit: () => _openEdit('email')),
              _EditableRow('Rol', formatRole(u['role'] ?? ''), t,
                  canEdit: false,
                  onEdit: () {}),
              _EditableRow(
                  'Estado',
                  formatUserStatus(u['status'] ?? '',
                      inactiveLabel: 'Inactivo'),
                  t,
                  valueColor: u['status'] == statusDeleted
                      ? inputErrorDark
                      : null,
                  canEdit: _canEdit('status', loggedUser, u),
                  onEdit: () => _openEdit('status')),
              _EditableRow(
                  'Plan',
                  u['plan']?['name']?.toString() ?? 'N/A',
                  t,
                  canEdit: _canEdit('plan', loggedUser, u),
                  onEdit: () => _openEdit('plan')),
              _EditableRow(
                  'Jubilado',
                  (u['is_retired'] as bool? ?? false) ? 'Sí' : 'No',
                  t,
                  canEdit: _canEdit('is_retired', loggedUser, u),
                  onEdit: () => _openEdit('is_retired')),
              _EditableRow(
                  'Teléfono',
                  _val(u['phone']),
                  t,
                  canEdit: _canEdit('phone', loggedUser, u),
                  onEdit: () => _openEdit('phone')),
              _ReadRow('Familia', u['family']?['name']?.toString() ?? 'N/A', t),
              _ReadRow(
                  'Dirección',
                  u['address'] != null
                      ? '${u['address']['address']} ${u['address']['city']} ${u['address']['state']}'
                      : 'N/A',
                  t),
              _ReadRow('Nacimiento',
                  u['birth_date'] != null ? formatDate(u['birth_date']) : 'N/A',
                  t),

              const SizedBox(height: 16),
              TouchableButton(
                  title: 'Restablecer contraseña',
                  onPress: _handleResetPassword),
            ],
          ),
        ),

        // ---- Botones de navegación ----
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 25),
          decoration: BoxDecoration(
              color: t.secondBackground,
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              TouchableButton(
                  title: 'Cuotas',
                  onPress: () => context.push('/admin-user-payments',
                      extra: {
                        'idNumber': _currentIdNumber,
                        'fullName': '${u['first_name']} ${u['last_name']}',
                      })),
              TouchableButton(
                  title: 'Plan de entrenamiento',
                  onPress: () => context.push('/admin-user-training-plans',
                      extra: {
                        'idNumber': _currentIdNumber,
                        'fullName': '${u['first_name']} ${u['last_name']}',
                      })),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------
// Helpers
// -------------------------------------------------------

/// Devuelve 'N/A' si el valor es null o cadena vacía.
String _val(dynamic v) {
  final s = v?.toString() ?? '';
  return s.isEmpty ? 'N/A' : s;
}

// -------------------------------------------------------
// Widgets internos reutilizables
// -------------------------------------------------------

class _EditableTitle extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  final double fontSize;
  final Color? color;
  final bool canEdit;
  final VoidCallback onEdit;
  const _EditableTitle({required this.text, required this.t, required this.fontSize, this.color, required this.canEdit, required this.onEdit});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color ?? t.text)),
          if (canEdit) ...[
            const SizedBox(width: 8),
            GestureDetector(onTap: onEdit, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 20, color: t.icon))),
          ],
        ],
      );
}

class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;
  final Color? valueColor;
  final bool canEdit;
  final VoidCallback onEdit;
  const _EditableRow(this.label, this.value, this.t, {this.valueColor, required this.canEdit, required this.onEdit});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(label, style: TextStyle(color: t.secondText, fontSize: 18)),
              if (canEdit) ...[
                const SizedBox(width: 6),
                GestureDetector(onTap: onEdit, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: t.icon))),
              ],
            ]),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? t.text, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}

class _ReadRow extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;
  const _ReadRow(this.label, this.value, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: t.secondText, fontSize: 18)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: t.text, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      );
}
