class Facility {
  final String id;
  final String name;
  final String type; // 'hospital', 'health-center', 'clinic', 'pharmacy'
  final String phone;
  final String village;
  final String? directions; // free-text: "past the market, blue gate"
  final String? services; // free-text: "maternity, lab, X-ray"
  final DateTime createdAt;

  Facility({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.village,
    this.directions,
    this.services,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'phone': phone,
        'village': village,
        'directions': directions,
        'services': services,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        phone: json['phone'] as String? ?? '',
        village: json['village'] as String? ?? '',
        directions: json['directions'] as String?,
        services: json['services'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
