import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../context/gym_provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../constants/training_plans.dart';
import '../../../components/no_connection/no_connection_screen.dart';
import '../../../components/containers/scroll_container.dart';
import '../../../components/toast/app_toast.dart';
import '../../../services/auth_service.dart';
import '../../../utils/formatters.dart';

class TraineePlansScreen extends StatefulWidget {
  const TraineePlansScreen({super.key});

  @override
  State<TraineePlansScreen> createState() => _TraineePlansScreenState();
}

class _TraineePlansScreenState extends State<TraineePlansScreen> {
  Map<String, dynamic>? _trainingPlan;
  int _selectedDay = 1;
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _connectionError = false);
    try {
      final response = await AuthService.get('/training-plans/list/');
      final results =
          response.data['data']['results'] as List<dynamic>? ?? [];
      if (results.isNotEmpty && mounted) {
        final isInitialLoad = _trainingPlan == null;
        final newPlan = results[0] as Map<String, dynamic>;

        setState(() {
          _trainingPlan = newPlan;
          if (isInitialLoad) {
            final exercises = newPlan['exercises'] as List<dynamic>? ?? [];
            final exercisesByDay = <int, List<dynamic>>{};
            for (final ex in exercises) {
              final day = (ex['week_day'] as num).toInt();
              exercisesByDay.putIfAbsent(day, () => []).add(ex);
            }

            if (exercisesByDay.keys.isNotEmpty) {
              final sortedDays = exercisesByDay.keys.toList()..sort();
              _selectedDay = sortedDays.first;
            } else {
              _selectedDay = 1; // Fallback to 1 if no exercises
            }
          }
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

  bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  Map<int, List<dynamic>> get _exercisesByDay {
    final exercises =
        _trainingPlan?['exercises'] as List<dynamic>? ?? [];
    final map = <int, List<dynamic>>{};
    for (final ex in exercises) {
      final day = (ex['week_day'] as num).toInt();
      map.putIfAbsent(day, () => []).add(ex);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError) return NoConnectionScreen(onRetry: _load);

    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);
    final byDay = _exercisesByDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
          child: Text(
            'Plan de ejercitación',
            style: TextStyle(fontSize: 22, color: t.text),
          ),
        ),
        Expanded(
          child: ScrollContainer(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
            children: [
              if (_trainingPlan == null)
                Text('Sin plan...',
                    style: TextStyle(fontSize: 22, color: t.text))
              else ...[
                // ---- Info del plan ----
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
                      _Label('Entrenador:', t),
                      _Value(_trainingPlan!['coach']?.toString() ?? '-', t),
                      _Label('Válido hasta:', t),
                      _Value(
                          formatDate(
                              _trainingPlan!['expiration_date']?.toString(),
                              fallback: 'Sin vencimiento'),
                          t),
                      _Label('Anotaciones Generales:', t),
                      _Value(
                          _trainingPlan!['description']?.toString() ?? '-',
                          t),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ---- Selector de días ----
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: weekDaysMap.entries.map((entry) {
                    final day = entry.key;
                    final label = entry.value;
                    final isActive = (byDay[day]?.isNotEmpty ?? false);
                    final isSelected = _selectedDay == day;

                    return GestureDetector(
                      onTap: isActive
                          ? () => setState(() => _selectedDay = day)
                          : null,
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? t.buttonBackground
                                : t.secondBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? buttonTextConfirmDark
                                  : t.buttonBorder,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              // Seleccionado: verde. No seleccionado: t.text (legible sobre secondBackground)
                              color: isSelected
                                  ? buttonTextConfirmDark
                                  : t.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ---- Ejercicios del día ----
                ...?byDay[_selectedDay]?.map((ex) {
                  final exercise =
                      ex['exercise'] as Map<String, dynamic>? ?? {};
                  final truncatedDesc = ex['description'] != null &&
                          ex['description'].toString().length > 10
                      ? '${ex['description'].toString().substring(0, 10)}...'
                      : ex['description']?.toString();

                  return GestureDetector(
                    onTap: () => context.push(
                      '/trainee-exercise-detail',
                      extra: {'exercise': ex},
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: t.secondBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: const Border(
                          left: BorderSide(
                              color: buttonTextConfirmDark, width: 3),
                        ),
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.bolt,
                                        size: 25, color: t.icon),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        exercise['name']?.toString() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: t.text),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Series: ${ex['sets'] ?? 'N/A'}',
                                  style: TextStyle(
                                      fontSize: 16, color: t.text),
                                ),
                                Text(
                                  'Repeticiones: ${ex['reps'] ?? 'N/A'}',
                                  style: TextStyle(
                                      fontSize: 16, color: t.text),
                                ),
                                Text(
                                  'Descanso: ${ex['rest'] ?? 'N/A'}',
                                  style: TextStyle(
                                      fontSize: 16, color: t.text),
                                ),
                                if (truncatedDesc != null)
                                  Text(
                                    'Anotaciones: $truncatedDesc',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: t.text,
                                        fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 24, color: t.secondText),
                        ],
                      ),
                    ),
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

class _Label extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _Label(this.text, this.t);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 16, color: t.secondText, fontWeight: FontWeight.bold));
}

class _Value extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _Value(this.text, this.t);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            Text(text, style: TextStyle(fontSize: 16, color: t.text)),
      );
}
