import 'package:flutter/material.dart';
import 'api_service.dart';
import 'add_medicine_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? medicineData;
  bool isLoading = false;

  void _search() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() {
      isLoading = true;
      medicineData = null;
    });

    final data =
        await ApiService().fetchMedicineInfo(_searchController.text.trim());

    setState(() {
      medicineData = data;
      isLoading = false;
    });

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "لم يتم العثور على نتائج. حاول كتابة الاسم بالإنجليزية بدقة.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("قاموس الأدوية الذكي"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // حقل البحث
            TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "ابحث باسم الدواء (مثال: Aspirin)",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90E2)),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),

            if (isLoading) const Center(child: CircularProgressIndicator()),

            if (medicineData != null)
              Expanded(
                child: ListView(
                  children: [
                    // كارت النتيجة الأساسية
                    Card(
                      elevation: 0,
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              medicineData!['openfda']?['brand_name']?[0] ??
                                  _searchController.text.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A90E2)),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: () {
                                // سحب الوصف (نأخذ أول 100 حرف من الاستخدام عشان ميبقاش طويل جداً)
                                String fullDesc =
                                    medicineData!['indications_and_usage']
                                            ?[0] ??
                                        "";
                                String shortDesc = fullDesc.length > 150
                                    ? "${fullDesc.substring(0, 150)}..."
                                    : fullDesc;

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddMedicineScreen(
                                        initialName: medicineData!['openfda']
                                            ?['brand_name']?[0],
                                        initialDesc: shortDesc,
                                      ),
                                    ));
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text("إضافة لجدولي",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("الاستخدام الطبي:"),
                    _buildInfoText(medicineData!['indications_and_usage']?[0]),
                    const SizedBox(height: 20),
                    _buildSectionTitle("التحذيرات:"),
                    _buildInfoText(medicineData!['warnings']?[0]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A90E2)));
  }

  Widget _buildInfoText(String? text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text ?? "المعلومات غير متوفرة لهذا المنتج.",
          style: const TextStyle(fontSize: 15, height: 1.5)),
    );
  }
}
