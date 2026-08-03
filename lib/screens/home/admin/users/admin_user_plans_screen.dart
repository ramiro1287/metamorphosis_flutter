import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/alerts/confirm_dialog.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminUserPlansScreen extends StatefulWidget {
  const AdminUserPlansScreen({super.key});
  @override
  State<AdminUserPlansScreen> createState() => _AdminUserPlansScreenState();
}

class _AdminUserPlansScreenState extends State<AdminUserPlansScreen> {
  Map<String, dynamic>? _editingPlan;
  String _priceError = '';

  void _handleEditPlan(Map<String, dynamic> plan) {
    setState(() {
      _editingPlan = Map<String, dynamic>.from(plan);
      _priceError = '';
    });
  }

  Future<void> _handleUpdatePrice() async {
    final parsed = double.tryParse(_editingPlan!['price']?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      setState(() => _priceError = 'Ingrese un precio válido');
      return;
    }

    final ok = await showConfirmDialog(
        context, '¿Estás seguro de actualizar el precio del plan?');
    if (!ok) {
      return;
    }

    try {
      await AuthService.put(
          '/admin/users/update-plan/${_editingPlan!["id"]}/',
          data: {'price': double.parse(parsed.toStringAsFixed(2))});

      // Oculta el formulario de edición en caso de éxito
      setState(() {
        _editingPlan = null;
        _priceError = '';
      });

      // Recarga gymInfo para que los planes muestren el precio actualizado
      if (mounted) {
        await context.read<GymProvider>().getGymInfo();
        AppToast.success('Precio actualizado correctamente', '');
      }
    } on DioException {
      AppToast.error('Error', 'No se pudo actualizar el precio');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);
    final plans = gymProvider.gymInfo?.plans ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Text('Tipo de planes',
              style: TextStyle(fontSize: 22, color: t.text)),
        ),
        Expanded(
          child: plans.isEmpty
              ? Center(child: Text('Sin planes...', style: TextStyle(fontSize: 22, color: t.text)))
              : ScrollContainer(
                  padding: const EdgeInsets.fromLTRB(25, 12, 25, 30),
                  children: [
                    ...plans.map((plan) => GestureDetector(
                          onTap: () => _handleEditPlan(plan as Map<String, dynamic>),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text('Plan: ',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.secondText)),
                                  Text(plan['name']?.toString() ?? '',
                                      style: TextStyle(fontSize: 20, color: t.text)),
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text('Precio: ',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.secondText)),
                                  Text('${plan['price']}',
                                      style: TextStyle(fontSize: 20, color: t.text)),
                                ]),
                              ],
                            ),
                          ),
                        )),

                    // Modal inline de edición de precio
                    if (_editingPlan != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: t.secondBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.text, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editar precio del plan: ${_editingPlan!['name']}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: t.text),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                              controller: TextEditingController(
                                  text: _editingPlan!['price']?.toString() ?? ''),
                              onChanged: (v) {
                                _editingPlan!['price'] = v;
                                setState(() => _priceError = '');
                              },
                              style: TextStyle(fontSize: 18, color: t.text),
                              decoration: InputDecoration(
                                hintText: 'Ingrese precio del plan',
                                hintStyle: TextStyle(color: t.secondText),
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: t.text)),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: t.text, width: 2)),
                              ),
                            ),
                            if (_priceError.isNotEmpty)
                              Text(_priceError,
                                  style: TextStyle(color: t.inputError, fontSize: 14)),
                            const SizedBox(height: 16),
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              TouchableButton(
                                title: 'Cancelar',
                                onPress: () => setState(() { _editingPlan = null; _priceError = ''; }),
                                variant: ButtonVariant.error,
                              ),
                              const SizedBox(width: 12),
                              TouchableButton(
                                title: 'Guardar',
                                onPress: _handleUpdatePrice,
                              ),
                            ]),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
