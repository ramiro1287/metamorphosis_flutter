import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/loading/loading_screen.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminFamilyAddScreen extends StatefulWidget {
  final dynamic familyId;
  const AdminFamilyAddScreen({super.key, required this.familyId});
  @override
  State<AdminFamilyAddScreen> createState() => _AdminFamilyAddScreenState();
}

class _AdminFamilyAddScreenState extends State<AdminFamilyAddScreen> {
  Map<String, dynamic>? _family;
  List<dynamic> _users = [];
  bool _connectionError = false;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFamily();
    _loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFamily() async {
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get(
          '/admin/users/family/${widget.familyId}/');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _family = data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      final q = StringBuffer('/admin/users/list/?page_size=10');
      if (_firstNameCtrl.text.isNotEmpty)
        q.write('&first_name=${_firstNameCtrl.text}');
      if (_lastNameCtrl.text.isNotEmpty)
        q.write('&last_name=${_lastNameCtrl.text}');
      final r = await AuthService.get(q.toString());
      final results =
          r.data['data']['results'] as List<dynamic>? ?? [];
      if (mounted) setState(() => _users = results);
    } on DioException catch (_) {
      AppToast.error('Error', 'Error de conexión');
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), _loadUsers);
  }

  Future<void> _handleAddMember(Map<String, dynamic> user) async {
    final name =
        '${user['first_name']} ${user['last_name']}';
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de agregar a $name a la familia?');
    if (!ok) return;
    try {
      await AuthService.post('/admin/users/family/add-user/', data: {
        'family_id': widget.familyId,
        'id_number': user['id_number'],
      });
      if (mounted) {
        context.go('/admin-families');
        context.push('/admin-family-detail',
            extra: {'familyId': widget.familyId});
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail =
            e.response?.data?['data']?['error_detail']?.toString() ?? '';
        AppToast.error('', detail);
      } else {
        AppToast.error('Error', 'No se pudo agregar el usuario a la familia');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _loadFamily);
    if (_family == null) return const LoadingScreen();

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        // Info de la familia
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: t.secondBackground,
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Agregar miembro a familia',
                  style: TextStyle(
                      fontSize: 22,
                      color: t.text,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nombre',
                      style:
                          TextStyle(color: t.secondText, fontSize: 18)),
                  Text(_family!['name']?.toString() ?? '',
                      style: TextStyle(color: t.text, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Usuarios',
            style: TextStyle(
                fontSize: 22, color: t.text, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        // Filtros de búsqueda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              TextField(
                controller: _firstNameCtrl,
                style: TextStyle(color: t.text),
                onChanged: (_) => _onSearchChanged(),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre',
                  hintStyle: TextStyle(color: t.secondText),
                  filled: true,
                  fillColor: t.secondBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastNameCtrl,
                style: TextStyle(color: t.text),
                onChanged: (_) => _onSearchChanged(),
                decoration: InputDecoration(
                  hintText: 'Buscar por apellido',
                  hintStyle: TextStyle(color: t.secondText),
                  filled: true,
                  fillColor: t.secondBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_users.isEmpty)
          Text('No se encontraron usuarios',
              style: TextStyle(fontSize: 18, color: t.text))
        else
          ..._users.map((usr) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: t.secondBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    top: BorderSide(color: t.text, width: 1),
                    bottom: BorderSide(color: t.text, width: 1),
                    left: BorderSide(color: t.text, width: 4),
                    right: BorderSide(color: t.text, width: 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${usr['first_name']} ${usr['last_name']}',
                        style:
                            TextStyle(fontSize: 18, color: t.text)),
                    GestureDetector(
                      onTap: () => _handleAddMember(
                          usr as Map<String, dynamic>),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.person_add,
                            size: 25, color: t.icon),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
