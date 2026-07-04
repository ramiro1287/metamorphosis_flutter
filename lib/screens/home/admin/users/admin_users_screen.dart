import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../context/gym_provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_theme.dart';
import '../../../../constants/users.dart';
import '../../../../components/no_connection/no_connection_screen.dart';
import '../../../../components/containers/scroll_container.dart';
import '../../../../components/buttons/touchable_button.dart';
import '../../../../components/toast/app_toast.dart';
import '../../../../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _pageSize = 20;
  List<dynamic> _users = [];
  String? _nextUrl;
  bool _loading = false;
  bool _loadingMore = false;
  bool _connectionError = false;

  final _dniCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _dniCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _loading = true);
      await _fetchPage(reset: true);
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _fetchPage({String? url, bool reset = false, bool append = false}) async {
    try {
      final String finalUrl;
      if (url != null) {
        finalUrl = url;
      } else {
        final q = StringBuffer('/admin/users/list/?page_size=$_pageSize');
        if (_dniCtrl.text.isNotEmpty) q.write('&id_number=${_dniCtrl.text}');
        if (_firstCtrl.text.isNotEmpty) q.write('&first_name=${_firstCtrl.text}');
        if (_lastCtrl.text.isNotEmpty) q.write('&last_name=${_lastCtrl.text}');
        finalUrl = q.toString();
      }

      final r = await AuthService.get(finalUrl);
      final data = r.data['data'] as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _nextUrl = data['next'] as String?;
          _users = append ? [..._users, ...results] : results;
        });
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    } finally {
      if (mounted && !append) setState(() => _loading = false);
    }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _nextUrl == null) return;
    setState(() => _loadingMore = true);
    await _fetchPage(url: _nextUrl, append: true);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _fetchPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) {
      return NoConnectionScreen(onRetry: () {
        setState(() { _connectionError = false; _loading = true; });
        _fetchPage();
      });
    }

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Usuarios', style: TextStyle(fontSize: 22, color: t.text)),
                  TouchableButton(
                    title: 'Nuevo Usuario',
                    onPress: () async {
                      await context.push('/admin-create-user');
                      _reload();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SearchField(
                ctrl: _dniCtrl, placeholder: 'Buscar por DNI', t: t,
                onChanged: (_) => _onFilterChanged(),
              ),
              const SizedBox(height: 6),
              _SearchField(
                ctrl: _firstCtrl, placeholder: 'Buscar por nombre', t: t,
                onChanged: (_) => _onFilterChanged(),
              ),
              const SizedBox(height: 6),
              _SearchField(
                ctrl: _lastCtrl, placeholder: 'Buscar por apellido', t: t,
                onChanged: (_) => _onFilterChanged(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Text('Sin usuarios...',
                          style: TextStyle(fontSize: 22, color: t.text)))
                  : ScrollContainer(
                      padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
                      onEndReached: _handleLoadMore,
                      loadingMore: _loadingMore,
                      children: _users.map((u) {
                        final isInactive = u['status'] != statusActive;
                        final borderColor =
                            isInactive ? errorButtonTextDark : t.text;
                        final isTrainee = u['role'] == traineeRole;

                        return GestureDetector(
                          onTap: () async {
                            await context.push('/admin-user-detail',
                                extra: {'idNumber': u['id_number']});
                            _reload();
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _InfoRow('DNI:', '${u['id_number']}${u['nickname'] != null ? ' (${u['nickname']})' : ''}', t),
                                      _InfoRow('Nombre:', u['first_name']?.toString() ?? '', t),
                                      _InfoRow('Apellido:', u['last_name']?.toString() ?? '', t),
                                    ],
                                  ),
                                ),
                                // Botón cuotas (solo trainees)
                                if (isTrainee)
                                  GestureDetector(
                                    onTap: () => context.push(
                                      '/admin-user-payments',
                                      extra: {
                                        'idNumber': u['id_number'],
                                        'fullName':
                                            '${u['first_name']} ${u['last_name']}',
                                      },
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: t.buttonBackground,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.credit_card,
                                              size: 24, color: t.buttonText),
                                          const SizedBox(height: 4),
                                          Text('Cuotas',
                                              style: TextStyle(
                                                  color: t.buttonText,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
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

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String placeholder;
  final AppThemeColors t;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.ctrl, required this.placeholder, required this.t, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: TextStyle(color: t.text),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: t.secondText),
          filled: true,
          fillColor: t.secondBackground,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;
  const _InfoRow(this.label, this.value, this.t);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: t.secondText)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: t.text)),
          ),
        ]),
      );
}
