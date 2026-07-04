import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_theme.dart';
import '../../components/no_connection/no_connection_screen.dart';
import '../../components/toast/app_toast.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final response = await AuthService.get('/notifications/list/');
      final data = response.data['data'];
      if (mounted) setState(() => _notifications = data is List ? data : []);
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _handleDelete(dynamic id) async {
    try {
      await AuthService.delete('/notifications/delete/$id/');
      await _load();
    } on DioException catch (_) {
      AppToast.error('Error', 'Error de conexión');
    }
  }

  Future<void> _handleRead(dynamic id) async {
    try {
      await AuthService.post('/notifications/read/$id/');
      await _load();
      if (mounted) {
        context.read<GymProvider>().getHasUnreadNotifications();
      }
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
          const SizedBox(height: 20),
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Text(
                      'Sin notificaciones...',
                      style: TextStyle(fontSize: 22, color: t.text),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 30),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final notif = _notifications[i];
                      return _NotifCard(
                        notif: notif,
                        isDarkMode: isDarkMode,
                        onRead: notif['is_read'] == true
                            ? null
                            : () => _handleRead(notif['id']),
                        onDelete: () => _handleDelete(notif['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final bool isDarkMode;
  final VoidCallback? onRead;
  final VoidCallback onDelete;

  const _NotifCard({
    required this.notif,
    required this.isDarkMode,
    required this.onRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    final isUnread = notif['is_read'] != true;

    final card = Container(
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
          // Header: título + badge no leído
          Row(
            children: [
              Expanded(
                child: Text(
                  notif['title']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                  ),
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notif['description']?.toString() ?? '',
            style: TextStyle(fontSize: 16, color: t.secondText),
          ),
          const SizedBox(height: 8),
          // Footer: fecha + botón eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDate(notif['created_at']?.toString()),
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

    if (onRead != null) {
      return GestureDetector(onTap: onRead, child: card);
    }
    return card;
  }
}
