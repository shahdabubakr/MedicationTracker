import 'package:flutter/material.dart';
import 'api_service.dart';
import 'add_medicine_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  final bool isAr;
  final bool isDark;

  const MedicineSearchScreen({
    super.key,
    required this.isAr,
    required this.isDark,
  });

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
        SnackBar(
          content: Text(widget.isAr
              ? "لم يتم العثور على نتائج. حاول كتابة الاسم بالإنجليزية بدقة."
              : "No results found. Try typing the exact English name."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = widget.isAr;
    bool isDark = widget.isDark;
    const Color primary = Color(0xFF4A90E2);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0F2FE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "قاموس الأدوية الذكي" : "Smart Medicine Dictionary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? "ابحث باسم الدواء (مثال: Aspirin)"
                          : "Search by medicine name (e.g., Aspirin)",
                      hintStyle: TextStyle(
                        color:
                            isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      ),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
              ),
              if (isLoading)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(color: primary))),
              if (medicineData != null && !isLoading)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withOpacity(0.15),
                              primary.withOpacity(0.08)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: primary.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              medicineData!['openfda']?['brand_name']?[0] ??
                                  _searchController.text.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                String fullDesc =
                                    medicineData!['indications_and_usage']
                                            ?[0] ??
                                        "";
                                String shortDesc = fullDesc.length > 150
                                    ? "${fullDesc.substring(0, 150)}..."
                                    : fullDesc;

                                String brandName = medicineData!['openfda']
                                        ?['brand_name']?[0] ??
                                    _searchController.text;

                                // التعديل هنا ليتوافق مع الـ Constructor الجديد
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddMedicineScreen(
                                      docId: null,
                                      existingData: {
                                        'name': brandName,
                                        'description': shortDesc,
                                        'time':
                                            "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
                                        'isDaily': true,
                                        'days': [1, 2, 3, 4, 5, 6, 7],
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded,
                                  color: Colors.white),
                              label: Text(
                                isAr ? "إضافة لجدولي" : "Add to my schedule",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                          isAr ? "الاستخدام الطبي:" : "Medical use:",
                          primary,
                          isAr),
                      _buildInfoText(isAr,
                          medicineData!['indications_and_usage']?[0], isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                          isAr ? "التحذيرات:" : "Warnings:", primary, isAr),
                      _buildInfoText(
                          isAr, medicineData!['warnings']?[0], isDark),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primary, bool isAr) {
    return Align(
      alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: primary)),
      ),
    );
  }

  Widget _buildInfoText(bool isAr, String? text, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Text(
        text ??
            (isAr
                ? "المعلومات غير متوفرة لهذا المنتج."
                : "Information not available."),
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
      ),
    );
  }
}
