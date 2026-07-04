import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/training_plans.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/picker/picker_select.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({super.key});
  @override
  State<AdminExercisesScreen> createState() => _State();
}

class _State extends State<AdminExercisesScreen> {
  List<dynamic> _exercises = [];
  String? _nextUrl;
  bool _loading = true;
  bool _loadingMore = false;
  bool _connectionError = false;
  String _typeFilter = '';
  final _nameCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() { super.initState(); _fetchPage(); }

  @override
  void dispose() { _debounce?.cancel(); _nameCtrl.dispose(); super.dispose(); }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _loading = true);
      await _fetchPage(reset: true);
    });
  }

  Future<void> _fetchPage({String? url, bool append = false, bool reset = false}) async {
    try {
      final String finalUrl;
      if (url != null) {
        finalUrl = url;
      } else {
        final q = StringBuffer('/admin/training-plans/exercises/?page_size=10');
        if (_typeFilter.isNotEmpty) q.write('&type=$_typeFilter');
        if (_nameCtrl.text.isNotEmpty) q.write('&name=${_nameCtrl.text}');
        finalUrl = q.toString();
      }
      final r = await AuthService.get(finalUrl);
      final data = r.data['data'] as Map<String, dynamic>;
      if (mounted) setState(() {
        _nextUrl = data['next'] as String?;
        _exercises = append ? [..._exercises, ...data['results'] as List] : data['results'] as List;
      });
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else { AppToast.error('Error', 'Error de conexión'); }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _nextUrl == null) return;
    setState(() => _loadingMore = true);
    await _fetchPage(url: _nextUrl, append: true);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _handleDelete(Map<String, dynamic> ex) async {
    final ok = await showConfirmDialog(context, '¿Eliminar el ejercicio "${ex['name']}"?');
    if (!ok) return;
    try {
      await AuthService.delete('/admin/training-plans/exercises/update/${ex['id']}/');
      AppToast.success('Ejercicio eliminado', '');
      setState(() => _loading = true); _fetchPage();
    } on DioException catch (_) { AppToast.error('Error', 'No se pudo eliminar el ejercicio'); }
  }

  void _showFormDialog({Map<String, dynamic>? editing}) {
    final isDarkMode = context.read<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    final typeCtrl = ValueNotifier<String>(editing?['type']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: editing?['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: editing?['description']?.toString() ?? '');

    final typeItems = exercisesMap.entries
        .map((e) => PickerItem(label: e.value, value: e.key))
        .toList();

    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: t.secondBackground,
        title: Text(editing == null ? 'Nuevo Ejercicio' : 'Editar Ejercicio',
            style: TextStyle(color: t.text, fontSize: 18), textAlign: TextAlign.center),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          PickerSelect(
            value: typeCtrl.value,
            onValueChange: (v) => setS(() => typeCtrl.value = v?.toString() ?? ''),
            items: [const PickerItem(label: 'Seleccionar grupo...', value: ''), ...typeItems],
            placeholder: 'Seleccionar grupo muscular',
          ),
          const SizedBox(height: 8),
          _tf(nameCtrl, 'Nombre del ejercicio', t),
          _tf(descCtrl, 'Descripción', t, maxLines: 3),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar', style: TextStyle(color: t.buttonTextCancel))),
          TextButton(
            onPressed: () async {
              if (typeCtrl.value.isEmpty || nameCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                AppToast.error('Campos incompletos', 'Completá tipo, nombre y descripción'); return;
              }
              Navigator.of(ctx).pop();
              try {
                final payload = {
                  'type': typeCtrl.value,
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                };
                if (editing == null) {
                  await AuthService.post('/admin/training-plans/exercises/create/', data: payload);
                  AppToast.success('Ejercicio creado', '');
                } else {
                  await AuthService.put('/admin/training-plans/exercises/update/${editing['id']}/', data: payload);
                  AppToast.success('Ejercicio actualizado', '');
                }
                setState(() => _loading = true); _fetchPage();
              } on DioException catch (e) {
                final d = e.response?.data?['data']?['error_detail']?.toString() ?? '';
                AppToast.error('', d.isNotEmpty ? d : 'Error al guardar el ejercicio');
              } finally { nameCtrl.dispose(); descCtrl.dispose(); }
            },
            child: Text('Guardar', style: TextStyle(color: t.buttonTextConfirm)),
          ),
        ],
      )),
    );
  }

  static Widget _tf(TextEditingController c, String hint, AppThemeColors t, {int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: TextField(controller: c, maxLines: maxLines,
              style: TextStyle(fontSize: 15, color: t.text),
              decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: t.secondText),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.text, width: 2)))));

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: () {
      setState(() { _connectionError = false; _loading = true; }); _fetchPage();
    });
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    final typeItems = [
      const PickerItem(label: 'Todos los grupos', value: ''),
      ...exercisesMap.entries.map((e) => PickerItem(label: e.value, value: e.key)),
    ];

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(25, 16, 25, 8), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Ejercicios', style: TextStyle(fontSize: 22, color: t.text, fontWeight: FontWeight.bold)),
          TouchableButton(title: '+ Nuevo', onPress: () => _showFormDialog()),
        ]),
        const SizedBox(height: 10),
        PickerSelect(
          value: _typeFilter,
          onValueChange: (v) { setState(() => _typeFilter = v?.toString() ?? ''); _onFilterChanged(); },
          items: typeItems,
          placeholder: 'Filtrar por grupo muscular',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          style: TextStyle(color: t.text),
          onChanged: (_) => _onFilterChanged(),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre', hintStyle: TextStyle(color: t.secondText),
            filled: true, fillColor: t.secondBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ])),
      Expanded(child: _loading && _exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? Center(child: Text('Sin ejercicios...', style: TextStyle(color: t.text)))
              : ScrollContainer(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
                  onEndReached: _handleLoadMore, loadingMore: _loadingMore,
                  children: _exercises.map((ex) => Container(
                    width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.secondText.withAlpha(80))),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ex['name']?.toString() ?? '',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: t.text)),
                        Text(formatExerciseType(ex['type']?.toString() ?? ''),
                            style: TextStyle(fontSize: 13, color: t.secondText)),
                        if (ex['description'] != null)
                          Text(ex['description'].toString(), style: TextStyle(fontSize: 13, color: t.secondText),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      GestureDetector(onTap: () => _showFormDialog(editing: ex as Map<String, dynamic>),
                          child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.edit, size: 22, color: t.icon))),
                      GestureDetector(onTap: () => _handleDelete(ex as Map<String, dynamic>),
                          child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.delete, size: 22, color: t.icon))),
                    ]),
                  )).toList(),
                )),
    ]);
  }
}
