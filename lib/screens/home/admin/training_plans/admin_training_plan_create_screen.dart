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

class AdminTrainingPlanCreateScreen extends StatefulWidget {
  const AdminTrainingPlanCreateScreen({super.key});
  @override
  State<AdminTrainingPlanCreateScreen> createState() => _State();
}

class _State extends State<AdminTrainingPlanCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _handleSubmit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      AppToast.error('Error', 'El título es obligatorio'); return;
    }
    final ok = await showConfirmDialog(context, '¿Estás seguro de crear esta plantilla?');
    if (!ok) return;
    setState(() => _loading = true);
    try {
      final r = await AuthService.post('/admin/training-plans/templates/create/', data: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
      final templateId = r.data['data']['id'];
      AppToast.success('Plantilla creada correctamente', '');
      if (mounted) {
        context.go('/admin-training-plans');
        context.push('/admin-training-plan-detail', extra: {'templateId': templateId});
      }
    } on DioException catch (e) {
      final d = e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error('', d.isNotEmpty ? d : 'Error al crear la plantilla');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    return ScrollContainer(padding: const EdgeInsets.all(25), children: [
      Text('Nueva Plantilla', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.text)),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Título:', style: TextStyle(color: t.secondText, fontSize: 16)),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 16, color: t.text),
            decoration: InputDecoration(
              hintText: 'Ej. Principiantes 3 días',
              hintStyle: TextStyle(color: t.secondText),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Descripción (opcional):', style: TextStyle(color: t.secondText, fontSize: 16)),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 16, color: t.text),
            decoration: InputDecoration(
              hintText: 'Sin descripción',
              hintStyle: TextStyle(color: t.secondText),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      Center(child: TouchableButton(title: 'Crear plantilla', onPress: _handleSubmit, loading: _loading)),
    ]);
  }
}
