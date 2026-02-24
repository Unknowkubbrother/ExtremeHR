class UserRegister {
  final String username;
  final String email;
  final String password;

  UserRegister({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email, 'password': password};
  }
}

class UserRegisterResponse {
  final String id;
  final String username;
  final String email;

  UserRegisterResponse({
    required this.id,
    required this.username,
    required this.email,
  });

  factory UserRegisterResponse.fromJson(Map<String, dynamic> json) {
    return UserRegisterResponse(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }
}

class UserLogin {
  final String username;
  final String password;

  UserLogin({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

class UserLoginResponse {
  final String token;
  final String token_type;

  UserLoginResponse({required this.token, required this.token_type});

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      token: json['access_token'],
      token_type: json['token_type'],
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;

  UserModel({required this.id, required this.username, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'email': email};
  }
}
