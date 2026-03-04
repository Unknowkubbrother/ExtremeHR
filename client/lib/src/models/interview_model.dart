import 'package:client/src/models/status_enum.dart';

class InverViewCardModel {
  final String id;
  final Status state;
  final String title;
  final String company;

  InverViewCardModel({
    required this.id,
    required this.state,
    required this.title,
    required this.company,
  });

  factory InverViewCardModel.fromJson(Map<String, dynamic> json) {
    Status parsedState = Status.waiting;
    String statusStr = (json['status'] ?? '').toString().toLowerCase();
    switch (statusStr) {
      case 'waiting':
        parsedState = Status.waiting;
        break;
      case 'interview':
        parsedState = Status.interview;
        break;
      case 'rejected':
        parsedState = Status.reject;
        break;
      case 'viewed':
        parsedState = Status.view;
        break;
      case 'accepted':
        parsedState = Status.accepted;
        break;
      default:
        parsedState = Status.waiting;
    }

    return InverViewCardModel(
      id: json['id'].toString(),
      state: parsedState,
      title: json['jobtitle'] ?? '',
      company: json['companyname'] ?? '',
    );
  }

  InverViewCardModel copyWith({
    String? id,
    Status? state,
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

class ApplyJobModel {
  final bool isSuccess;

  ApplyJobModel({required this.isSuccess});

  factory ApplyJobModel.fromJson(Map<String, dynamic> json) {
    return ApplyJobModel(isSuccess: json['isSuccess']);
  }
}
