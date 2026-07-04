import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/payments.dart';
import '../../../../components/loading/loading_screen.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/picker/picker_select.dart';
import '../../../../components/picker/date_picker_modal.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/formatters.dart';

class AdminUserPaymentDetailScreen extends StatefulWidget {
  final dynamic paymentId;
  final String fullName;
  const AdminUserPaymentDetailScreen(
      {super.key, required this.paymentId, required this.fullName});
  @override
  State<AdminUserPaymentDetailScreen> createState() =>
      _AdminUserPaymentDetailScreenState();
}

class _AdminUserPaymentDetailScreenState
    extends State<AdminUserPaymentDetailScreen> {
  Map<String, dynamic>? _payment;
  bool _connectionError = false;
  bool _isEditing = false;
  Map<String, dynamic> _editedFields = {};

  bool get _hasChanges => _editedFields.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get(
          '/admin/payments/detail/${widget.paymentId}/');
      final data = r.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) setState(() => _payment = data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  void _handleFieldChange(String field, dynamic value) {
    setState(() => _editedFields[field] = value);
  }

  Future<bool> _doSave({bool skipConfirm = false}) async {
    final payload = Map<String, dynamic>.from(_editedFields);

    if (payload.containsKey('total_amount')) {
      final parsed = double.tryParse(payload['total_amount'].toString());
      if (parsed == null || parsed < 0) {
        AppToast.error('Error', 'Ingrese un precio válido');
        return false;
      }
      payload['total_amount'] = parsed;
    }

    if (payload['date_paid'] is DateTime) {
      final d = payload['date_paid'] as DateTime;
      payload['date_paid'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    if (!skipConfirm) {
      final ok = await showConfirmDialog(context, '¿Guardar todos los cambios?');
      if (!ok) return false;
    }

    try {
      await AuthService.put('/admin/payments/update/${widget.paymentId}/',
          data: payload);
      AppToast.success('Cuota actualizada correctamente', '');
      setState(() {
        _isEditing = false;
        _editedFields = {};
      });
      _load();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        AppToast.error('Error',
            e.response?.data?['data']?['error_detail']?.toString() ?? '');
      } else {
        AppToast.error('Error', 'No se pudo actualizar la cuota');
      }
      return false;
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      if (_hasChanges) {
        _showDiscardDialog();
      } else {
        setState(() { _isEditing = false; _editedFields = {}; });
      }
    } else {
      setState(() => _isEditing = true);
      final pm = context.read<GymProvider>().gymInfo?.paymentMethods ?? [];
      if (_payment?['payment_method'] == null && pm.isNotEmpty) {
        _editedFields['payment_method_id'] = pm[0]['id'];
      }
    }
  }

  Future<void> _showDiscardDialog() async {
    final discard = await showConfirmDialog(
      context,
      '¿Descartar los cambios no guardados?',
      cancelMsg: 'Continuar editando',
      confirmMsg: 'Descartar',
    );
    if (discard && mounted) {
      setState(() { _isEditing = false; _editedFields = {}; });
    }
  }

  Future<void> _handleUpdatePenalty(dynamic penaltyId, String amount) async {
    final ok =
        await showConfirmDialog(context, '¿Estás seguro de actualizar la penalización?');
    if (!ok) return;
    try {
      await AuthService.put('/admin/payments/penalty/$penaltyId/',
          data: {'amount': double.tryParse(amount) ?? 0});
      AppToast.success('Penalización actualizada', '');
      _load();
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo actualizar la penalización');
    }
  }

  Future<void> _handleToggleDiscount(dynamic discountId, bool enabled) async {
    final msg = enabled
        ? '¿Estás seguro de desactivar el descuento?'
        : '¿Estás seguro de activar el descuento?';
    final ok = await showConfirmDialog(context, msg);
    if (!ok) return;
    try {
      await AuthService.put('/admin/payments/discount/$discountId/',
          data: {'enabled': enabled ? 0 : 1});
      AppToast.success(enabled ? 'Descuento desactivado' : 'Descuento activado', '');
      _load();
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo cambiar el descuento');
    }
  }

  Future<void> _handleSyncPayment() async {
    try {
      await AuthService.post(
          '/admin/payments/mercadopago/sync/${widget.paymentId}/');
      AppToast.success('Pago sincronizado', '');
      _load();
    } on DioException catch (_) {
      AppToast.error('Error', 'No se pudo sincronizar el pago');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);
    if (_payment == null) return const LoadingScreen();

    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);
    final p = _payment!;
    final status = p['status']?.toString() ?? '';
    final paymentMethods = gymProvider.gymInfo?.paymentMethods ?? [];
    final penalties = p['penalties'] as List<dynamic>? ?? [];
    final discounts = p['discounts'] as List<dynamic>? ?? [];
    final statusColor =
        (status == payStatusCompleted || status == payStatusCanceled)
            ? buttonTextConfirmDark
            : inputErrorDark;

    return PopScope(
      canPop: !_isEditing || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showDiscardDialog();
      },
      child: ScrollContainer(
        padding: const EdgeInsets.all(25),
        children: [
          Text('Cuota de', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: t.text)),
          Text(widget.fullName, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: t.text)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: t.secondBackground,
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Edit header ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _toggleEdit,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                            _isEditing ? Icons.close : Icons.edit,
                            size: 26, color: t.icon),
                      ),
                    ),
                    if (_isEditing && _hasChanges) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _doSave(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.save,
                              size: 26, color: buttonTextConfirmDark),
                        ),
                      ),
                    ],
                  ],
                ),
                // ---- Estado ----
                _RowLabel('Estado:', t),
                _isEditing
                    ? PickerSelect(
                        value: _editedFields['status'] ?? status,
                        onValueChange: (v) => _handleFieldChange('status', v),
                        items: const [
                          PickerItem(label: 'Pendiente', value: payStatusPending),
                          PickerItem(label: 'Cancelada', value: payStatusCanceled),
                          PickerItem(label: 'Pagada', value: payStatusCompleted),
                        ],
                      )
                    : Text(formatPaymentStatus(status),
                        style: TextStyle(fontSize: 20, color: statusColor)),
                const SizedBox(height: 12),
                // ---- Fecha de pago ----
                _RowLabel('Fecha de pago:', t),
                _isEditing
                    ? GestureDetector(
                        onTap: () async {
                          final picked = await showAppDatePicker(
                            context: context,
                            initialDate: _editedFields['date_paid'] is DateTime
                                ? _editedFields['date_paid'] as DateTime
                                : (p['date_paid'] != null
                                    ? DateTime.tryParse(p['date_paid']) ?? DateTime.now()
                                    : DateTime.now()),
                          );
                          if (picked != null) {
                            _handleFieldChange('date_paid', picked);
                          }
                        },
                        child: Text(
                          _editedFields['date_paid'] is DateTime
                              ? formatDate((_editedFields['date_paid'] as DateTime).toIso8601String())
                              : (p['date_paid'] != null ? formatDate(p['date_paid']) : 'Seleccionar fecha'),
                          style: TextStyle(
                              fontSize: 20, color: t.text,
                              decoration: TextDecoration.underline),
                        ),
                      )
                    : Text(p['date_paid'] != null ? formatDate(p['date_paid']) : 'N/A',
                        style: TextStyle(fontSize: 20, color: t.text)),
                const SizedBox(height: 12),
                // ---- Método de pago ----
                _RowLabel('Forma de pago:', t),
                _isEditing
                    ? PickerSelect(
                        value: _editedFields['payment_method_id'] ??
                            p['payment_method']?['id'],
                        onValueChange: (v) =>
                            _handleFieldChange('payment_method_id', v),
                        items: paymentMethods
                            .map((m) => PickerItem(
                                label: m['name']?.toString() ?? '',
                                value: m['id']))
                            .toList(),
                      )
                    : Text(p['payment_method']?['name']?.toString() ?? 'N/A',
                        style: TextStyle(fontSize: 20, color: t.text)),
                const SizedBox(height: 12),
                // ---- Monto ----
                _RowLabel('Valor de la cuota:', t),
                _isEditing
                    ? TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        controller: TextEditingController(
                            text: _editedFields['total_amount']?.toString() ??
                                p['total_amount']?.toString() ?? ''),
                        onChanged: (v) => _handleFieldChange('total_amount', v),
                        style: TextStyle(fontSize: 20, color: t.text),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: t.text)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: t.text, width: 2)),
                        ),
                      )
                    : Text('\$${p['total_amount']}',
                        style: TextStyle(fontSize: 20, color: t.text)),
                const SizedBox(height: 12),
                _RowLabel('Monto a pagar:', t),
                Text('\$${getFinalAmount(p)}',
                    style: TextStyle(fontSize: 20, color: t.text)),
                const SizedBox(height: 12),
                _RowLabel('Mes:', t),
                Text(getMonth(p['created_at']?.toString() ?? ''),
                    style: TextStyle(fontSize: 20, color: t.text)),

                // ---- Sync MP ----
                if (gymProvider.gymInfo?.mercadopagoCheckoutEnabled == true) ...[
                  const SizedBox(height: 16),
                  TouchableButton(
                      title: 'Sincronizar pago MP',
                      onPress: _handleSyncPayment),
                ],
              ],
            ),
          ),

          // ---- Penalizaciones ----
          if (penalties.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Penalizaciones aplicadas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: t.text)),
            const SizedBox(height: 8),
            ...penalties.map((pen) => _PenaltyCard(
                  penalty: pen as Map<String, dynamic>,
                  isDarkMode: isDarkMode,
                  onUpdate: (penaltyId, amount) =>
                      _handleUpdatePenalty(penaltyId, amount),
                )),
          ],

          // ---- Descuentos ----
          if (discounts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Descuentos aplicados',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: t.text)),
            const SizedBox(height: 8),
            ...discounts.map((disc) => _DiscountCard(
                  discount: disc as Map<String, dynamic>,
                  isDarkMode: isDarkMode,
                  onToggle: (discountId, enabled) =>
                      _handleToggleDiscount(discountId, enabled),
                )),
          ],
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _RowLabel(this.text, this.t);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 18, color: t.secondText));
}

class _PenaltyCard extends StatefulWidget {
  final Map<String, dynamic> penalty;
  final bool isDarkMode;
  final Future<void> Function(dynamic penaltyId, String amount) onUpdate;
  const _PenaltyCard({required this.penalty, required this.isDarkMode, required this.onUpdate});
  @override
  State<_PenaltyCard> createState() => _PenaltyCardState();
}

class _PenaltyCardState extends State<_PenaltyCard> {
  late final TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.penalty['amount']?.toString() ?? '0');
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(widget.isDarkMode);
    final pen = widget.penalty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: const BorderSide(color: inputErrorDark, width: 3),
          right: const BorderSide(color: inputErrorDark, width: 3),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pen['penalty']?['description']?.toString() ?? '',
            style: TextStyle(fontSize: 16, color: t.secondText)),
        Row(children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 18, color: inputErrorDark),
              decoration: InputDecoration(
                  prefixText: '\$',
                  prefixStyle: const TextStyle(color: inputErrorDark),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: t.text)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: t.text, width: 2))),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onUpdate(pen['id'], _ctrl.text),
            child: const Icon(Icons.save, color: inputErrorDark, size: 22),
          ),
        ]),
      ]),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  final Map<String, dynamic> discount;
  final bool isDarkMode;
  final Future<void> Function(dynamic discountId, bool enabled) onToggle;
  const _DiscountCard({required this.discount, required this.isDarkMode, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    final d = discount;
    final enabled = d['discount']?['enabled'] as bool? ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: const BorderSide(color: buttonTextConfirmDark, width: 3),
          right: const BorderSide(color: buttonTextConfirmDark, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['discount']?['description']?.toString() ?? '',
                  style: TextStyle(fontSize: 16, color: t.secondText)),
              Text('\$${d['fixed_amount']}',
                  style: const TextStyle(fontSize: 18, color: buttonTextConfirmDark)),
            ]),
          ),
          GestureDetector(
            onTap: () => onToggle(d['discount']?['id'], enabled),
            child: Icon(enabled ? Icons.toggle_on : Icons.toggle_off,
                size: 32,
                color: enabled ? buttonTextConfirmDark : t.secondText),
          ),
        ],
      ),
    );
  }
}
