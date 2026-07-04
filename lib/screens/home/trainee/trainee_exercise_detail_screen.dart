import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../context/gym_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../components/containers/scroll_container.dart';
import '../../../components/buttons/touchable_button.dart';
import '../../../utils/formatters.dart';

class TraineeExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const TraineeExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<TraineeExerciseDetailScreen> createState() =>
      _TraineeExerciseDetailScreenState();
}

class _TraineeExerciseDetailScreenState
    extends State<TraineeExerciseDetailScreen> {
  bool _isViewerVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    final ex = widget.exercise;
    final exercise = ex['exercise'] as Map<String, dynamic>? ?? {};
    final name = exercise['name']?.toString() ?? '';
    final type = exercise['type']?.toString() ?? '';
    final exerciseDesc = exercise['description']?.toString();
    final trainerNotes = ex['description']?.toString();
    final illustration = exercise['illustration']?.toString();

    List<Widget> buildParagraphs(String text, TextStyle style) {
      return text.split('\n').map((p) {
        return Text(p.isEmpty ? ' ' : p, style: style);
      }).toList();
    }

    return PopScope(
      // Cuando el visor está abierto, intercepta el back para cerrarlo en vez de navegar
      canPop: !_isViewerVisible,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isViewerVisible) {
          setState(() => _isViewerVisible = false);
        }
      },
      child: Stack(
        children: [
          // ---- Contenido principal ----
          ScrollContainer(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
            children: [
              Text(
                name,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: t.text),
              ),
              const SizedBox(height: 20),
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
                    _Detail(
                      label: 'Grupo muscular',
                      value: formatExerciseType(type),
                      t: t,
                    ),
                    _Detail(
                        label: 'Series',
                        value: ex['sets']?.toString() ?? 'N/A',
                        t: t),
                    _Detail(
                        label: 'Repeticiones',
                        value: ex['reps']?.toString() ?? 'N/A',
                        t: t),
                    _Detail(
                        label: 'Descanso',
                        value: ex['rest']?.toString() ?? 'N/A',
                        t: t),
                  ],
                ),
              ),
              const SizedBox(height: 15),
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
                    Text('Descripción:',
                        style: TextStyle(
                            fontSize: 18,
                            color: t.secondText,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (exerciseDesc != null && exerciseDesc.isNotEmpty)
                      ...buildParagraphs(exerciseDesc,
                          TextStyle(fontSize: 16, color: t.text))
                    else
                      Text('Sin descripción',
                          style: TextStyle(fontSize: 16, color: t.text)),
                    if (trainerNotes != null && trainerNotes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Anotaciones del entrenador:',
                          style: TextStyle(
                              fontSize: 18,
                              color: t.secondText,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...buildParagraphs(trainerNotes,
                          TextStyle(fontSize: 16, color: t.text)),
                    ],
                  ],
                ),
              ),
              if (illustration != null && illustration.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TouchableButton(
                    title: 'Mostrar Ejercicio',
                    onPress: () =>
                        setState(() => _isViewerVisible = true),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TouchableButton(
                  title: 'Volver',
                  onPress: () => context.pop(),
                ),
              ),
            ],
          ),

          // ---- Overlay del visor de imagen (sin Navigator) ----
          if (_isViewerVisible && illustration != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          illustration,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white)),
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white, size: 60),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _isViewerVisible = false),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors t;

  const _Detail({required this.label, required this.value, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                  fontSize: 16,
                  color: t.secondText,
                  fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(fontSize: 16, color: t.text),
            ),
          ],
        ),
      ),
    );
  }
}
