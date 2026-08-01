class UserModel {
  final String uid;
  final String name;
  final int birthYear;
  final String email;
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.birthYear,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'birthYear': birthYear,
      'email': email,
      'phone': phone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      birthYear: map['birthYear'] ?? 2000,
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}
