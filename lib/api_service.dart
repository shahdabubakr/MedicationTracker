import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ===== FDA API =====
  Future<Map<String, dynamic>?> fetchMedicineInfo(String medName) async {
    final url = Uri.parse(
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:"$medName"&limit=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0];
        }
      }
    } catch (e) {
      print("FDA API Error: $e");
    }
    return null;
  }

  // ===== ترجمة بيانات الدواء عبر Claude API =====
  Future<Map<String, String>> translateMedicineData(
      Map<String, dynamic> rawData) async {
    // استخراج البيانات المهمة من FDA
    final purpose = _extractFirst(rawData['purpose']);
    final warnings = _extractFirst(rawData['warnings']);
    final dosage = _extractFirst(rawData['dosage_and_administration']);
    final sideEffects = _extractFirst(rawData['adverse_reactions']);
    final brandName = _extractFirst(rawData['openfda']?['brand_name']);
    final genericName = _extractFirst(rawData['openfda']?['generic_name']);

    final textToTranslate = '''
Brand Name: $brandName
Generic Name: $genericName
Purpose: $purpose
Warnings: $warnings
Dosage: $dosage
Side Effects: $sideEffects
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content':
                  '''أنت مساعد طبي متخصص. ترجم معلومات الدواء التالية للعربية بشكل واضح ومبسط مناسب للمريض العادي.
أجب فقط بـ JSON بالشكل التالي بدون أي نص إضافي:
{
  "brandName": "اسم الدواء التجاري",
  "genericName": "الاسم العلمي",
  "purpose": "الاستخدام",
  "warnings": "التحذيرات",
  "dosage": "الجرعة",
  "sideEffects": "الآثار الجانبية"
}

البيانات:
$textToTranslate'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['content'][0]['text'] as String;
        final clean =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        final translated = json.decode(clean) as Map<String, dynamic>;
        return translated.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      print("Translation Error: $e");
    }

    // لو الترجمة فشلت نرجع النص الأصلي
    return {
      'brandName': brandName ?? '',
      'genericName': genericName ?? '',
      'purpose': purpose ?? '',
      'warnings': warnings ?? '',
      'dosage': dosage ?? '',
      'sideEffects': sideEffects ?? '',
    };
  }

  String? _extractFirst(dynamic value) {
    if (value == null) return null;
    if (value is List && value.isNotEmpty) return value[0].toString();
    return value.toString();
  }
}
