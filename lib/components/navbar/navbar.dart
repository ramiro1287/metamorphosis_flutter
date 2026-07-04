import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../context/gym_provider.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  // Altura total: MediaQuery safe area + 56px (igual que en RN: insets.top + 56)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final gymProvider = context.watch<GymProvider>();
    final isDarkMode = gymProvider.isDarkMode;
    final hasUnread = gymProvider.hasUnreadNotifications;
    final t = getThemeColors(isDarkMode);

    return AppBar(
      backgroundColor: t.navbar,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: GestureDetector(
        // Limpia el stack y va a Home (equivalente a navigation.reset en RN)
        onTap: () => context.go('/home'),
        child: Text(
          'Metamorphosis Gym',
          style: TextStyle(
            color: t.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        // Ícono de notificaciones con badge
        // go('/home') limpia el stack, push agrega Notifications encima
        // → back vuelve a Home (equiv. navigation.reset [Home, Notifications] de RN)
        GestureDetector(
          onTap: () {
            context.go('/home');
            context.push('/notifications');
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.notifications,
                  size: 35,
                  color: isDarkMode ? iconDark : iconLight,
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: 8,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Ícono de perfil
        // Mismo patrón: [/home, /profile] → back vuelve a Home
        GestureDetector(
          onTap: () {
            context.go('/home');
            context.push('/profile');
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 15),
            child: Icon(
              Icons.account_circle,
              size: 35,
              color: isDarkMode ? iconDark : iconLight,
            ),
          ),
        ),
      ],
    );
  }
}
