import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/training_plans.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminUserTrainingPlansScreen extends StatefulWidget {
  final String idNumber;
  final String fullName;
  const AdminUserTrainingPlansScreen({super.key, required this.idNumber, required this.fullName});
  @override
  State<AdminUserTrainingPlansScreen> createState() => _State();
}

class _State extends State<AdminUserTrainingPlansScreen> {
  List<dynamic> _plans = [];
  String? _nextUrl;
  bool _loading = true;
  bool _loadingMore = false;
  bool _connectionError = false;

  @override
  void initState() { super.initState(); _fetchPage(); }

  Future<void> _fetchPage({String? url, bool append = false}) async {
    try {
      final finalUrl = url ?? '/admin/training-plans/list/${widget.idNumber}/?page_size=10';
      final r = await AuthService.get(finalUrl);
      final data = r.data['data'] as Map<String, dynamic>;
      if (mounted) setState(() {
        _nextUrl = data['next'] as String?;
        _plans = append ? [..._plans, ...data['results'] as List] : data['results'] as List;
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

  bool get _hasActivePlan => _plans.any((p) => p['status'] == planStatusActive);

  void _goCreate() {
    if (_hasActivePlan) { AppToast.info('Ya existe un plan activo', ''); return; }
    context.push('/admin-user-training-plan-create',
        extra: {'idNumber': widget.idNumber, 'fullName': widget.fullName});
  }

  Future<void> _goAssign() async {
    if (_hasActivePlan) { AppToast.info('Ya existe un plan activo', ''); return; }
    await context.push('/admin-user-training-plan-assign',
        extra: {'idNumber': widget.idNumber, 'fullName': widget.fullName});
    if (mounted) { setState(() => _loading = true); _fetchPage(); }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: () {
      setState(() { _connectionError = false; _loading = true; }); _fetchPage();
    });
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Planes de ${widget.fullName}',
              style: TextStyle(fontSize: 20, color: t.text)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: TouchableButton(title: 'Asignar existente', onPress: _goAssign)),
            const SizedBox(width: 8),
            Flexible(child: TouchableButton(title: 'Crear personalizado', onPress: _goCreate)),
          ]),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(child: _loading && _plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? Center(child: Text('Sin planes...', style: TextStyle(color: t.text, fontSize: 18)))
              : ScrollContainer(
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
                  onEndReached: _handleLoadMore, loadingMore: _loadingMore,
                  children: _plans.map((plan) {
                    final status = plan['status']?.toString() ?? '';
                    final isActive = status == planStatusActive;
                    final borderColor = isActive ? buttonTextConfirmDark : t.text;
                    return GestureDetector(
                      onTap: () async {
                        await context.push('/admin-user-training-plan-detail',
                            extra: {'idNumber': widget.idNumber, 'planId': plan['id'], 'fullName': widget.fullName});
                        setState(() => _loading = true); _fetchPage();
                      },
                      child: Container(
                        width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: t.secondBackground, borderRadius: BorderRadius.circular(20),
                            border: Border(top: BorderSide(color: borderColor, width: 1), bottom: BorderSide(color: borderColor, width: 1),
                                left: BorderSide(color: borderColor, width: 4), right: BorderSide(color: borderColor, width: 4))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Row('Estado:', formatPlanStatus(status), t),
                          _Row('Vence:', formatDate(plan['expiration_date']?.toString(), fallback: 'Sin vencimiento'), t),
                          if (plan['description'] != null) _Row('Anotaciones:', plan['description'].toString(), t),
                        ]),
                      ),
                    );
                  }).toList(),
                )),
    ]);
  }
}
class _Row extends StatelessWidget {
  final String l, v; final AppThemeColors t;
  const _Row(this.l, this.v, this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text(l, style: TextStyle(fontSize: 16, color: t.secondText, fontWeight: FontWeight.bold)),
      const SizedBox(width: 6),
      Flexible(child: Text(v, style: TextStyle(fontSize: 16, color: t.text), overflow: TextOverflow.ellipsis)),
    ]));
}
