import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemeColors {
  final Color text;
  final Color secondText;
  final Color background;
  final Color secondBackground;
  final Color icon;
  final Color inputError;
  final Color buttonBackground;
  final Color buttonText;
  final Color navbar;
  final Color shadow;
  final Color buttonBorder;
  final Color buttonTextConfirm;
  final Color buttonTextCancel;
  final Color errorButton;

  const AppThemeColors({
    required this.text,
    required this.secondText,
    required this.background,
    required this.secondBackground,
    required this.icon,
    required this.inputError,
    required this.buttonBackground,
    required this.buttonText,
    required this.navbar,
    required this.shadow,
    required this.buttonBorder,
    required this.buttonTextConfirm,
    required this.buttonTextCancel,
    required this.errorButton,
  });
}

AppThemeColors getThemeColors(bool isDarkMode) {
  return AppThemeColors(
    text: isDarkMode ? defaultTextDark : defaultTextLight,
    secondText: isDarkMode ? secondTextDark : secondTextLight,
    background: isDarkMode ? mainBackgroundDark : mainBackgroundLight,
    secondBackground: isDarkMode ? secondBackgroundDark : secondBackgroundLight,
    icon: isDarkMode ? iconDark : iconLight,
    inputError: isDarkMode ? inputErrorDark : inputErrorLight,
    buttonBackground: isDarkMode ? buttonBackgroundDark : buttonBackgroundLight,
    buttonText: isDarkMode ? defaultTextLight : defaultTextDark,
    navbar: isDarkMode ? navbarBackgroundDark : navbarBackgroundLight,
    shadow: isDarkMode ? shadowCardDark : shadowCardLight,
    buttonBorder: isDarkMode ? buttonBorderDark : buttonBorderLight,
    buttonTextConfirm: isDarkMode ? buttonTextConfirmDark : buttonTextConfirmLight,
    buttonTextCancel: isDarkMode ? buttonTextCancelDark : buttonTextCancelLight,
    errorButton: isDarkMode ? errorButtonTextDark : errorButtonTextLight,
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: mainBackgroundLight,
    colorScheme: const ColorScheme.light(
      primary: buttonBackgroundLight,
      surface: secondBackgroundLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navbarBackgroundLight,
      foregroundColor: defaultTextLight,
      elevation: 0,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: mainBackgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: buttonBackgroundLight,
      surface: secondBackgroundDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navbarBackgroundDark,
      foregroundColor: defaultTextDark,
      elevation: 0,
    ),
  );
}
