import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/payments.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminUserPaymentsScreen extends StatefulWidget {
  final String idNumber;
  final String fullName;
  const AdminUserPaymentsScreen(
      {super.key, required this.idNumber, required this.fullName});
  @override
  State<AdminUserPaymentsScreen> createState() =>
      _AdminUserPaymentsScreenState();
}

class _AdminUserPaymentsScreenState extends State<AdminUserPaymentsScreen> {
  static const _pageSize = 10;
  List<dynamic> _payments = [];
  String? _nextUrl;
  bool _loading = true;
  bool _loadingMore = false;
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage({String? url, bool append = false}) async {
    try {
      final finalUrl = url ??
          '/admin/payments/user/${widget.idNumber}/?page_size=$_pageSize';
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _nextUrl == null) return;
    setState(() => _loadingMore = true);
    await _fetchPage(url: _nextUrl, append: true);
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) {
      return NoConnectionScreen(
        onRetry: () {
          setState(() { _connectionError = false; _loading = true; });
          _fetchPage();
        },
      );
    }

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Text('Cuotas de ${widget.fullName}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: t.text)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading && _payments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _payments.isEmpty
                  ? Center(child: Text('Sin cuotas...', style: TextStyle(fontSize: 20, color: t.text)))
                  : ScrollContainer(
                      padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
                      onEndReached: _handleLoadMore,
                      loadingMore: _loadingMore,
                      children: _payments.map((p) {
                        final status = p['status']?.toString() ?? '';
                        final isPending = status == payStatusPending ||
                            status == payStatusProcessing;
                        final borderColor = isPending ? errorButtonTextDark : t.text;
                        final statusColor =
                            (status == payStatusCompleted || status == payStatusCanceled)
                                ? buttonTextConfirmDark
                                : inputErrorDark;

                        return GestureDetector(
                          onTap: () async {
                            await context.push('/admin-user-payment-detail',
                                extra: {'paymentId': p['id'], 'fullName': widget.fullName});
                            // Recarga al volver (equiv. useFocusEffect)
                            if (mounted) {
                              setState(() => _loading = true);
                              _fetchPage();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: t.secondBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border(
                                top: BorderSide(color: borderColor, width: 1),
                                bottom: BorderSide(color: borderColor, width: 1),
                                left: BorderSide(color: borderColor, width: 4),
                                right: BorderSide(color: borderColor, width: 4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CardRow('Estado:', formatPaymentStatus(status), t, statusColor),
                                _CardRow('Valor de la cuota:', '\$${p['total_amount']}', t, null),
                                _CardRow('Monto a pagar:', '\$${getFinalAmount(p)}', t, null),
                                _CardRow('Mes:', getMonth(p['created_at']?.toString() ?? ''), t, null),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  final String title;
  final String value;
  final AppThemeColors t;
  final Color? valueColor;
  const _CardRow(this.title, this.value, this.t, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: t.secondText)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(value,
                  style: TextStyle(fontSize: 18, color: valueColor ?? t.text)),
            ),
          ],
        ),
      );
}
