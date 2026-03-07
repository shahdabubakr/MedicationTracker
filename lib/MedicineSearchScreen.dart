import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'add_medicine_screen.dart';
import 'app_provider.dart';

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
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final bool isAr = appProvider.locale.languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? "لم يتم العثور على نتائج. حاول كتابة الاسم بالإنجليزية بدقة."
              : "No results found. Try typing the exact English name."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? "ابحث باسم الدواء (مثال: Aspirin)"
                          : "Search by medicine name (e.g., Aspirin)",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: primary, size: 24),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                ),
              if (medicineData != null && !isLoading)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.15),
                              primary.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: primary.withValues(alpha: 0.25)),
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
                                color: Color(0xFF4A90E2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Material(
                              borderRadius: BorderRadius.circular(16),
                              shadowColor: primary.withValues(alpha: 0.4),
                              elevation: 6,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  String fullDesc =
                                      medicineData!['indications_and_usage']?[0] ?? "";
                                  String shortDesc = fullDesc.length > 150
                                      ? "${fullDesc.substring(0, 150)}..."
                                      : fullDesc;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddMedicineScreen(
                                        initialName: medicineData!['openfda']?['brand_name']?[0],
                                        initialDesc: shortDesc,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                label: Text(
                                  isAr ? "إضافة لجدولي" : "Add to my schedule",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle(isAr ? "الاستخدام الطبي:" : "Medical use:", primary),
                      _buildInfoText(isAr, medicineData!['indications_and_usage']?[0], isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle(isAr ? "التحذيرات:" : "Warnings:", primary),
                      _buildInfoText(isAr, medicineData!['warnings']?[0], isDark),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }

  Widget _buildInfoText(bool isAr, String? text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.06)) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text ??
            (isAr
                ? "المعلومات غير متوفرة لهذا المنتج."
                : "Information not available for this product."),
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
        ),
      ),
    );
  }
}
