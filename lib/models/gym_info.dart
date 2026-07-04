class GymInfo {
  final List<dynamic> plans;
  /// Map<String, String>: {'AR-X': 'Córdoba', 'AR-B': 'Buenos Aires', ...}
  final Map<String, dynamic> states;
  /// Map<String, String>: {'ARMS': 'Brazos', 'LEGS': 'Piernas', ...}
  final Map<String, dynamic> exerciseTypes;
  final List<dynamic> discounts;
  final List<dynamic> paymentMethods;
  final bool mercadopagoCheckoutEnabled;
  /// Map<String, String>: {'AR': 'Argentina', 'UY': 'Uruguay', ...}
  final Map<String, dynamic> countries;

  const GymInfo({
    required this.plans,
    required this.states,
    required this.exerciseTypes,
    required this.discounts,
    required this.paymentMethods,
    this.mercadopagoCheckoutEnabled = false,
    this.countries = const {},
  });

  factory GymInfo.fromJson(Map<String, dynamic> json) {
    return GymInfo(
      plans: (json['plans'] as List<dynamic>?) ?? [],
      states: (json['states'] as Map<String, dynamic>?) ?? {},
      exerciseTypes: (json['exercise_types'] as Map<String, dynamic>?) ?? {},
      discounts: (json['discounts'] as List<dynamic>?) ?? [],
      paymentMethods: (json['payment_methods'] as List<dynamic>?) ?? [],
      mercadopagoCheckoutEnabled:
          json['mercadopago_checkout_enabled'] as bool? ?? false,
      countries: (json['countries'] as Map<String, dynamic>?) ?? {},
    );
  }
}
