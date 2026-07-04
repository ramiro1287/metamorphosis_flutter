// AdminTrainingPlanDetailScreen — misma estructura que AdminUserTrainingPlanDetailScreen
// pero para plantillas. Endpoints: /admin/training-plans/templates/...
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/training_plans.dart';
import '../../../../components/loading/loading_screen.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import 'admin_user_training_plan_detail_screen.dart'
    show ExerciseSearchDialog, ExerciseEditDialog;

class AdminTrainingPlanDetailScreen extends StatefulWidget {
  final dynamic templateId;
  const AdminTrainingPlanDetailScreen({super.key, required this.templateId});
  @override
  State<AdminTrainingPlanDetailScreen> createState() => _State();
}

class _State extends State<AdminTrainingPlanDetailScreen> {
  Map<String, dynamic>? _template;
  bool _connectionError = false;
  int _selectedDay = 1;
  String? _editTitle;
  String? _editDescription;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get('/admin/training-plans/templates/detail/${widget.templateId}/');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _template = data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else { AppToast.error('Error', 'Error de conexión'); }
    }
  }

  Future<void> _updateField(String field, dynamic value) async {
    try {
      await AuthService.put('/admin/training-plans/templates/detail/${widget.templateId}/', data: {field: value});
      AppToast.success('Actualizado correctamente', '');
      _load();
    } on DioException catch (e) {
      final d = e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error('', d.isNotEmpty ? d : 'Error al actualizar');
    }
  }

  Future<void> _handleDeleteTemplate() async {
    final ok = await showConfirmDialog(context, '¿Estás seguro de eliminar esta plantilla?');
    if (!ok) return;
    try {
      await AuthService.delete('/admin/training-plans/templates/detail/${widget.templateId}/');
      AppToast.success('Plantilla eliminada correctamente', '');
      if (mounted) {
        context.go('/admin-training-plans');
      }
    } on DioException catch (_) { AppToast.error('Error', 'No se pudo eliminar la plantilla'); }
  }

  Future<void> _handleDeleteExercise(dynamic exId) async {
    final ok = await showConfirmDialog(context, '¿Estás seguro de eliminar el ejercicio?');
    if (!ok) return;
    try {
      await AuthService.delete('/admin/training-plans/templates/exercise-detail/$exId/');
      AppToast.success('Ejercicio eliminado', '');
      _load();
    } on DioException catch (_) { AppToast.error('Error', 'No se pudo eliminar el ejercicio'); }
  }

  Future<void> _handleReorder(List<dynamic> exercises) async {
    final payload = exercises.asMap().entries.map((e) => {'id': e.value['id'], 'order': e.key}).toList();
    try {
      await AuthService.put('/admin/training-plans/templates/exercise-detail/reorder/',
          data: {'exercises': payload});
    } on DioException catch (_) { AppToast.error('Error', 'No se pudo guardar el orden'); _load(); }
  }

  Map<int, List<dynamic>> get _byDay {
    final exercises = (_template?['exercises'] as List<dynamic>?) ?? [];
    final map = <int, List<dynamic>>{};
    for (final ex in exercises) {
      final d = (ex['week_day'] as num).toInt();
      map.putIfAbsent(d, () => []).add(ex);
    }
    for (final list in map.values) {
      list.sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);
    if (_template == null) return const LoadingScreen();
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    final byDay = _byDay;
    final currentExercises = List<dynamic>.from(byDay[_selectedDay] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ---- Info card ----
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Título
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: _editTitle != null
                  ? TextField(controller: TextEditingController(text: _editTitle),
                      onChanged: (v) => _editTitle = v,
                      style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2))))
                  : Text(_template!['title']?.toString() ?? '',
                      style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () async {
                  if (_editTitle != null) {
                    final trimmed = _editTitle!.trim();
                    if (trimmed.isEmpty) { AppToast.error('Error', 'El título no puede estar vacío'); return; }
                    if (trimmed != (_template!['title']?.toString().trim() ?? '')) {
                      final ok = await showConfirmDialog(context, '¿Estás seguro de actualizar el título?');
                      if (ok) await _updateField('title', trimmed);
                    }
                    setState(() => _editTitle = null);
                  } else { setState(() => _editTitle = _template!['title']?.toString() ?? ''); }
                },
                child: Padding(padding: const EdgeInsets.all(4),
                    child: Icon(_editTitle != null ? Icons.check : Icons.edit, size: 18, color: t.icon)),
              ),
            ]),
            const SizedBox(height: 10),
            // Descripción
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Descripción:', style: TextStyle(color: t.secondText, fontSize: 15)),
              GestureDetector(
                onTap: () async {
                  if (_editDescription != null) {
                    final trimmed = _editDescription!.trim();
                    final original = _template!['description']?.toString().trim() ?? '';
                    if (trimmed != original) {
                      final ok = await showConfirmDialog(context, '¿Estás seguro de actualizar la descripción?');
                      if (ok) await _updateField('description', trimmed.isEmpty ? null : trimmed);
                    }
                    setState(() => _editDescription = null);
                  } else { setState(() => _editDescription = _template!['description']?.toString() ?? ''); }
                },
                child: Padding(padding: const EdgeInsets.all(4),
                    child: Icon(_editDescription != null ? Icons.check : Icons.edit, size: 18, color: t.icon)),
              ),
            ]),
            if (_editDescription != null)
              TextField(
                controller: TextEditingController(text: _editDescription),
                onChanged: (v) => _editDescription = v,
                maxLines: 3,
                style: TextStyle(color: t.text, fontSize: 15),
                decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2))),
              )
            else
              Text(_template!['description']?.toString() ?? 'Sin descripción',
                  style: TextStyle(color: t.text, fontSize: 15)),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight,
                child: GestureDetector(onTap: _handleDeleteTemplate,
                    child: Icon(Icons.delete, size: 28, color: t.icon))),
          ]),
        ),
        const SizedBox(height: 20),
        // ---- Day selector ----
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: weekDaysMap.entries.map((e) {
            final day = e.key; final label = e.value;
            final isActive = byDay[day]?.isNotEmpty ?? false;
            final isSelected = _selectedDay == day;
            return GestureDetector(
              onTap: isActive ? () => setState(() => _selectedDay = day) : null,
              child: Opacity(opacity: isActive ? 1.0 : 0.4, child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? t.buttonBackground : t.secondBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? buttonTextConfirmDark : t.buttonBorder, width: 2),
                ),
                child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? buttonTextConfirmDark : t.text)),
              )),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight,
            child: TouchableButton(title: '+ Ejercicio', onPress: () =>
              ExerciseSearchDialog.show(
                context: context,
                isDarkMode: isDarkMode,
                planId: widget.templateId,
                selectedDay: _selectedDay,
                onAdded: _load,
                addUrl: '/admin/training-plans/templates/exercise-detail/add/',
              ))),
        const SizedBox(height: 12),
        if (currentExercises.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Sin ejercicios para este día', style: TextStyle(color: t.secondText))))
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (newIdx > oldIdx) newIdx--;
                final item = currentExercises.removeAt(oldIdx);
                currentExercises.insert(newIdx, item);
                final all = List<dynamic>.from(_template!['exercises']);
                all.removeWhere((e) => (e['week_day'] as num).toInt() == _selectedDay);
                all.addAll(currentExercises);
                _template!['exercises'] = all;
              });
              _handleReorder(currentExercises);
            },
            children: currentExercises.asMap().entries.map((entry) {
              final idx = entry.key; final ex = entry.value as Map<String, dynamic>;
              return Card(
                key: ValueKey(ex['id']),
                color: t.secondBackground,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    ReorderableDragStartListener(index: idx,
                        child: Icon(Icons.drag_indicator, color: t.secondText)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ex['exercise']?['name']?.toString() ?? '',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
                      Text('Series: ${ex['sets'] ?? 'N/A'}  Reps: ${ex['reps'] ?? 'N/A'}  Descanso: ${ex['rest'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: t.secondText)),
                    ])),
                    GestureDetector(
                      onTap: () => ExerciseEditDialog.show(
                        context: context, isDarkMode: isDarkMode, exercise: ex,
                        onSaved: _load,
                        saveUrl: '/admin/training-plans/templates/exercise-detail/${ex['id']}/',
                      ),
                      child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.edit, size: 22, color: t.icon)),
                    ),
                    GestureDetector(onTap: () => _handleDeleteExercise(ex['id']),
                        child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.delete, size: 22, color: t.icon))),
                  ]),
                ),
              );
            }).toList(),
          ),
      ]),
    );
  }
}
