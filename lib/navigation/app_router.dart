import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../context/gym_provider.dart';
import '../components/navbar/navbar.dart';
import '../components/loading/loading_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/terms_and_conditions_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/admin/admin_announcements_screen.dart';
import '../screens/notifications/admin/admin_announcement_create_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/change_address_screen.dart';
import '../screens/home/trainee/trainee_payments_screen.dart';
import '../screens/home/trainee/trainee_plans_screen.dart';
import '../screens/home/trainee/payment_detail_screen.dart';
import '../screens/home/trainee/trainee_exercise_detail_screen.dart';
import '../screens/home/admin/families/admin_families_screen.dart';
import '../screens/home/admin/families/admin_family_detail_screen.dart';
import '../screens/home/admin/families/admin_family_create_screen.dart';
import '../screens/home/admin/families/admin_family_add_screen.dart';
import '../screens/home/admin/payments/admin_user_payments_screen.dart';
import '../screens/home/admin/payments/admin_user_payment_detail_screen.dart';
import '../screens/home/admin/statistics/admin_statistics_screen.dart';
import '../screens/home/admin/users/admin_users_screen.dart';
import '../screens/home/admin/users/admin_create_user_screen.dart';
import '../screens/home/admin/users/admin_user_detail_screen.dart';
import '../screens/home/admin/users/admin_user_plans_screen.dart';
import '../screens/home/admin/training_plans/admin_user_training_plans_screen.dart';
import '../screens/home/admin/training_plans/admin_user_training_plan_create_screen.dart';
import '../screens/home/admin/training_plans/admin_user_training_plan_detail_screen.dart';
import '../screens/home/admin/training_plans/admin_user_training_plan_assign_screen.dart';
import '../screens/home/admin/training_plans/admin_exercises_screen.dart';
import '../screens/home/admin/training_plans/admin_training_plans_screen.dart';
import '../screens/home/admin/training_plans/admin_training_plan_create_screen.dart';
import '../screens/home/admin/training_plans/admin_training_plan_detail_screen.dart';

/// ChangeNotifier que solo notifica a go_router cuando cambia el estado de
/// autenticación (user, isAuthLoading, termsAccepted).
/// Sin esto, refreshListenable: gymProvider haría que go_router reconstruya
/// el árbol de widgets en CADA notifyListeners() — incluyendo el polling de
/// notificaciones cada 60s — causando _dependents.isEmpty cuando hay un
/// dialog abierto en el Navigator del ShellRoute.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(GymProvider gymProvider) {
    _prevUserId = gymProvider.user?.idNumber;
    _prevIsLoading = gymProvider.isAuthLoading;
    _prevTermsAccepted = gymProvider.user?.termsAccepted;
    gymProvider.addListener(() {
      final newUserId = gymProvider.user?.idNumber;
      final newLoading = gymProvider.isAuthLoading;
      final newTerms = gymProvider.user?.termsAccepted;
      if (newUserId != _prevUserId ||
          newLoading != _prevIsLoading ||
          newTerms != _prevTermsAccepted) {
        _prevUserId = newUserId;
        _prevIsLoading = newLoading;
        _prevTermsAccepted = newTerms;
        notifyListeners();
      }
    });
  }
  String? _prevUserId;
  bool _prevIsLoading = false;
  bool? _prevTermsAccepted;
}

GoRouter createAppRouter(GymProvider gymProvider) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _AuthStateNotifier(gymProvider),
    redirect: (context, state) {
      final isLoading = gymProvider.isAuthLoading;
      final user = gymProvider.user;
      final loc = state.matchedLocation;

      // Mientras se verifica el token, mostrar pantalla de carga
      if (isLoading) {
        return loc == '/loading' ? null : '/loading';
      }

      // Sin usuario → Login
      if (user == null) {
        return (loc == '/login') ? null : '/login';
      }

      // Usuario sin términos aceptados → Terms
      if (!user.termsAccepted) {
        return (loc == '/terms') ? null : '/terms';
      }

      // Usuario autenticado intentando entrar a rutas de auth → Home
      if (loc == '/login' || loc == '/loading' || loc == '/terms') {
        return '/home';
      }

      return null; // Sin redirección
    },
    routes: [
      // -------------------------------------------------------
      // Rutas fuera del shell (sin Navbar)
      // -------------------------------------------------------
      GoRoute(
        path: '/loading',
        builder: (_, __) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsAndConditionsScreen(),
      ),

      // -------------------------------------------------------
      // Shell con Navbar (todas las pantallas autenticadas)
      // -------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          // NO usamos context.watch<GymProvider>() aquí.
          // El color de fondo viene de scaffoldBackgroundColor en buildLightTheme/buildDarkTheme.
          // Si lo leyéramos aquí, el Scaffold se re-crearía con cada notifyListeners()
          // (incluyendo el polling de notificaciones), lo que causa _dependents.isEmpty
          // cuando hay un dialog abierto en el Navigator del ShellRoute.
          return Scaffold(
            appBar: const Navbar(),
            body: child,
          );
        },
        routes: [
          // ---- Home ----
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),

          // ---- Trainee ----
          GoRoute(
            path: '/trainee-payments',
            builder: (_, __) => const TraineePaymentsScreen(),
          ),
          GoRoute(
            path: '/trainee-plans',
            builder: (_, __) => const TraineePlansScreen(),
          ),
          GoRoute(
            // extra: {'exercise': Map<String, dynamic>}
            path: '/trainee-exercise-detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return TraineeExerciseDetailScreen(
                exercise: extra['exercise'] as Map<String, dynamic>? ?? {},
              );
            },
          ),
          GoRoute(
            // extra: {'paymentId': dynamic}
            path: '/payment-detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return PaymentDetailScreen(paymentId: extra['paymentId']);
            },
          ),

          // ---- Admin / Users ----
          GoRoute(
            path: '/admin-users',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            // extra: {'idNumber': string}
            path: '/admin-user-detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserDetailScreen(
                  idNumber: extra['idNumber']?.toString() ?? '');
            },
          ),
          GoRoute(
            path: '/admin-create-user',
            builder: (_, __) => const AdminCreateUserScreen(),
          ),
          GoRoute(
            path: '/admin-user-plans',
            builder: (_, __) => const AdminUserPlansScreen(),
          ),

          // ---- Admin / Families ----
          GoRoute(
            path: '/admin-families',
            builder: (_, __) => const AdminFamiliesScreen(),
          ),
          GoRoute(
            // extra: {'familyId': dynamic}
            path: '/admin-family-detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AdminFamilyDetailScreen(familyId: extra['familyId']);
            },
          ),
          GoRoute(
            // extra: {'familyId': dynamic}
            path: '/admin-family-add',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AdminFamilyAddScreen(familyId: extra['familyId']);
            },
          ),
          GoRoute(
            path: '/admin-family-create',
            builder: (_, __) => const AdminFamilyCreateScreen(),
          ),

          // ---- Admin / Payments ----
          GoRoute(
            // extra: {'idNumber': string, 'fullName': string}
            path: '/admin-user-payments',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserPaymentsScreen(
                idNumber: extra['idNumber']?.toString() ?? '',
                fullName: extra['fullName']?.toString() ?? '',
              );
            },
          ),
          GoRoute(
            // extra: {'paymentId': dynamic, 'fullName': string}
            path: '/admin-user-payment-detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserPaymentDetailScreen(
                paymentId: extra['paymentId'],
                fullName: extra['fullName']?.toString() ?? '',
              );
            },
          ),

          // ---- Admin / TrainingPlans ----
          GoRoute(
            // extra: {'idNumber': string, 'fullName': string}
            path: '/admin-user-training-plans',
            builder: (context, state) {
              final e = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserTrainingPlansScreen(
                  idNumber: e['idNumber']?.toString() ?? '',
                  fullName: e['fullName']?.toString() ?? '');
            },
          ),
          GoRoute(
            // extra: {'idNumber': string, 'fullName': string}
            path: '/admin-user-training-plan-create',
            builder: (context, state) {
              final e = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserTrainingPlanCreateScreen(
                  idNumber: e['idNumber']?.toString() ?? '',
                  fullName: e['fullName']?.toString() ?? '');
            },
          ),
          GoRoute(
            // extra: {'idNumber': string, 'planId': dynamic, 'fullName': string}
            path: '/admin-user-training-plan-detail',
            builder: (context, state) {
              final e = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserTrainingPlanDetailScreen(
                  idNumber: e['idNumber']?.toString() ?? '',
                  planId: e['planId'],
                  fullName: e['fullName']?.toString() ?? '');
            },
          ),
          GoRoute(
            // extra: {'idNumber': string, 'fullName': string}
            path: '/admin-user-training-plan-assign',
            builder: (context, state) {
              final e = state.extra as Map<String, dynamic>? ?? {};
              return AdminUserTrainingPlanAssignScreen(
                  idNumber: e['idNumber']?.toString() ?? '',
                  fullName: e['fullName']?.toString() ?? '');
            },
          ),
          GoRoute(
            path: '/admin-exercises',
            builder: (_, __) => const AdminExercisesScreen(),
          ),
          GoRoute(
            path: '/admin-training-plans',
            builder: (_, __) => const AdminTrainingPlansScreen(),
          ),
          GoRoute(
            path: '/admin-training-plan-create',
            builder: (_, __) => const AdminTrainingPlanCreateScreen(),
          ),
          GoRoute(
            // extra: {'templateId': dynamic}
            path: '/admin-training-plan-detail',
            builder: (context, state) {
              final e = state.extra as Map<String, dynamic>? ?? {};
              return AdminTrainingPlanDetailScreen(templateId: e['templateId']);
            },
          ),

          // ---- Admin / Statistics ----
          GoRoute(
            path: '/admin-statistics',
            builder: (_, __) => const AdminStatisticsScreen(),
          ),

          // ---- Profile ----
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/change-address',
            builder: (_, __) => const ChangeAddressScreen(),
          ),

          // ---- Notifications ----
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/admin-announcements',
            builder: (_, __) => const AdminAnnouncementsScreen(),
          ),
          GoRoute(
            path: '/admin-announcement-create',
            builder: (_, __) => const AdminAnnouncementCreateScreen(),
          ),
        ],
      ),
    ],
  );
}
