import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/picker/date_picker_modal.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminUserTrainingPlanCreateScreen extends StatefulWidget {
  final String idNumber;
  final String fullName;
  const AdminUserTrainingPlanCreateScreen({super.key, required this.idNumber, required this.fullName});
  @override
  State<AdminUserTrainingPlanCreateScreen> createState() => _State();
}

class _State extends State<AdminUserTrainingPlanCreateScreen> {
  final _descCtrl = TextEditingController();
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _handleSubmit() async {
    final ok = await showConfirmDialog(context, '¿Estás seguro de crear plan de entrenamiento?');
    if (!ok) return;
    setState(() => _loading = true);
    try {
      final r = await AuthService.post('/admin/training-plans/create/', data: {
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'expiration_date': _expirationDate.toIso8601String(),
        'trainee_id_number': widget.idNumber,
      });
      final planId = r.data['data']['id'];
      AppToast.success('Plan creado correctamente', '');
      if (mounted) {
        context.go('/admin-user-training-plans');
        context.push('/admin-user-training-plan-detail',
            extra: {'idNumber': widget.idNumber, 'planId': planId, 'fullName': widget.fullName});
      }
    } on DioException catch (e) {
      final d = e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error('', d.isNotEmpty ? d : 'Error al crear el plan');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    return ScrollContainer(padding: const EdgeInsets.all(25), children: [
      Text('Plan para:', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: t.text)),
      Text(widget.fullName, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.text)),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fecha de expiración:', style: TextStyle(color: t.secondText, fontSize: 16)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final d = await showAppDatePicker(context: context,
                  initialDate: _expirationDate,
                  firstDate: DateTime.now().add(const Duration(days: 1)));
              if (d != null) setState(() => _expirationDate = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(color: t.background, borderRadius: BorderRadius.circular(12)),
              child: Text(_fmtDate(_expirationDate), style: TextStyle(color: t.text, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Anotaciones:', style: TextStyle(color: t.secondText, fontSize: 16)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 16, color: t.text),
            decoration: InputDecoration(
              hintText: 'Sin anotaciones...',
              hintStyle: TextStyle(color: t.secondText),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      Center(child: TouchableButton(title: 'Crear plan', onPress: _handleSubmit, loading: _loading)),
    ]);
  }
}
