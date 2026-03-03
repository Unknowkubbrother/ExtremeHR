import 'package:client/src/models/education_model.dart';
import 'package:client/src/models/experience_model.dart';

class PersonalInformation {
  final String fullName;
  final int? age;
  final String? phone;
  final String? email;
  final String? address;
  final List<String> skills;
  final List<Education> education;
  final List<Experience> experience;

  PersonalInformation({
    required this.fullName,
    this.age,
    this.phone,
    this.email,
    this.address,
    required this.skills,
    required this.education,
    required this.experience,
  });

  PersonalInformation copyWith({
    String? fullName,
    int? age,
    String? phone,
    String? email,
    String? address,
    List<String>? skills,
    List<Education>? education,
    List<Experience>? experience,
  }) {
    return PersonalInformation(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'age': age,
      'phone': phone,
      'email': email,
      'address': address,
      'skills': skills.map((s) => {'name': s}).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
    };
  }

  factory PersonalInformation.fromJson(Map<String, dynamic> json) {
    return PersonalInformation(
      fullName: json['full_name'] ?? '',
      age: json['age'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      skills: (json['skills'] as List? ?? [])
          .map((s) => s['name'] as String)
          .toList(),
      education: (json['education'] as List? ?? [])
          .map((e) => Education.fromJson(e))
          .toList(),
      experience: (json['experience'] as List? ?? [])
          .map((e) => Experience.fromJson(e))
          .toList(),
    );
  }
}
