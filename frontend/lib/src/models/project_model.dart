class Project {
  final String title;
  final String? description;

  Project({required this.title, this.description});

  Project copyWith({String? title, String? description}) {
    return Project(
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description};
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'] ?? '',
      description: json['description'],
    );
  }
}
