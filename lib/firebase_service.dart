import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
    if (_auth.currentUser == null) {
      throw Exception("No user is currently signed in");
    }
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

  // 1. إضافة أو تعديل دواء (تسمع في Firestore والـ Realtime Database فوراً)
  Future<void> saveMedicine(String medId, Map<String, dynamic> data) async {
    String uid = _auth.currentUser!.uid;
    
    // حفظ أو تحديث في Firestore
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(medId)
        .set(data, SetOptions(merge: true));

    // مزامنة نفس الإضافة أو التعديل مع Realtime Database الخاصة بالماكينة
    try {
      final url = Uri.parse('https://medicationtracker-31883-default-rtdb.firebaseio.com/devices/$uid/alarms/$medId.json');
      
      String daysStr = "";
      if (data['days'] is List) {
        daysStr = (data['days'] as List).join(',');
      } else {
        daysStr = data['days']?.toString() ?? "1,2,3,4,5,6,7";
      }

      await http.patch(
        url,
        body: jsonEncode({
          "medName": data['medName'] ?? data['name'] ?? "Medicine",
          "times": data['times'] ?? data['time'] ?? "08:00",
          "days": daysStr,
          "status": "pending"
        }),
      );
      print("تم مزامنة (إضافة/تعديل) الدواء مع الماكينة بنجاح!");
    } catch (e) {
      print("خطأ في مزامنة الماكينة: $e");
    }
  }

  // 2. حذف دواء (يتحذف من Firestore ويتمسح تماماً من الـ Realtime Database والماكينة)
  Future<void> deleteMedicine(String medId) async {
    String uid = _auth.currentUser!.uid;
    
    // الحذف من Firestore
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(medId)
        .delete();

    // الحذف تماماً من Realtime Database ليقف أي تنبيه أو دوران للماكينة
    try {
      final url = Uri.parse('https://medicationtracker-31883-default-rtdb.firebaseio.com/devices/$uid/alarms/$medId.json');
      final response = await http.delete(url);
      print("تم مسح الدواء نهائياً من الماكينة - HTTP code: ${response.statusCode}");
    } catch (e) {
      print("خطأ في حذف الدواء من الماكينة: $e");
    }
  }
}