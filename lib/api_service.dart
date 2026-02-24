import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // دالة البحث عن دواء بالاسم
  Future<Map<String, dynamic>?> fetchMedicineInfo(String medName) async {
    // نستخدم query parameter للبحث في brand_name
    final url = Uri.parse(
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:"$medName"&limit=1');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]; // بنرجع أول نتيجة تطلع
        }
      } else {
        print("Error: Status Code ${response.statusCode}");
      }
    } catch (e) {
      print("Exception during API call: $e");
    }
    return null;
  }
}
