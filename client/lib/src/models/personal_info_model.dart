class PersonalInformation {
  final String fullName;
  final String age;
  final String phone;
  final String email;
  final String address;
  final List<String> skills;

  PersonalInformation({
    required this.fullName,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    required this.skills,
  });

  PersonalInformation copyWith({
    String? fullName,
    String? age,
    String? phone,
    String? email,
    String? address,
    List<String>? skills,
  }) {
    return PersonalInformation(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      skills: skills ?? this.skills,
    );
  }
}
