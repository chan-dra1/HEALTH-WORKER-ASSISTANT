class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender; // 'male', 'female', 'other'
  final String phone;
  final String village;
  final String facilityName;
  final DateTime createdAt;
  DateTime? syncedAt;
  final bool synced;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.village,
    required this.facilityName,
    DateTime? createdAt,
    this.syncedAt,
    this.synced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'phone': phone,
        'village': village,
        'facilityName': facilityName,
        'createdAt': createdAt.toIso8601String(),
        'syncedAt': syncedAt?.toIso8601String(),
        'synced': synced ? 1 : 0,
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
        gender: json['gender'] as String,
        phone: json['phone'] as String,
        village: json['village'] as String,
        facilityName: json['facilityName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncedAt: json['syncedAt'] != null
            ? DateTime.parse(json['syncedAt'] as String)
            : null,
        synced: (json['synced'] as int) == 1,
      );

  String get fullName => '$firstName $lastName';

  @override
  String toString() => 'Patient(name=$fullName, age=$age, id=$id)';
}
