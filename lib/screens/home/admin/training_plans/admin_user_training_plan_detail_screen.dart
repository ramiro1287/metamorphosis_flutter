import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../components/picker/picker_select.dart';
import '../../../../components/picker/date_picker_modal.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminUserTrainingPlanDetailScreen extends StatefulWidget {
  final String idNumber;
  final dynamic planId;
  final String fullName;
  const AdminUserTrainingPlanDetailScreen({super.key, required this.idNumber, required this.planId, required this.fullName});
  @override
  State<AdminUserTrainingPlanDetailScreen> createState() => _State();
}

class _State extends State<AdminUserTrainingPlanDetailScreen> {
  Map<String, dynamic>? _plan;
  bool _connectionError = false;
  int _selectedDay = 1;
  // Inline edit states
  String? _editDescription;
  bool _editingStatus = false;
  String? _editStatus;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get('/admin/training-plans/detail/${widget.planId}/');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _plan = data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else { AppToast.error('Error', 'Error de conexión'); }
    }
  }

  Map<int, List<dynamic>> get _byDay {
    final exercises = (_plan?['exercises'] as List<dynamic>?) ?? [];
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

  Future<void> _updateField(String field, dynamic value) async {
    try {
      await AuthService.put('/admin/training-plans/update/${widget.planId}/', data: {field: value});
      AppToast.success('Actualizado correctamente', '');
      _load();
    } on DioException catch (e) {
      final d = e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error('', d.isNotEmpty ? d : 'Error al actualizar');
    }
  }

  Future<void> _handleDeletePlan() async {
    final ok = await showConfirmDialog(context, '¿Estás seguro de eliminar el plan de entrenamiento?');
    if (!ok) return;
    try {
      await AuthService.delete('/admin/training-plans/update/${widget.planId}/');
      AppToast.success('Plan eliminado correctamente', '');
      if (mounted) context.pop();
    } on DioException catch (_) { AppToast.error('Error', 'No se pudo eliminar el plan'); }
  }

  Future<void> _handleDeleteExercise(dynamic exId) async {
    final ok = await showConfirmDialog(context, '¿Estás seguro de eliminar el ejercicio?');
    if (!ok) return;
    try {
      await AuthService.delete('/admin/training-plans/exercise-detail/$exId/');
      AppToast.success('Ejercicio eliminado', '');
      _load();
    } on DioException catch (_) { AppToast.error('Error', 'No se pudo eliminar el ejercicio'); }
  }

  Future<void> _handleReorder(List<dynamic> exercises) async {
    final payload = exercises.asMap().entries.map((e) => {'id': e.value['id'], 'order': e.key}).toList();
    try {
      await AuthService.put('/admin/training-plans/exercise-detail/reorder/', data: {'exercises': payload});
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo guardar el orden');
      _load();
    }
  }

  void _showAddExerciseDialog() {
    ExerciseSearchDialog.show(
      context: context,
      isDarkMode: context.read<GymProvider>().isDarkMode,
      planId: widget.planId,
      selectedDay: _selectedDay,
      onAdded: _load,
      addUrl: '/admin/training-plans/exercise-detail/add/',
    );
  }

  void _showEditExerciseDialog(Map<String, dynamic> ex) {
    ExerciseEditDialog.show(
      context: context,
      isDarkMode: context.read<GymProvider>().isDarkMode,
      exercise: ex,
      onSaved: _load,
      saveUrl: '/admin/training-plans/exercise-detail/${ex['id']}/',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);
    if (_plan == null) return const LoadingScreen();
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
            // Status
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Estado:', style: TextStyle(color: t.secondText, fontSize: 16)),
              if (!_editingStatus) ...[
                Text(formatPlanStatus(_plan!['status'] ?? ''), style: TextStyle(color: t.text, fontSize: 16)),
                GestureDetector(onTap: () => setState(() { _editingStatus = true; _editStatus = _plan!['status']; }),
                    child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: t.icon))),
              ] else ...[
                Expanded(child: PickerSelect(
                  value: _editStatus,
                  onValueChange: (v) => setState(() => _editStatus = v?.toString()),
                  items: [
                    PickerItem(label: formatPlanStatus(planStatusActive), value: planStatusActive),
                    PickerItem(label: formatPlanStatus(planStatusFinish), value: planStatusFinish),
                    PickerItem(label: formatPlanStatus(planStatusCanceled), value: planStatusCanceled),
                  ],
                )),
                TextButton(onPressed: () async {
                  if (_editStatus != _plan!['status']) {
                    final ok = await showConfirmDialog(context, '¿Estás seguro de cambiar el estado del plan?');
                    if (ok) await _updateField('status', _editStatus);
                  }
                  setState(() => _editingStatus = false);
                }, child: Text('OK', style: TextStyle(color: t.buttonTextConfirm))),
                TextButton(onPressed: () => setState(() => _editingStatus = false),
                    child: Text('X', style: TextStyle(color: t.buttonTextCancel))),
              ],
            ]),
            const SizedBox(height: 8),
            // Fecha
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Vence:', style: TextStyle(color: t.secondText, fontSize: 16)),
              Row(children: [
                Text(formatDate(_plan!['expiration_date']?.toString(), fallback: 'Sin vencimiento'),
                    style: TextStyle(color: t.text, fontSize: 16)),
                GestureDetector(
                  onTap: () async {
                    final d = await showAppDatePicker(context: context,
                        initialDate: DateTime.tryParse(_plan!['expiration_date']?.toString() ?? '') ?? DateTime.now());
                    if (d == null) return;
                    final ok = await showConfirmDialog(context, '¿Estás seguro de actualizar el vencimiento del plan?');
                    if (ok) await _updateField('expiration_date', d.toIso8601String());
                  },
                  child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: t.icon)),
                ),
              ]),
            ]),
            const SizedBox(height: 8),
            // Descripción
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Anotaciones:', style: TextStyle(color: t.secondText, fontSize: 16)),
              GestureDetector(
                onTap: () async {
                  if (_editDescription != null) {
                    final trimmed = _editDescription!.trim();
                    final original = _plan!['description']?.toString().trim() ?? '';
                    if (trimmed != original) {
                      final ok = await showConfirmDialog(context, '¿Estás seguro de actualizar anotaciones?');
                      if (ok) await _updateField('description', trimmed.isEmpty ? null : trimmed);
                    }
                    setState(() => _editDescription = null);
                  } else {
                    setState(() => _editDescription = _plan!['description']?.toString() ?? '');
                  }
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
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2)),
                ),
              )
            else
              Text(_plan!['description']?.toString() ?? 'Sin anotaciones',
                  style: TextStyle(color: t.text, fontSize: 15)),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight,
                child: GestureDetector(onTap: _handleDeletePlan,
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
        // ---- Add exercise button ----
        Align(alignment: Alignment.centerRight,
            child: TouchableButton(title: '+ Ejercicio', onPress: _showAddExerciseDialog)),
        const SizedBox(height: 12),
        // ---- Exercises reorderable ----
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
                // Update plan exercises order
                final all = List<dynamic>.from(_plan!['exercises']);
                // Remove day exercises and re-insert reordered
                all.removeWhere((e) => (e['week_day'] as num).toInt() == _selectedDay);
                all.addAll(currentExercises);
                _plan!['exercises'] = all;
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
                      Text(ex['exercise']?['name']?.toString() ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.text)),
                      Text('Series: ${ex['sets'] ?? 'N/A'}  Reps: ${ex['reps'] ?? 'N/A'}  Descanso: ${ex['rest'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: t.secondText)),
                      if (ex['description'] != null)
                        Text('Nota: ${ex['description']}', style: TextStyle(fontSize: 13, color: t.secondText, fontStyle: FontStyle.italic)),
                    ])),
                    GestureDetector(onTap: () => _showEditExerciseDialog(ex),
                        child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.edit, size: 22, color: t.icon))),
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

// -------------------------------------------------------
// Dialog para buscar y agregar un ejercicio al plan
// -------------------------------------------------------
class ExerciseSearchDialog extends StatefulWidget {
  final bool isDarkMode;
  final dynamic planId;
  final int selectedDay;
  final VoidCallback onAdded;
  final String addUrl;

  const ExerciseSearchDialog({required this.isDarkMode, required this.planId,
      required this.selectedDay, required this.onAdded, required this.addUrl});

  static void show({required BuildContext context, required bool isDarkMode,
      required dynamic planId, required int selectedDay, required VoidCallback onAdded, required String addUrl}) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => ExerciseSearchDialog(isDarkMode: isDarkMode, planId: planId,
          selectedDay: selectedDay, onAdded: onAdded, addUrl: addUrl),
    );
  }

  @override
  State<ExerciseSearchDialog> createState() => ExerciseSearchDialogState();
}

class ExerciseSearchDialogState extends State<ExerciseSearchDialog> {
  List<dynamic> _exercises = [];
  String _nameFilter = '';
  String _typeFilter = '';
  Timer? _debounce;
  bool _loading = false;
  int _selectedDay = 1;

  @override
  void initState() { super.initState(); _selectedDay = widget.selectedDay; _search(); }
  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final q = StringBuffer('/admin/training-plans/exercises/?page_size=10');
      if (_typeFilter.isNotEmpty) q.write('&type=$_typeFilter');
      if (_nameFilter.isNotEmpty) q.write('&name=$_nameFilter');
      final r = await AuthService.get(q.toString());
      final results = r.data['data']['results'] as List<dynamic>? ?? [];
      if (mounted) setState(() => _exercises = results);
    } on DioException catch (_) { AppToast.error('Error', 'Error de conexión'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _handleAdd(dynamic exerciseId) async {
    Navigator.of(context).pop();
    try {
      await AuthService.post(widget.addUrl, data: {
        'plan_id': widget.planId, 'exercise_id': exerciseId, 'week_day': _selectedDay,
      });
      AppToast.success('Ejercicio agregado con éxito', '');
      widget.onAdded();
    } on DioException catch (e) {
      final d = e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error('', d.isNotEmpty ? d : 'No se pudo agregar el ejercicio');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(widget.isDarkMode);
    final typeItems = [
      const PickerItem(label: 'Todos los grupos', value: ''),
      ...exercisesMap.entries.map((e) => PickerItem(label: e.value, value: e.key)),
    ];
    final dayItems = weekDaysMap.entries.map((e) => PickerItem(label: e.value, value: e.key)).toList();

    return Dialog(
      backgroundColor: t.secondBackground,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text('Agregar ejercicio', style: TextStyle(fontSize: 18, color: t.text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            PickerSelect(value: _selectedDay, onValueChange: (v) => setState(() => _selectedDay = v as int), items: dayItems),
            const SizedBox(height: 8),
            PickerSelect(value: _typeFilter, onValueChange: (v) { setState(() => _typeFilter = v?.toString() ?? ''); _onSearch(); }, items: typeItems),
            const SizedBox(height: 8),
            TextField(
              style: TextStyle(color: t.text),
              decoration: InputDecoration(hintText: 'Buscar por nombre', hintStyle: TextStyle(color: t.secondText),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2))),
              onChanged: (v) { setState(() => _nameFilter = v); _onSearch(); },
            ),
          ])),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _exercises.isEmpty
                  ? Center(child: Text('Sin resultados', style: TextStyle(color: t.secondText)))
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (_, i) {
                        final ex = _exercises[i];
                        return ListTile(
                          title: Text(ex['name']?.toString() ?? '', style: TextStyle(color: t.text)),
                          subtitle: Text(exercisesMap[ex['type']] ?? ex['type']?.toString() ?? '', style: TextStyle(color: t.secondText, fontSize: 13)),
                          trailing: GestureDetector(
                            onTap: () => _handleAdd(ex['id']),
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: buttonTextConfirmDark, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Agregar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
                          ),
                        );
                      },
                    )),
          TextButton(onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(color: t.buttonTextCancel))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// -------------------------------------------------------
// Dialog para editar un ejercicio del plan (sets/reps/etc)
// -------------------------------------------------------
class ExerciseEditDialog {
  static void show({required BuildContext context, required bool isDarkMode,
      required Map<String, dynamic> exercise, required VoidCallback onSaved, required String saveUrl}) {
    final t = getThemeColors(isDarkMode);
    final setsCtrl = TextEditingController(text: exercise['sets']?.toString() ?? '');
    final repsCtrl = TextEditingController(text: exercise['reps']?.toString() ?? '');
    final restCtrl = TextEditingController(text: exercise['rest']?.toString() ?? '');
    final descCtrl = TextEditingController(text: exercise['description']?.toString() ?? '');
    int selectedDay = (exercise['week_day'] as num).toInt();

    final dayItems = weekDaysMap.entries.map((e) => PickerItem(label: e.value, value: e.key)).toList();

    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        return StatefulBuilder(
          builder: (ctx, setS) => Dialog(
            backgroundColor: t.secondBackground,
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              // Ancho fijo = pantalla menos márgenes. Alto fijo = 80% de pantalla.
              width: size.width - 40,
              height: size.height * 0.8,
              child: Column(children: [
                // ---- Título ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    exercise['exercise']?['name']?.toString() ?? 'Editar ejercicio',
                    style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                // ---- Contenido ----
                // Campos fijos (sin scroll necesario)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    PickerSelect(
                      value: selectedDay,
                      onValueChange: (v) => setS(() => selectedDay = v as int),
                      items: dayItems,
                    ),
                    const SizedBox(height: 8),
                    _ef(setsCtrl, 'Series', t, isNumber: true),
                    _ef(repsCtrl, 'Repeticiones', t),
                    _ef(restCtrl, 'Descanso', t),
                  ]),
                ),
                // Anotaciones: ocupa el espacio libre restante hasta los botones
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: TextField(
                      controller: descCtrl,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(fontSize: 15, color: t.text),
                      decoration: InputDecoration(
                        hintText: 'Anotaciones',
                        hintStyle: TextStyle(color: t.secondText),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: t.text),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: t.text, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ),
                // ---- Acciones ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancelar', style: TextStyle(color: t.buttonTextCancel)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await AuthService.put(saveUrl, data: {
                            'week_day': selectedDay,
                            'sets': setsCtrl.text.trim().isEmpty ? null : int.tryParse(setsCtrl.text.trim()),
                            'reps': repsCtrl.text.trim().isEmpty ? null : repsCtrl.text.trim(),
                            'rest': restCtrl.text.trim().isEmpty ? null : restCtrl.text.trim(),
                            'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          });
                          AppToast.success('Ejercicio actualizado correctamente', '');
                          onSaved();
                        } on DioException catch (_) {
                          AppToast.error('Error', 'No se pudo actualizar el ejercicio');
                        } finally {
                          setsCtrl.dispose();
                          repsCtrl.dispose();
                          restCtrl.dispose();
                          descCtrl.dispose();
                        }
                      },
                      child: Text('Guardar', style: TextStyle(color: t.buttonTextConfirm)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  static Widget _ef(TextEditingController c, String hint, AppThemeColors t, {bool isNumber = false, int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: c, maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
            style: TextStyle(fontSize: 15, color: t.text),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: t.secondText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2))),
          ));
}
