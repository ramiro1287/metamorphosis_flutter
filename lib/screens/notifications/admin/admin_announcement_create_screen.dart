import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../context/gym_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../components/containers/scroll_container.dart';
import '../../../components/buttons/touchable_button.dart';
import '../../../components/alerts/confirm_dialog.dart';
import '../../../components/picker/date_picker_modal.dart';
import '../../../components/toast/app_toast.dart';
import '../../../services/auth_service.dart';

class AdminAnnouncementCreateScreen extends StatefulWidget {
  const AdminAnnouncementCreateScreen({super.key});

  @override
  State<AdminAnnouncementCreateScreen> createState() =>
      _AdminAnnouncementCreateScreenState();
}

class _AdminAnnouncementCreateScreenState
    extends State<AdminAnnouncementCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _expirationDate;

  String _titleError = '';
  String _descError = '';
  String _dateError = '';
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _titleError = '';
      _descError = '';
      _dateError = '';
    });
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Ingresar un título');
      ok = false;
    }
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _descError = 'Ingresar una descripción');
      ok = false;
    }
    if (_expirationDate == null) {
      setState(() => _dateError = 'Ingresar una fecha de expiración');
      ok = false;
    }
    return ok;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    final ok = await showConfirmDialog(
      context,
      '¿Estás seguro de crear el anuncio?',
    );
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final expDate = _expirationDate!;
      final dateStr =
          '${expDate.year.toString().padLeft(4, '0')}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}';

      await AuthService.post(
        '/admin/notifications/annoucements/',
        data: {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'expiration_date': dateStr,
        },
      );

      if (mounted) {
        context.read<GymProvider>().getHasUnreadNotifications();
        AppToast.success('Anuncio creado', '');
        context.pop();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail =
            e.response?.data?['data']?['error_detail']?.toString() ?? '';
        AppToast.error('', detail);
        setState(() {
          _titleCtrl.clear();
          _descCtrl.clear();
          _expirationDate = null;
        });
      } else {
        AppToast.error('Error', 'Código ${e.response?.statusCode}');
      }
    } catch (_) {
      AppToast.error('Error', 'Error de conexión');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _expirationDate ?? tomorrow,
      firstDate: tomorrow,
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
        _dateError = '';
      });
    }
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<GymProvider>().isDarkMode;
    final t = getThemeColors(isDarkMode);

    return ScrollContainer(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Nuevo Anuncio',
          style: TextStyle(fontSize: 22, color: t.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),

        // Título
        _SectionLabel('Título', t),
        _StyledInput(
          controller: _titleCtrl,
          placeholder: 'Escribe el título...',
          hasError: _titleError.isNotEmpty,
          t: t,
          onChanged: (_) => setState(() => _titleError = ''),
        ),
        if (_titleError.isNotEmpty) _ErrorText(_titleError, t),

        // Descripción
        _SectionLabel('Descripción', t),
        _StyledInput(
          controller: _descCtrl,
          placeholder: 'Escribe la descripción...',
          hasError: _descError.isNotEmpty,
          t: t,
          onChanged: (_) => setState(() => _descError = ''),
          maxLines: 3,
        ),
        if (_descError.isNotEmpty) _ErrorText(_descError, t),

        // Fecha de expiración
        _SectionLabel('Fecha de expiración', t),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatDateDisplay(_expirationDate),
                style: TextStyle(
                  fontSize: 18,
                  color: _expirationDate == null ? t.secondText : t.text,
                ),
              ),
            ),
            GestureDetector(
              onTap: _pickDate,
              child: Icon(Icons.calendar_today, size: 24, color: t.icon),
            ),
          ],
        ),
        Divider(color: _dateError.isNotEmpty ? t.inputError : t.text, height: 12),
        if (_dateError.isNotEmpty) _ErrorText(_dateError, t),

        const SizedBox(height: 25),
        TouchableButton(
          title: 'Crear Anuncio',
          onPress: _handleSubmit,
          loading: _loading,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _SectionLabel(this.text, this.t);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
      );
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool hasError;
  final AppThemeColors t;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const _StyledInput({
    required this.controller,
    required this.placeholder,
    required this.hasError,
    required this.t,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 18, color: t.text),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: t.text.withAlpha(153)),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: hasError ? t.inputError : t.text),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: hasError ? t.inputError : t.text, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  final AppThemeColors t;
  const _ErrorText(this.text, this.t);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(color: t.inputError, fontSize: 16)),
      );
}
