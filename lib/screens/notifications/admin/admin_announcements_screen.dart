import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../context/gym_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../components/no_connection/no_connection_screen.dart';
import '../../../components/buttons/touchable_button.dart';
import '../../../components/alerts/confirm_dialog.dart';
import '../../../components/toast/app_toast.dart';
import '../../../services/auth_service.dart';
import '../../../utils/formatters.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final response =
          await AuthService.get('/admin/notifications/annoucements/');
      final data = response.data['data'];
      if (mounted) {
        setState(() => _announcements = data is List ? data : []);
      }
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _handleDelete(dynamic id) async {
    final ok = await showConfirmDialog(
      context,
      '¿Estás seguro de eliminar el anuncio?',
    );
    if (!ok) return;

    try {
      await AuthService.delete(
          '/admin/notifications/annoucements/delete/$id/');
      await _load();
    } on DioException catch (_) {
      AppToast.error('Error', 'Error de conexión');
    }
  }

  bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anuncios',
                style: TextStyle(fontSize: 22, color: t.text),
              ),
              TouchableButton(
                title: 'Nuevo Anuncio',
                onPress: () async {
                  await context.push('/admin-announcement-create');
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _announcements.isEmpty
                ? Center(
                    child: Text(
                      'Sin anuncios...',
                      style: TextStyle(fontSize: 22, color: t.text),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 30),
                    itemCount: _announcements.length,
                    itemBuilder: (context, i) {
                      final annc = _announcements[i];
                      return _AnnouncementCard(
                        annc: annc,
                        isDarkMode: isDarkMode,
                        onDelete: () => _handleDelete(annc['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> annc;
  final bool isDarkMode;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.annc,
    required this.isDarkMode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: t.secondBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(color: t.text, width: 0.5),
          bottom: BorderSide(color: t.text, width: 0.5),
          left: BorderSide(color: t.text, width: 3),
          right: BorderSide(color: t.text, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            annc['title']?.toString() ?? '',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: t.text),
          ),
          const SizedBox(height: 4),
          Text(
            annc['description']?.toString() ?? '',
            style: TextStyle(fontSize: 16, color: t.secondText),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expira el: ${formatDate(annc['expiration_date']?.toString())}',
                style: TextStyle(fontSize: 14, color: t.text),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete, size: 24, color: t.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
