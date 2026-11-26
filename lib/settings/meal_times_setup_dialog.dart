import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';

class MealTimesSetupDialog extends StatefulWidget {
  const MealTimesSetupDialog({super.key});

  @override
  State<MealTimesSetupDialog> createState() => _MealTimesSetupDialogState();
}

class _MealTimesSetupDialogState extends State<MealTimesSetupDialog> {
  TimeOfDay breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay lunchTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay dinnerTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isSaving = false;

  Future<void> _pickTime(String meal) async {
    final initial = meal == 'breakfast'
        ? breakfastTime
        : meal == 'lunch'
            ? lunchTime
            : dinnerTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (meal == 'breakfast') breakfastTime = picked;
        if (meal == 'lunch') lunchTime = picked;
        if (meal == 'dinner') dinnerTime = picked;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'mealTimes': {
          'breakfast':
              '${breakfastTime.hour.toString().padLeft(2, '0')}:${breakfastTime.minute.toString().padLeft(2, '0')}',
          'lunch':
              '${lunchTime.hour.toString().padLeft(2, '0')}:${lunchTime.minute.toString().padLeft(2, '0')}',
          'dinner':
              '${dinnerTime.hour.toString().padLeft(2, '0')}:${dinnerTime.minute.toString().padLeft(2, '0')}',
        },
        'mealTimesSet': true,
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primary = Color(0xFF4A90E2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              isAr ? 'أوقات وجباتك' : 'Your Meal Times',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'حدد أوقات وجباتك عشان نذكرك بدواءك في الوقت الصح'
                  : 'Set your meal times so we remind you at the right time',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _mealTile(
              emoji: '🌅',
              label: isAr ? 'الفطار' : 'Breakfast',
              time: breakfastTime,
              primary: primary,
              isDark: isDark,
              onTap: () => _pickTime('breakfast'),
            ),
            Divider(color: isDark ? Colors.white12 : Colors.black12),
            _mealTile(
              emoji: '☀️',
              label: isAr ? 'الغداء' : 'Lunch',
              time: lunchTime,
              primary: primary,
              isDark: isDark,
              onTap: () => _pickTime('lunch'),
            ),
            Divider(color: isDark ? Colors.white12 : Colors.black12),
            _mealTile(
              emoji: '🌙',
              label: isAr ? 'العشاء' : 'Dinner',
              time: dinnerTime,
              primary: primary,
              isDark: isDark,
              onTap: () => _pickTime('dinner'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isAr ? 'حفظ' : 'Save',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                isAr ? 'استخدام الأوقات الافتراضية' : 'Use default times',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealTile({
    required String emoji,
    required String label,
    required TimeOfDay time,
    required Color primary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
