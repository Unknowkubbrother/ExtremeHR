class InverViewCardModel {
  final String id;
  final int state;
  final String title;
  final String company;

  InverViewCardModel({
    required this.id,
    required this.state,
    required this.title,
    required this.company,
  });

  InverViewCardModel copyWith({
    String? id,
    int? state,
    String? title,
    String? company,
  }) {
    return InverViewCardModel(
      id: id ?? this.id,
      company: company ?? this.company,
      title: title ?? this.title,
      state: state ?? this.state,
    );
  }
}
