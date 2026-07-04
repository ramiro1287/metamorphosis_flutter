class User {
  final String idNumber;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final bool termsAccepted;
  final bool isRetired;
  final String? phone;
  final String? birthDate;
  final Map<String, dynamic>? plan;
  final Map<String, dynamic>? family;
  /// Devuelto por AddressSerializer: {id, state (nombre legible), city, address}
  final Map<String, dynamic>? address;

  const User({
    required this.idNumber,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    required this.termsAccepted,
    required this.isRetired,
    this.phone,
    this.birthDate,
    this.plan,
    this.family,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idNumber: json['id_number']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      isRetired: json['is_retired'] as bool? ?? false,
      phone: json['phone']?.toString(),
      birthDate: json['birth_date']?.toString(),
      plan: json['plan'] as Map<String, dynamic>?,
      family: json['family'] as Map<String, dynamic>?,
      address: json['address'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_number': idNumber,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'status': status,
        'terms_accepted': termsAccepted,
        'is_retired': isRetired,
        'phone': phone,
        'birth_date': birthDate,
        'plan': plan,
        'family': family,
        'address': address,
      };

  String get fullName => '$firstName $lastName';
}
