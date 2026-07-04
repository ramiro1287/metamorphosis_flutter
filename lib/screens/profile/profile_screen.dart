import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_theme.dart';
import '../../components/containers/scroll_container.dart';
import '../../components/buttons/touchable_button.dart';
import '../../components/alerts/confirm_dialog.dart';
import '../../components/picker/date_picker_modal.dart';
import '../../components/toast/app_toast.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPicker = false;

  @override
  void initState() {
    super.initState();
    // Refresca datos del usuario al entrar al perfil
    context.read<GymProvider>().refreshUser();
  }

  Future<void> _onConfirmDate(DateTime date) async {
    setState(() => _showPicker = false);

    final ok = await showConfirmDialog(
      context,
      '¿Estás seguro de cambiar tu fecha de nacimiento?',
    );
    if (!ok) return;

    await _changeBirthDate(date);
  }

  Future<void> _changeBirthDate(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      await AuthService.put('/users/me/', data: {'birth_date': dateStr});
      if (mounted) {
        AppToast.success('Fecha de nacimiento actualizada', '');
        context.read<GymProvider>().refreshUser();
      }
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo cambiar tu fecha de nacimiento');
    }
  }

  Future<void> _handleLogout() async {
    final ok = await showConfirmDialog(
        context, '¿Seguro que quieres cerrar sesión?');
    if (!ok) return;
    if (mounted) await context.read<GymProvider>().handleLogout();
  }

  Future<void> _handleDeleteAccount() async {
    final ok = await showConfirmDialog(
      context,
      '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción es irreversible.',
    );
    if (!ok) return;

    try {
      await AuthService.post('/users/delete/');
      if (mounted) {
        AppToast.success('Cuenta eliminada correctamente', '');
        context.read<GymProvider>().handleLogout();
      }
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo eliminar la cuenta');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymProvider = context.watch<GymProvider>();
    final user = gymProvider.user;
    if (user == null) return const SizedBox.shrink();

    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        // ---- Profile card ----
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: t.secondBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Fila superior: toggle tema + logout
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => gymProvider.setIsDarkMode(!isDarkMode),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        size: 30,
                        color: t.icon,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.power_settings_new,
                        size: 30,
                        color: t.icon,
                      ),
                    ),
                  ),
                ],
              ),
              // Avatar
              Icon(Icons.account_circle, size: 120, color: t.icon),
              const SizedBox(height: 8),
              Text(
                '${user.firstName} ${user.lastName}',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: t.text),
              ),
              Text(
                user.idNumber,
                style: TextStyle(fontSize: 16, color: t.secondText),
              ),
              const SizedBox(height: 20),

              // Filas de info
              _InfoRow(label: 'Rol', value: formatRole(user.role), t: t),
              _InfoRow(
                  label: 'Estado',
                  value: formatUserStatus(user.status,
                      inactiveLabel: 'Desactivado'),
                  t: t),
              _InfoRow(
                  label: 'Plan',
                  value: user.plan?['name']?.toString() ?? 'N/A',
                  t: t),
              _InfoRow(
                  label: 'Jubilado',
                  value: user.isRetired ? 'Sí' : 'No',
                  t: t),
              _InfoRow(
                  label: 'Teléfono',
                  value: user.phone?.isNotEmpty == true
                      ? user.phone!
                      : 'N/A',
                  t: t),
              _InfoRow(
                  label: 'Familia',
                  value: user.family?['name']?.toString() ?? 'N/A',
                  t: t),

              // Dirección con botón editar
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Dirección',
                            style: TextStyle(
                                color: t.secondText, fontSize: 18)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/change-address'),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit, size: 22, color: t.icon),
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Text(
                        _buildAddressText(user),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.text, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Nacimiento con botón editar
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Nacimiento',
                            style: TextStyle(
                                color: t.secondText, fontSize: 18)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _showPicker = true),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit, size: 22, color: t.icon),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      user.birthDate != null
                          ? formatDate(user.birthDate)
                          : 'N/A',
                      style: TextStyle(color: t.text, fontSize: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              TouchableButton(
                title: 'Cambiar contraseña',
                onPress: () => context.push('/change-password'),
              ),
              const SizedBox(height: 15),
              TouchableButton(
                title: 'Eliminar cuenta',
                onPress: _handleDeleteAccount,
                variant: ButtonVariant.error,
              ),
            ],
          ),
        ),

        // DatePicker inline (se muestra superpuesto cuando _showPicker == true)
        if (_showPicker)
          _InlineDatePicker(
            initialDate: user.birthDate != null
                ? DateTime.tryParse(user.birthDate!) ?? DateTime.now()
                : DateTime.now(),
            isDarkMode: isDarkMode,
            onConfirm: _onConfirmDate,
            onCancel: () => setState(() => _showPicker = false),
          ),
      ],
    );
  }

  String _buildAddressText(User user) {
    // address viene del AddressSerializer: {id, state (nombre), city, address}
    final addr = user.address;
    if (addr == null) return 'N/A';
    final parts = [
      addr['address']?.toString(),
      addr['city']?.toString(),
      addr['state']?.toString(),
    ].where((s) => s != null && s.isNotEmpty).join(', ');
    return parts.isEmpty ? 'N/A' : parts;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t.secondText, fontSize: 18)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: t.text, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// DatePicker modal inline (para el perfil)
class _InlineDatePicker extends StatelessWidget {
  final DateTime initialDate;
  final bool isDarkMode;
  final ValueChanged<DateTime> onConfirm;
  final VoidCallback onCancel;

  const _InlineDatePicker({
    required this.initialDate,
    required this.isDarkMode,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Lanzamos el picker nativo al construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final picked = await showAppDatePicker(
        context: context,
        initialDate: initialDate,
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        onConfirm(picked);
      } else {
        onCancel();
      }
    });
    return const SizedBox.shrink();
  }
}
