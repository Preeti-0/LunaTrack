class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String? location;
  final double? rating;
  final String? phone;
  final String? imageUrl;
  final String? education;
  final String? about;
  final int? experience;
  final double consultationFee; // ✅ Required!
  final List<String>? availableDays;
  final List<String>? availableTime;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    this.location,
    this.rating,
    this.phone,
    this.imageUrl,
    this.education,
    this.about,
    this.experience,
    required this.consultationFee,
    this.availableDays,
    this.availableTime,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      location: json['location'],
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      phone: json['phone'],
      imageUrl: json['image_url'], // ✅ Matches the new serializer field
      education: json['education'],
      about: json['about'],
      experience: json['experience_years'], // ✅ CORRECT FIELD NAME
      consultationFee:
          double.tryParse(json['consultation_fee'].toString()) ?? 0.0,
      availableDays:
          (json['available_days'] as List?)?.map((e) => e.toString()).toList(),
      availableTime:
          (json['available_time'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
