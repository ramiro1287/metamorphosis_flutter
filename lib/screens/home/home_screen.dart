import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../context/gym_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../constants/users.dart';
import '../../constants/payments.dart';
import '../../components/loading/loading_screen.dart';
import '../../components/no_connection/no_connection_screen.dart';
import '../../components/containers/scroll_container.dart';
import '../../components/buttons/touchable_button.dart';
import '../../components/toast/app_toast.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _trainingPlans = [];
  List<dynamic> _payments = [];
  bool _loading = true;
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _connectionError = false;
      _loading = true;
    });
    final user = context.read<GymProvider>().user;
    await Future.wait([
      _loadTrainingPlan(),
      if (user?.role == traineeRole) _loadPayments(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadTrainingPlan() async {
    try {
      final response = await AuthService.get('/training-plans/list/');
      final results = response.data['data']['results'] as List<dynamic>? ?? [];
      if (mounted) setState(() => _trainingPlans = results);
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  Future<void> _loadPayments() async {
    try {
      final response = await AuthService.get('/payments/list/');
      final results = response.data['data']['results'] as List<dynamic>? ?? [];
      if (mounted) setState(() => _payments = results);
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        if (mounted) setState(() => _connectionError = true);
      } else {
        AppToast.error('Error', 'Error de conexión');
      }
    }
  }

  bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  @override
  Widget build(BuildContext context) {
    if (_connectionError) {
      return NoConnectionScreen(onRetry: _load);
    }
    if (_loading) {
      return const LoadingScreen();
    }

    final gymProvider = context.watch<GymProvider>();
    final user = gymProvider.user!;
    final gymInfo = gymProvider.gymInfo;
    final isDarkMode = gymProvider.isDarkMode;
    final t = getThemeColors(isDarkMode);

    return ScrollContainer(
      padding: const EdgeInsets.all(25),
      children: [
        // ---- Saludo ----
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '¡Hola ${user.firstName.isNotEmpty ? user.firstName : "usuario"}!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
        ),
        const SizedBox(height: 15),

        // ---- Última cuota (solo Trainee) ----
        if (user.role == traineeRole)
          _Card(
            title: 'Última cuota',
            isDarkMode: isDarkMode,
            children: _payments.isNotEmpty
                ? [
                    _InfoRow(
                      label: 'Precio',
                      value: '\$${getFinalAmount(_payments[0])}',
                      valueStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                      ),
                    ),
                    _InfoRow(
                      label: 'Estado',
                      value: formatPaymentStatus(_payments[0]['status'] ?? ''),
                      valueStyle: TextStyle(
                        fontSize: 18,
                        color: _payments[0]['status'] != payStatusCompleted
                            ? inputErrorDark
                            : buttonTextConfirmDark,
                      ),
                    ),
                    _InfoRow(
                      label: 'Mes',
                      value:
                          '${getMonth(_payments[0]['created_at'] ?? '')} ${DateTime.tryParse(_payments[0]['created_at'] ?? '')?.year ?? ''}',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TouchableButton(
                        title: 'Ver cuotas',
                        icon: Icon(Icons.credit_card, size: 22, color: t.buttonText),
                        onPress: () => context.push('/trainee-payments'),
                      ),
                    ),
                  ]
                : [Text('Sin cuotas disponibles', style: TextStyle(fontSize: 16, color: t.text))],
          ),

        if (user.role == traineeRole) const SizedBox(height: 15),

        // ---- Plan de entrenamiento ----
        _Card(
          title: 'Plan de entrenamiento',
          isDarkMode: isDarkMode,
          children: _trainingPlans.isNotEmpty
              ? [
                  _InfoRow(label: 'Entrenador', value: _trainingPlans[0]['coach']?.toString() ?? '-'),
                  _InfoRow(
                    label: 'Vence',
                    value: formatDate(_trainingPlans[0]['expiration_date']?.toString(), fallback: 'Sin vencimiento'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TouchableButton(
                      title: 'Ver plan',
                      icon: Icon(Icons.assignment, size: 22, color: t.buttonText),
                        onPress: () => context.push('/trainee-plans'),
                    ),
                  ),
                ]
              : [Text('Sin plan asignado', style: TextStyle(fontSize: 16, color: t.text))],
        ),
        const SizedBox(height: 15),

        // ---- Planes y Precios ----
        _Card(
          title: 'Planes y Precios',
          isDarkMode: isDarkMode,
          children: (gymInfo?.plans.isNotEmpty ?? false)
              ? gymInfo!.plans
                  .map<Widget>((plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InfoRow(
                          label: plan['name']?.toString() ?? '',
                          value: '\$${plan['price']}',
                        ),
                      ))
                  .toList()
              : [Text('No hay planes disponibles', style: TextStyle(fontSize: 16, color: t.text))],
        ),
        const SizedBox(height: 15),

        // ---- Grid de administración (Coach / Admin) ----
        if (user.role != traineeRole)
          _AdminGrid(user: user, isDarkMode: isDarkMode),
      ],
    );
  }
}

// -------------------------------------------------------
// Widgets internos reutilizables en Home
// -------------------------------------------------------

/// Tarjeta con título y contenido (equivale a las cards de Home.jsx)
class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDarkMode;

  const _Card({
    required this.title,
    required this.children,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.secondBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Fila de info label + value (equivale a common.infoRow + common.label + common.value)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t.secondText, fontSize: 18)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? TextStyle(color: t.text, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid de administración
class _AdminGrid extends StatelessWidget {
  final dynamic user;
  final bool isDarkMode;

  const _AdminGrid({required this.user, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final t = getThemeColors(isDarkMode);

    final items = [
      _GridItem(title: 'Usuarios', icon: Icons.people, route: '/admin-users', show: true),
      _GridItem(title: 'Familias', icon: Icons.home, route: '/admin-families', show: user.role == adminRole),
      _GridItem(title: 'Ejercicios', icon: Icons.fitness_center, route: '/admin-exercises', show: user.role == adminRole),
      _GridItem(title: 'Planes Mensuales', icon: Icons.calendar_today, route: '/admin-user-plans', show: user.role == adminRole),
      _GridItem(title: 'Estadísticas', icon: Icons.bar_chart, route: '/admin-statistics', show: user.role == adminRole),
      _GridItem(title: 'Planes Entrenamiento', icon: Icons.assignment, route: '/admin-training-plans', show: user.role == adminRole),
      _GridItem(title: 'Anuncios', icon: Icons.campaign, route: '/admin-announcements', show: user.role == adminRole),
    ].where((item) => item.show).toList();

    return _Card(
      title: 'Administración',
      isDarkMode: isDarkMode,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          children: items
              .map((item) => _AdminGridButton(item: item, t: t))
              .toList(),
        ),
      ],
    );
  }
}

class _GridItem {
  final String title;
  final IconData icon;
  final String route;
  final bool show;
  const _GridItem({required this.title, required this.icon, required this.route, required this.show});
}

class _AdminGridButton extends StatelessWidget {
  final _GridItem item;
  final AppThemeColors t;

  const _AdminGridButton({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // push: back vuelve a Home (equiv. navigation.reset [Home, route])
      onTap: () => context.push(item.route),
      child: Container(
        width: (MediaQuery.of(context).size.width - 50 - 50 - 12) / 2,
        decoration: BoxDecoration(
          color: t.buttonBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 28, color: t.buttonText),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.buttonText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
