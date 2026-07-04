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

class AdminFamilyDetailScreen extends StatefulWidget {
  final dynamic familyId;
  const AdminFamilyDetailScreen({super.key, required this.familyId});
  @override
  State<AdminFamilyDetailScreen> createState() =>
      _AdminFamilyDetailScreenState();
}

class _AdminFamilyDetailScreenState extends State<AdminFamilyDetailScreen> {
  Map<String, dynamic>? _family;
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get('/admin/users/family/${widget.familyId}/');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _family = data);
    } on DioException catch (e) {
      if (_isConn(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  bool _isConn(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout;

  Future<void> _handleEditField(
      BuildContext context, String field, bool isDarkMode) async {
    final t = getThemeColors(isDarkMode);
    final ctrl =
        TextEditingController(text: _family![field]?.toString() ?? '');
    String? errorMsg;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: t.secondBackground,
          title: Text(
            field == 'name' ? 'Editar nombre' : 'Editar descripción',
            style: TextStyle(color: t.text),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: field == 'description' ? 3 : 1,
                style: TextStyle(color: t.text),
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: t.text)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: t.text, width: 2)),
                ),
              ),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorMsg!,
                      style: TextStyle(
                          color: t.inputError, fontSize: 14)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar',
                  style: TextStyle(color: t.buttonTextCancel)),
            ),
            TextButton(
              onPressed: () {
                if (field == 'name' && ctrl.text.trim().isEmpty) {
                  setS(() => errorMsg = 'El nombre no puede estar vacío');
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text('Guardar',
                  style: TextStyle(color: t.buttonTextConfirm)),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final confirm = await showConfirmDialog(
        context, '¿Estás seguro de actualizar el campo de la familia?');
    if (!confirm) return;

    try {
      final payload = field == 'description' && ctrl.text.trim().isEmpty
          ? {field: null}
          : {field: ctrl.text.trim()};
      await AuthService.put('/admin/users/family/${widget.familyId}/',
          data: payload);
      AppToast.success('Campo actualizado correctamente', '');
      _load();
    } on DioException catch (e) {
      final detail =
          e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error(detail.isNotEmpty ? detail : 'Error', 'No se pudo actualizar el campo');
    }
  }

  Future<void> _handleRemoveMember(dynamic idNumber) async {
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de eliminar el miembro de la familia?');
    if (!ok) return;
    try {
      await AuthService.put(
          '/admin/users/family/${widget.familyId}/remove-user/$idNumber/',
          data: {});
      AppToast.success('Miembro eliminado correctamente', '');
      _load();
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo eliminar el miembro');
    }
  }

  Future<void> _handleDeleteFamily() async {
    final ok = await showConfirmDialog(
        context, '¿Estás seguro de eliminar la familia?');
    if (!ok) return;
    try {
      await AuthService.delete('/admin/users/family/${widget.familyId}/');
      AppToast.success('Familia eliminada correctamente', '');
      if (mounted) context.pop();
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo eliminar la familia');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);
    if (_family == null) return const LoadingScreen();

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    final members = _family!['members'] as List<dynamic>? ?? [];

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        // ---- Tarjeta de info ----
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: t.secondBackground,
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _InfoRowEdit(
                label: 'Nombre',
                value: _family!['name']?.toString() ?? '',
                t: t,
                onEdit: () =>
                    _handleEditField(context, 'name', isDarkMode),
              ),
              _InfoRowEdit(
                label: 'Descripción',
                value: _family!['description']?.toString() ?? 'N/A',
                t: t,
                onEdit: () =>
                    _handleEditField(context, 'description', isDarkMode),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _handleDeleteFamily,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete, size: 35, color: t.icon),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---- Miembros ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Miembros',
                style: TextStyle(
                    fontSize: 22, color: t.text, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: () => context.push('/admin-family-add',
                  extra: {'familyId': widget.familyId}),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.person_add, size: 35, color: t.icon),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (members.isEmpty)
          Text('Sin miembros',
              style: TextStyle(fontSize: 18, color: t.text))
        else
          ...members.map((m) => Container(
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
                      '${m['first_name']} ${m['last_name']}',
                      style:
                          TextStyle(fontSize: 18, color: t.text),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _handleRemoveMember(m['id_number']),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete,
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

class _InfoRowEdit extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;
  final VoidCallback onEdit;

  const _InfoRowEdit({
    required this.label,
    required this.value,
    required this.t,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style:
                      TextStyle(color: t.secondText, fontSize: 18)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child:
                      Icon(Icons.edit, size: 20, color: t.icon),
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(color: t.text, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
