import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../context/gym_provider.dart';

// Equivalente a client/src/components/Picker/PickerSelect.jsx
// Dropdown personalizado: trigger abre un ModalBottomSheet directamente desde onTap.

class PickerItem {
  final String label;
  final dynamic value;
  final dynamic key;

  const PickerItem({
    required this.label,
    required this.value,
    this.key,
  });
}

class PickerSelect extends StatelessWidget {
  final dynamic value;
  final ValueChanged<dynamic> onValueChange;
  final List<PickerItem> items;
  final String? placeholder;

  const PickerSelect({
    super.key,
    required this.value,
    required this.onValueChange,
    required this.items,
    this.placeholder,
  });

  Future<void> _show(BuildContext context) async {
    final isDarkMode = context.read<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.secondBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              final isSelected = item.value == value;
              return ListTile(
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 17,
                    color: isSelected ? t.buttonTextConfirm : t.text,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, size: 20, color: t.buttonTextConfirm)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onValueChange(item.value);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    final selected = items.where((item) => item.value == value).firstOrNull;
    final displayLabel = selected?.label ?? placeholder ?? 'Seleccionar...';
    final isPlaceholder = selected == null;

    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.secondText),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  color: isPlaceholder ? t.secondText : t.text,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 24, color: t.secondText),
          ],
        ),
      ),
    );
  }
}
