import 'package:client/src/models/education_model.dart';
import 'package:client/src/models/experience_model.dart';

class PersonalInformation {
  final String fullName;
  final String age;
  final String phone;
  final String email;
  final String address;
  final List<String> skills;
  final List<Education> education;
  final List<Experience> experience;

  PersonalInformation({
    required this.fullName,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    required this.skills,
    required this.education,
    required this.experience,
  });

  PersonalInformation copyWith({
    String? fullName,
    String? age,
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
}
