import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'context/gym_provider.dart';
import 'components/toast/app_toast.dart';
import 'constants/app_theme.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear el provider antes del árbol de widgets para pasarlo al router
  final gymProvider = GymProvider();

  // Crear el router con referencia directa al provider (para refreshListenable y redirect)
  final appRouter = createAppRouter(gymProvider);

  runApp(
    ChangeNotifierProvider.value(
      value: gymProvider,
      child: _GymApp(router: appRouter, gymProvider: gymProvider),
    ),
  );
}

class _GymApp extends StatefulWidget {
  final GoRouter router;
  final GymProvider gymProvider;

  const _GymApp({required this.router, required this.gymProvider});

  @override
  State<_GymApp> createState() => _GymAppState();
}

class _GymAppState extends State<_GymApp> {
  @override
  void initState() {
    super.initState();
    // Sincronizar el tema del toast cuando el provider cambie
    widget.gymProvider.addListener(_syncToastTheme);
  }

  @override
  void dispose() {
    widget.gymProvider.removeListener(_syncToastTheme);
    super.dispose();
  }

  void _syncToastTheme() {
    AppToast.updateTheme(widget.gymProvider.isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;

    // Actualiza el color de la status bar según el tema
    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp.router(
      title: 'Metamorphosis Gym',
      debugShowCheckedModeBanner: false,
      // Clave global para el ScaffoldMessenger (toasts globales)
      scaffoldMessengerKey: AppToast.messengerKey,
      // Temas claro y oscuro
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Configuración del router
      routerConfig: widget.router,
    );
  }
}


