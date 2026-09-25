class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final int age;
  final String phone;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.age = 0,
    this.phone = '',
  });

  String get displayName =>
      '$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName';

  bool get hasValidSession => id > 0 && username.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      image: json['image'] as String? ?? '',
      accessToken:
          json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? json['contactNo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'image': image,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'age': age,
    'phone': phone,
  };
}
