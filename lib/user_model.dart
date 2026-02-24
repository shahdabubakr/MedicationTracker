class UserModel {
  final String uid; // رقم اليوزر في فايربيز
  final String name; // اسمه
  final int birthYear; // سنة ميلاده
  final String email; // إيميله

  UserModel({
    required this.uid,
    required this.name,
    required this.birthYear,
    required this.email,
  });

  // 1. تحويل البيانات من "كلاس" لـ "Map" عشان تتبعت للفايربيز
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'birthYear': birthYear, 'email': email};
  }

  // 2. تحويل البيانات اللي جاية من فايربيز (Map) لـ "كلاس" عشان نستخدمها في الأبلكيشن
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      birthYear: map['birthYear'] ?? 2000,
      email: map['email'] ?? '',
    );
  }
}
