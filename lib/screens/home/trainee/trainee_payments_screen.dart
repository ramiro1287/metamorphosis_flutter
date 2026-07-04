import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../context/gym_provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../constants/payments.dart';
import '../../../components/no_connection/no_connection_screen.dart';
import '../../../components/containers/scroll_container.dart';
import '../../../components/toast/app_toast.dart';
import '../../../services/auth_service.dart';
import '../../../utils/formatters.dart';

class TraineePaymentsScreen extends StatefulWidget {
  const TraineePaymentsScreen({super.key});

  @override
  State<TraineePaymentsScreen> createState() => _TraineePaymentsScreenState();
}

class _TraineePaymentsScreenState extends State<TraineePaymentsScreen> {
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
      final finalUrl = url ?? '/payments/list/?page_size=$_pageSize';
      final response = await AuthService.get(finalUrl);
      final data = response.data['data'] as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      final next = data['next'] as String?;

      if (mounted) {
        setState(() {
          _nextUrl = next;
          _payments = append ? [..._payments, ...results] : results;
        });
      }
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _nextUrl == null) return;
    setState(() => _loadingMore = true);
    await _fetchPage(url: _nextUrl, append: true);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _handleRetry() async {
    setState(() {
      _connectionError = false;
      _loading = true;
    });
    await _fetchPage();
    if (mounted) setState(() => _loading = false);
  }

  bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _handleRetry);

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Text(
            'Lista de cuotas',
            style: TextStyle(fontSize: 22, color: t.text),
          ),
        ),
        Expanded(
          child: _loading && _payments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _payments.isEmpty
                  ? Center(
                      child: Text('Sin cuotas...',
                          style: TextStyle(fontSize: 22, color: t.text)))
                  : ScrollContainer(
                      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
                      onEndReached: _handleLoadMore,
                      loadingMore: _loadingMore,
                      children: _payments
                          .map((p) => _PaymentCard(
                                payment: p,
                                isDarkMode: isDarkMode,
                                onTap: () => context.push(
                                  '/payment-detail',
                                  extra: {'paymentId': p['id']},
                                ),
                              ))
                          .toList(),
                    ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.payment,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    final status = payment['status']?.toString() ?? '';
    final isPendingOrProcessing =
        status == payStatusPending || status == payStatusProcessing;
    final borderColor =
        isPendingOrProcessing ? errorButtonTextDark : t.text;

    final statusColor =
        (status == payStatusCompleted || status == payStatusCanceled)
            ? buttonTextConfirmDark
            : inputErrorDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
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
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardRow(
              title: 'Estado:',
              value: formatPaymentStatus(status),
              valueColor: statusColor,
              t: t,
            ),
            _CardRow(
              title: 'Valor de la cuota:',
              value: '\$${payment['total_amount']}',
              t: t,
            ),
            _CardRow(
              title: 'Monto a pagar:',
              value: '\$${getFinalAmount(payment)}',
              t: t,
            ),
            _CardRow(
              title: 'Mes correspondiente:',
              value: getMonth(payment['created_at']?.toString() ?? ''),
              t: t,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final AppThemeColors t;

  const _CardRow({
    required this.title,
    required this.value,
    required this.t,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, color: t.secondText, height: 1.4)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: valueColor ?? t.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
