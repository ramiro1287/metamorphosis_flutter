import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/picker/date_picker_modal.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminUserTrainingPlanAssignScreen extends StatefulWidget {
  final String idNumber;
  final String fullName;
  const AdminUserTrainingPlanAssignScreen({super.key, required this.idNumber, required this.fullName});
  @override
  State<AdminUserTrainingPlanAssignScreen> createState() => _State();
}

class _State extends State<AdminUserTrainingPlanAssignScreen> {
  List<dynamic> _templates = [];
  bool _loading = true;
  bool _connectionError = false;
  dynamic _selectedId;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  @override
  void initState() { super.initState(); _fetchPage(); }

  Future<void> _fetchPage({String? url, bool append = false}) async {
    try {
      final finalUrl = url ?? '/admin/training-plans/templates/?page_size=10';
      final r = await AuthService.get(finalUrl);
      final data = r.data['data'] as Map<String, dynamic>;
      if (mounted) setState(() {
        _templates = append ? [..._templates, ...data['results'] as List] : data['results'] as List;
      });
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else { AppToast.error('Error', 'Error al cargar plantillas'); }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _handleAssign() async {
    if (_selectedId == null) { AppToast.error('Error', 'Selecciona una plantilla primero'); return; }
    setState(() => _submitting = true);
    try {
      await AuthService.post('/admin/training-plans/templates/assign/', data: {
        'template_id': _selectedId,
        'trainee_id_number': widget.idNumber,
        'expiration_date': _expirationDate.toIso8601String(),
      });
      AppToast.success('Plan asignado correctamente', '');
      if (mounted) context.pop();
    } on DioException catch (e) {
      final detail = e.response?.data?['data']?['error_detail']?.toString()
          ?? e.response?.data?['error_detail']?.toString() ?? 'Error al asignar plan';
      AppToast.error('Error', detail);
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: () {
      setState(() { _connectionError = false; _loading = true; }); _fetchPage();
    });
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(25, 16, 25, 8), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignar plan de entrenamiento', style: TextStyle(fontSize: 20, color: t.text)),
          Text(widget.fullName, style: TextStyle(fontSize: 18, color: t.secondText)),
          const SizedBox(height: 12),
          Row(children: [
            Text('Fecha de expiración: ', style: TextStyle(fontSize: 15, color: t.secondText)),
            GestureDetector(
              onTap: () async {
                final d = await showAppDatePicker(context: context,
                    initialDate: _expirationDate,
                    firstDate: DateTime.now().add(const Duration(hours: 3)));
                if (d != null) setState(() => _expirationDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(8)),
                child: Text(_fmtDate(_expirationDate), style: TextStyle(color: t.text, fontSize: 15)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TouchableButton(
            title: _submitting ? 'Asignando...' : 'Asignar seleccionada',
            onPress: _handleAssign,
            disabled: _submitting || _selectedId == null,
          ),
        ],
      )),
      Expanded(child: _loading && _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(child: Text('Sin plantillas...', style: TextStyle(color: t.text)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
                  child: Column(children: _templates.map((tmpl) {
                    final isSelected = _selectedId == tmpl['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedId = tmpl['id']),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: t.secondBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? buttonTextConfirmDark : t.text,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tmpl['title']?.toString() ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
                          if (tmpl['description'] != null)
                            Text(tmpl['description'].toString(), style: TextStyle(fontSize: 14, color: t.secondText), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(formatDate(tmpl['created_at']?.toString()), style: TextStyle(fontSize: 13, color: t.secondText)),
                        ]),
                      ),
                    );
                  }).toList()),
                )),
    ]);
  }
}
