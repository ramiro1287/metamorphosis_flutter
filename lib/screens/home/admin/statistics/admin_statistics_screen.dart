import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/payments.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/picker/picker_select.dart';
import '../../../../components/picker/date_picker_modal.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});
  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  Map<String, dynamic>? _earnings;
  List<dynamic> _payments = [];
  String _paymentStatus = payStatusPending;
  DateTime _queryDate = DateTime.now();
  String? _nextUrl;
  bool _loading = true;
  bool _loadingMore = false;
  bool _connectionError = false;

  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _connectionError = false; _loading = true; });
    await Future.wait([_getEarnings(), _getPayments()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _getEarnings() async {
    try {
      final r = await AuthService.get(
          '/admin/payments/earnings/?date=${_queryDate.toIso8601String()}');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _earnings = data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      }
    }
  }

  Future<void> _getPayments({String? url, bool append = false}) async {
    try {
      final finalUrl = url ??
          '/admin/payments/?date=${_queryDate.toIso8601String()}&status=$_paymentStatus&page_size=$_pageSize';
      final r = await AuthService.get(finalUrl);
      final data = r.data['data'] as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _nextUrl = data['next'] as String?;
          _payments = append ? [..._payments, ...results] : results;
        });
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _nextUrl == null) return;
    setState(() => _loadingMore = true);
    await _getPayments(url: _nextUrl, append: true);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _handleNotify(dynamic paymentId) async {
    final ok = await showConfirmDialog(
        context, '¿Quieres notificar la falta de pago de esta cuota?');
    if (!ok) return;
    try {
      await AuthService.post('/admin/notifications/notify/', data: {
        'notif_key': 'PAYMENT_REMINDER',
        'payment_id': paymentId,
      });
      AppToast.success('Notificación enviada', '');
    } on DioException catch (e) {
      final detail =
          e.response?.data?['data']?['error_detail']?.toString() ?? '';
      AppToast.error('', detail.isNotEmpty ? detail : 'Error de conexión');
    }
  }

  Future<void> _onFilterChanged() async {
    setState(() { _loading = true; _payments = []; });
    await Future.wait([_getEarnings(), _getPayments()]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _loadAll);

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    final month = monthsMap[_queryDate.toUtc().month] ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Column(
            children: [
              Text('Estadísticas',
                  style: TextStyle(fontSize: 22, color: t.text)),
              const SizedBox(height: 12),
              // ---- Card de ganancias ----
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: t.secondBackground,
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Ingresos $month ${_queryDate.year}',
                            style: TextStyle(color: t.secondText, fontSize: 16),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showAppDatePicker(
                              context: context,
                              initialDate: _queryDate,
                              firstDate: DateTime(2025),
                            );
                            if (picked != null) {
                              setState(() => _queryDate = picked);
                              _onFilterChanged();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_calendar,
                                size: 25, color: t.icon),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _EarningsRow('Ganancias',
                        '\$ ${_earnings?['payments_completed_total'] ?? '-'}', t),
                    _EarningsRow('Pendientes',
                        '\$ ${_earnings?['payments_pending_total'] ?? '-'}', t),
                    _EarningsRow('Cancelados',
                        '\$ ${_earnings?['payments_canceled_total'] ?? '-'}', t),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ---- Selector de estado ----
              Row(
                children: [
                  Text('Cuotas ',
                      style: TextStyle(fontSize: 22, color: t.text)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PickerSelect(
                      value: _paymentStatus,
                      onValueChange: (v) {
                        setState(() => _paymentStatus = v.toString());
                        _onFilterChanged();
                      },
                      items: const [
                        PickerItem(label: 'Pagadas', value: payStatusCompleted),
                        PickerItem(label: 'Pendientes/Procesando', value: payStatusPending),
                        PickerItem(label: 'Canceladas', value: payStatusCanceled),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading && _payments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _payments.isEmpty
                  ? Center(
                      child: Text('Sin Cuotas',
                          style: TextStyle(color: t.text, fontSize: 18)))
                  : ScrollContainer(
                      padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
                      onEndReached: _handleLoadMore,
                      loadingMore: _loadingMore,
                      children: _payments
                          .map((p) => GestureDetector(
                                onTap: () async {
                                  await context.push(
                                    '/admin-user-payment-detail',
                                    extra: {
                                      'paymentId': p['id'],
                                      'fullName':
                                          p['user_fullname']?.toString() ?? '',
                                    },
                                  );
                                  // Recarga al volver del detalle (equiv. useFocusEffect)
                                  if (mounted) _onFilterChanged();
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(15),
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
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Text('Usuario: ',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: t.secondText)),
                                              Expanded(
                                                child: Text(
                                                  p['user_fullname']?.toString() ?? '',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: t.text),
                                                ),
                                              ),
                                            ]),
                                            Row(children: [
                                              Text('Monto: ',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: t.secondText)),
                                              Text(
                                                '\$${getFinalAmount(p)}',
                                                style: TextStyle(
                                                    fontSize: 18, color: t.text),
                                              ),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      if (_paymentStatus == payStatusPending)
                                        GestureDetector(
                                          onTap: () => _handleNotify(p['id']),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(Icons.forward_to_inbox,
                                                size: 25, color: t.icon),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
        ),
      ],
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;
  const _EarningsRow(this.label, this.value, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: t.secondText, fontSize: 16)),
            Text(value, style: TextStyle(color: t.text, fontSize: 16)),
          ],
        ),
      );
}
