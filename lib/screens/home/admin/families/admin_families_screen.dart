import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminFamiliesScreen extends StatefulWidget {
  const AdminFamiliesScreen({super.key});
  @override
  State<AdminFamiliesScreen> createState() => _AdminFamiliesScreenState();
}

class _AdminFamiliesScreenState extends State<AdminFamiliesScreen> {
  List<dynamic> _families = [];
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final r = await AuthService.get('/admin/users/family/');
      final data = r.data['data'];
      if (mounted) setState(() => _families = data is List ? data : []);
    } on DioException catch (e) {
      if (_isConn(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  bool _isConn(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout;

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Familias', style: TextStyle(fontSize: 22, color: t.text)),
              TouchableButton(
                title: 'Nueva Familia',
                onPress: () async {
                  await context.push('/admin-family-create');
                  _load(); // Recarga al volver (equiv. useFocusEffect)
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _families.isEmpty
              ? Center(child: Text('Sin familias...', style: TextStyle(fontSize: 22, color: t.text)))
              : ScrollContainer(
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
                  children: _families
                      .map((f) => GestureDetector(
                            onTap: () async {
                              await context.push('/admin-family-detail',
                                  extra: {'familyId': f['id']});
                              _load(); // Recarga al volver del detalle
                            },
                            child: _BorderedCard(
                              isDarkMode: isDarkMode,
                              child: Row(
                                children: [
                                  Text('Nombre: ',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: t.secondText)),
                                  Expanded(
                                    child: Text(f['name']?.toString() ?? '',
                                        style: TextStyle(
                                            fontSize: 20, color: t.text)),
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

class _BorderedCard extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;
  const _BorderedCard({required this.isDarkMode, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    return Container(
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
      child: child,
    );
  }
}
