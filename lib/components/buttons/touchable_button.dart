import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../context/gym_provider.dart';

// Equivalente a client/src/components/Buttons/TouchableButton.jsx

enum ButtonVariant { defaultBtn, error }

class TouchableButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final Widget? icon;
  final ButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final bool loading;
  final bool disabled;
  final TextStyle? textStyle;

  const TouchableButton({
    super.key,
    required this.title,
    required this.onPress,
    this.icon,
    this.variant = ButtonVariant.defaultBtn,
    this.padding,
    this.loading = false,
    this.disabled = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;

    final bgColor = variant == ButtonVariant.error
        ? (isDarkMode ? errorButtonTextDark : errorButtonTextLight)
        : (isDarkMode ? buttonBackgroundDark : buttonBackgroundLight);

    final fgColor = isDarkMode ? defaultButtonTextDark : defaultButtonTextLight;

    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black.withValues(alpha: 0.15),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (loading || disabled) ? null : onPress,
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle ??
                              TextStyle(
                                color: fgColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
