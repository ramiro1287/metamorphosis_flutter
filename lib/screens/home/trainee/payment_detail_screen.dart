import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../context/gym_provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../constants/payments.dart';
import '../../../components/loading/loading_screen.dart';
import '../../../components/no_connection/no_connection_screen.dart';
import '../../../components/containers/scroll_container.dart';
import '../../../components/buttons/touchable_button.dart';
import '../../../components/toast/app_toast.dart';
import '../../../services/auth_service.dart';
import '../../../utils/formatters.dart';

class PaymentDetailScreen extends StatefulWidget {
  final dynamic paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  Map<String, dynamic>? _payment;
  bool _connectionError = false;
  bool _isProcessingPay = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final response =
          await AuthService.get('/payments/detail/${widget.paymentId}/');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _payment = data);
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _handleCheckout() async {
    final user = context.read<GymProvider>().user;
    if (user?.toJson()['email'] == null ||
        user!.toJson()['email'].toString().isEmpty) {
      AppToast.error(
          'Necesitas un email', 'Por favor, contacta a un entrenador.');
      return;
    }

    setState(() => _isProcessingPay = true);
    try {
      final response = await AuthService.post(
          '/payments/checkout/${_payment!['id']}/');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() => _payment = data);
        final url = data['payment_url']?.toString();
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          AppToast.error('Error', 'No se encontró el link de pago');
        }
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['error_detail']?.toString() ??
          'No se pudo iniciar el pago';
      AppToast.error('Error', detail);
    } catch (_) {
      AppToast.error('Error', 'Error de conexión al procesar el pago');
    } finally {
      if (mounted) setState(() => _isProcessingPay = false);
    }
  }

  bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);
    if (_payment == null) return const LoadingScreen();

    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);
    final payment = _payment!;
    final status = payment['status']?.toString() ?? '';
    final mercadopagoEnabled =
        gymProvider.gymInfo?.mercadopagoCheckoutEnabled ?? false;
    final statusColor =
        (status == payStatusCompleted || status == payStatusCanceled)
            ? buttonTextConfirmDark
            : inputErrorDark;
    final penalties =
        payment['penalties'] as List<dynamic>? ?? [];
    final discounts =
        payment['discounts'] as List<dynamic>? ?? [];

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: t.secondBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Campos principales ----
              _CardRow(title: 'Estado:', t: t,
                  value: formatPaymentStatus(status), valueColor: statusColor),
              _CardRow(
                title: 'Fecha de pago:',
                value: payment['date_paid'] != null
                    ? formatDate(payment['date_paid'].toString())
                    : 'N/A',
                t: t,
              ),
              _CardRow(
                title: 'Forma de pago:',
                value: payment['payment_method']?['name']?.toString() ?? 'N/A',
                t: t,
              ),
              _CardRow(
                  title: 'Valor de la cuota:',
                  value: '\$${payment['total_amount']}',
                  t: t),
              _CardRow(
                  title: 'Monto a pagar:',
                  value: '\$${getFinalAmount(payment)}',
                  t: t),
              _CardRow(
                  title: 'Mes correspondiente:',
                  value: getMonth(payment['created_at']?.toString() ?? ''),
                  t: t),

              // ---- Botón MercadoPago ----
              if (mercadopagoEnabled &&
                  (status == payStatusPending ||
                      status == payStatusProcessing)) ...[
                const SizedBox(height: 12),
                TouchableButton(
                  title: (payment['payment_url'] != null &&
                          status == payStatusProcessing)
                      ? 'Continuar con el pago'
                      : 'Pagar cuota',
                  onPress: _handleCheckout,
                  loading: _isProcessingPay,
                  icon: Icon(Icons.payment, size: 22, color: t.buttonText),
                ),
              ],

              // ---- Penalizaciones ----
              if (penalties.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text('Penalizaciones aplicadas',
                      style: TextStyle(fontSize: 18, color: t.text)),
                ),
                const SizedBox(height: 8),
                ...penalties.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}) ${p['penalty']?['description'] ?? ''}',
                        style: TextStyle(fontSize: 16, color: t.secondText),
                      ),
                      Row(
                        children: [
                          Text('\$${p['amount']}',
                              style: const TextStyle(
                                  fontSize: 18, color: inputErrorDark)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_upward,
                              size: 24, color: inputErrorDark),
                        ],
                      ),
                    ],
                  );
                }),
              ],

              // ---- Descuentos ----
              if (discounts.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text('Descuentos aplicados',
                      style: TextStyle(fontSize: 18, color: t.text)),
                ),
                const SizedBox(height: 8),
                ...discounts.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}) ${d['discount']?['description'] ?? ''}',
                        style: TextStyle(fontSize: 16, color: t.secondText),
                      ),
                      Row(
                        children: [
                          Text('\$${d['fixed_amount']}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: buttonTextConfirmDark)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_downward,
                              size: 24, color: buttonTextConfirmDark),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, color: t.secondText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: valueColor ?? t.text,
            ),
          ),
        ],
      ),
    );
  }
}
