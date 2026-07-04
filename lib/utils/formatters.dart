import '../constants/users.dart';
import '../constants/payments.dart';
import '../constants/training_plans.dart';

// Equivalente a client/src/utils/formatters.js

/// Formatea una fecha ISO a dd/MM/yyyy en español (Argentina)
String formatDate(String? isoString, {String fallback = 'Sin fecha'}) {
  if (isoString == null || isoString.isEmpty) return fallback;
  try {
    final date = DateTime.parse(isoString);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  } catch (_) {
    return fallback;
  }
}

/// Traduce el rol del usuario al español
String formatRole(String role) {
  if (role == adminRole) return 'Administrador';
  if (role == coachRole) return 'Entrenador';
  return 'Cliente';
}

/// Traduce el estado del usuario al español
String formatUserStatus(String status, {String inactiveLabel = 'Inactivo'}) {
  if (status == statusDeleted) return inactiveLabel;
  return 'Activo';
}

/// Traduce el estado del plan de entrenamiento al español
String formatPlanStatus(String status) {
  if (status == planStatusActive) return 'Activo';
  if (status == planStatusFinish) return 'Finalizado';
  if (status == planStatusCanceled) return 'Cancelado';
  return status;
}

/// Traduce el estado del pago al español
String formatPaymentStatus(String status) {
  const map = {
    payStatusPending: 'Pendiente',
    payStatusCompleted: 'Pagada',
    payStatusCanceled: 'Cancelada',
    payStatusProcessing: 'Procesando',
  };
  return map[status] ?? 'Error';
}

/// Traduce el tipo de ejercicio al español
String formatExerciseType(String type) {
  const map = {
    exerciseArms: 'Brazos',
    exerciseBack: 'Espalda',
    exerciseLegs: 'Piernas',
    exerciseChest: 'Pecho',
    exerciseAbs: 'Abdominales',
  };
  return map[type] ?? 'Grupo desconocido';
}

/// Calcula el monto final de un pago (total + penalidades - descuentos)
String getFinalAmount(Map<String, dynamic> payment) {
  final total = double.tryParse(payment['total_amount']?.toString() ?? '') ?? 0.0;
  final penalties = double.tryParse(payment['penalties_sum']?.toString() ?? '') ?? 0.0;
  final discounts = double.tryParse(payment['discounts_sum']?.toString() ?? '') ?? 0.0;
  return (total + penalties - discounts).toStringAsFixed(2);
}

/// Devuelve el nombre del mes a partir de una fecha ISO
String getMonth(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return monthsMap[date.month] ?? '';
  } catch (_) {
    return '';
  }
}
