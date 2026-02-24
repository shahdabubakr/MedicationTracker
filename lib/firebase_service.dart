import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // حفظ بيانات المستخدم الجديد
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // جلب بيانات المستخدم الحالي
  Future<DocumentSnapshot> getUserData() async {
    return await _db.collection('users').doc(_auth.currentUser!.uid).get();
  }

  // تحديث بيانات البروفايل (الاسم وسنة الميلاد)
  Future<void> updateUserProfile(String newName, int newYear) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).update({
      'name': newName,
      'birthYear': newYear,
    });
  }

  // عمليات الأدوية (Stream للحصول على تحديثات فورية)
  Stream<QuerySnapshot> getMedicinesStream() {
    String uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('medicines').snapshots();
  }

  Future<void> saveMedicine(String medId, Map<String, dynamic> data) async {
    String uid = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(medId)
        .set(data);
  }

  Future<void> deleteMedicine(String medId) async {
    String uid = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(medId)
        .delete();
  }
}
