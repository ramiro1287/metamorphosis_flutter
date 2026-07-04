import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminTrainingPlansScreen extends StatefulWidget {
  const AdminTrainingPlansScreen({super.key});
  @override
  State<AdminTrainingPlansScreen> createState() => _State();
}

class _State extends State<AdminTrainingPlansScreen> {
  List<dynamic> _templates = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetchPage(); }

  Future<void> _fetchPage({String? url, bool append = false}) async {
    try {
      final r = await AuthService.get(url ?? '/admin/training-plans/templates/?page_size=10');
      final data = r.data['data'] as Map<String, dynamic>;
      if (mounted) setState(() {
        _templates = append ? [..._templates, ...data['results'] as List] : data['results'] as List;
      });
    } on DioException catch (e) {
      if (e.type != DioExceptionType.connectionError) { AppToast.error('Error', 'Error de conexión'); }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(25, 16, 25, 0), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Plantillas de Entrenamiento', style: TextStyle(fontSize: 20, color: t.text)),
          TouchableButton(title: 'Nueva', onPress: () async {
            await context.push('/admin-training-plan-create');
            setState(() => _loading = true); _fetchPage();
          }),
        ],
      )),
      const SizedBox(height: 8),
      Expanded(child: _loading && _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(child: Text('Sin plantillas...', style: TextStyle(color: t.text)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
                  child: Column(children: _templates.map((tmpl) => GestureDetector(
                    onTap: () async {
                      await context.push('/admin-training-plan-detail', extra: {'templateId': tmpl['id']});
                      setState(() => _loading = true); _fetchPage();
                    },
                    child: Container(
                      width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(20),
                          border: Border(top: BorderSide(color: t.text, width: 1), bottom: BorderSide(color: t.text, width: 1),
                              left: BorderSide(color: t.text, width: 4), right: BorderSide(color: t.text, width: 4))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tmpl['title']?.toString() ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
                        if (tmpl['description'] != null)
                          Text(tmpl['description'].toString(), style: TextStyle(fontSize: 14, color: t.secondText), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  )).toList()),
                )),
    ]);
  }
}
