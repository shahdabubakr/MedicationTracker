import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';
import 'app_provider.dart';

class AddMedicineScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddMedicineScreen({super.key, this.docId, this.existingData});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  late TextEditingController nameController;
  late TextEditingController descController;

  int timesPerDay = 1;
  bool isEveryXHours = false;
  int everyXHours = 8;

  String mealRelation = 'any';
  int minutesOffset = 30;

  // تحديد الوجبات المفعلة (الفطار مفعل افتراضياً)
  bool isBreakfastSelected = true;
  bool isLunchSelected = false;
  bool isDinnerSelected = false;

  TimeOfDay breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay lunchTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay dinnerTime = const TimeOfDay(hour: 21, minute: 0);

  List<TimeOfDay> manualTimes = [const TimeOfDay(hour: 8, minute: 0)];

  List<int> selectedDays = [];
  bool isDaily = true;
  bool isSaving = false;

  final List<Map<String, dynamic>> weekDays = [
    {'id': 6, 'ar': 'سبت', 'en': 'Sat'},
    {'id': 7, 'ar': 'أحد', 'en': 'Sun'},
    {'id': 1, 'ar': 'اثنين', 'en': 'Mon'},
    {'id': 2, 'ar': 'ثلاثاء', 'en': 'Tue'},
    {'id': 3, 'ar': 'أربعاء', 'en': 'Wed'},
    {'id': 4, 'ar': 'خميس', 'en': 'Thu'},
    {'id': 5, 'ar': 'جمعة', 'en': 'Fri'},
  ];

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.existingData?['name'] ?? '');
    descController =
        TextEditingController(text: widget.existingData?['description'] ?? '');

    if (widget.existingData != null) {
      final d = widget.existingData!;
      timesPerDay = d['timesPerDay'] ?? 1;
      isEveryXHours = d['isEveryXHours'] ?? false;
      everyXHours = d['everyXHours'] ?? 8;
      mealRelation = d['mealRelation'] ?? 'any';
      minutesOffset = d['minutesOffset'] ?? 30;
      isDaily = d['isDaily'] ?? true;
      selectedDays = List<int>.from(d['days'] ?? []);

      isBreakfastSelected = d['isBreakfastSelected'] ?? true;
      isLunchSelected = d['isLunchSelected'] ?? false;
      isDinnerSelected = d['isDinnerSelected'] ?? false;

      if (d['breakfastTime'] != null) {
        final p = (d['breakfastTime'] as String).split(':');
        breakfastTime =
            TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      if (d['lunchTime'] != null) {
        final p = (d['lunchTime'] as String).split(':');
        lunchTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      if (d['dinnerTime'] != null) {
        final p = (d['dinnerTime'] as String).split(':');
        dinnerTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      if (d['manualTimes'] != null) {
        manualTimes = (d['manualTimes'] as List).map((t) {
          final p = (t as String).split(':');
          return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }).toList();
      }
    } else {
      _loadMealTimesFromFirestore();
    }
  }

  Future<void> _loadMealTimesFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final mealTimes = doc.data()?['mealTimes'] as Map<String, dynamic>?;

    if (mealTimes != null && mounted) {
      setState(() {
        if (mealTimes['breakfast'] != null) {
          final p = (mealTimes['breakfast'] as String).split(':');
          breakfastTime =
              TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
        if (mealTimes['lunch'] != null) {
          final p = (mealTimes['lunch'] as String).split(':');
          lunchTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
        if (mealTimes['dinner'] != null) {
          final p = (mealTimes['dinner'] as String).split(':');
          dinnerTime =
              TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _computeNotificationTimes() {
    List<TimeOfDay> base = [];

    if (isEveryXHours) {
      final start = manualTimes.isNotEmpty
          ? manualTimes[0]
          : const TimeOfDay(hour: 8, minute: 0);
      int h = start.hour;
      int m = start.minute;
      final count = 24 ~/ everyXHours;
      for (int i = 0; i < count; i++) {
        base.add(TimeOfDay(hour: h % 24, minute: m));
        h += everyXHours;
      }
    } else if (mealRelation == 'any') {
      base = List.generate(timesPerDay, (i) {
        if (i < manualTimes.length) return manualTimes[i];
        return TimeOfDay(hour: (8 + (i * 4)) % 24, minute: 0);
      });
    } else {
      // مرتبط بالوجبات المختارة فقط
      final meals = <TimeOfDay>[];
      if (isBreakfastSelected) meals.add(breakfastTime);
      if (isLunchSelected) meals.add(lunchTime);
      if (isDinnerSelected) meals.add(dinnerTime);

      for (final meal in meals) {
        int totalMinutes = meal.hour * 60 + meal.minute;
        if (mealRelation == 'before') totalMinutes -= minutesOffset;
        if (mealRelation == 'after') totalMinutes += minutesOffset;
        totalMinutes = (totalMinutes + 1440) % 1440;
        base.add(TimeOfDay(
          hour: totalMinutes ~/ 60,
          minute: totalMinutes % 60,
        ));
      }
    }

    return base
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();
  }

  int _getCurrentlySelectedMealsCount() {
    int count = 0;
    if (isBreakfastSelected) count++;
    if (isLunchSelected) count++;
    if (isDinnerSelected) count++;
    return count;
  }

  Future<void> _handleSave() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اسم الدواء أولاً')),
      );
      return;
    }

    if (!isEveryXHours && mealRelation != 'any') {
      final selectedCount = _getCurrentlySelectedMealsCount();
      if (selectedCount != timesPerDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'لقد اخترت $timesPerDay مرات يومياً، يرجى تحديد $timesPerDay وجبات بالضبط.'),
          ),
        );
        return;
      }
    }

    if (!isDaily && selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر يوم واحد على الأقل')),
      );
      return;
    }

    setState(() => isSaving = true);
    final isAr =
        Provider.of<AppProvider>(context, listen: false).locale.languageCode ==
            'ar';

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final medId =
        widget.docId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final notificationTimes = _computeNotificationTimes();
    final daysToSave = isDaily ? [1, 2, 3, 4, 5, 6, 7] : selectedDays;

    final data = {
      'name': nameController.text.trim(),
      'description': descController.text.trim(),
      'timesPerDay': timesPerDay,
      'isEveryXHours': isEveryXHours,
      'everyXHours': everyXHours,
      'mealRelation': mealRelation,
      'minutesOffset': minutesOffset,
      'isBreakfastSelected': isBreakfastSelected,
      'isLunchSelected': isLunchSelected,
      'isDinnerSelected': isDinnerSelected,
      'breakfastTime':
          '${breakfastTime.hour.toString().padLeft(2, '0')}:${breakfastTime.minute.toString().padLeft(2, '0')}',
      'lunchTime':
          '${lunchTime.hour.toString().padLeft(2, '0')}:${lunchTime.minute.toString().padLeft(2, '0')}',
      'dinnerTime':
          '${dinnerTime.hour.toString().padLeft(2, '0')}:${dinnerTime.minute.toString().padLeft(2, '0')}',
      'manualTimes': manualTimes
          .map((t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList(),
      'notificationTimes': notificationTimes,
      'days': daysToSave,
      'isDaily': isDaily,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .doc(medId)
          .set(data, SetOptions(merge: true));

      await FirebaseDatabase.instance.ref('devices/$uid/alarms/$medId').set({
        'times': notificationTimes.join(','),
        'status': 'pending',
        'medName': nameController.text.trim(),
        'days': daysToSave.join(','),
      });

      for (int i = 0; i < 10; i++) {
        await NotificationService().cancelNotification(
            NotificationService.notificationIdFromDocId('${medId}_$i'));
      }
      for (int i = 0; i < notificationTimes.length; i++) {
        final nId = NotificationService.notificationIdFromDocId('${medId}_$i');
        await NotificationService().scheduleNotification(
            nId, nameController.text.trim(), notificationTimes[i], isAr);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(widget.docId == null ? 'تمت الإضافة ✓' : 'تم التحديث ✓'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSave();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isAr = appProvider.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF4A90E2);

    final steps = [
      isAr ? 'الدواء' : 'Medicine',
      isAr ? 'الجرعة' : 'Dose',
      isAr ? 'المواعيد' : 'Schedule',
    ];

    return Scaffold(
      body: Container(
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
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 22),
                      onPressed: _currentStep == 0
                          ? () => Navigator.pop(context)
                          : _prevStep,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.docId == null
                              ? (isAr ? 'إضافة دواء' : 'Add Medicine')
                              : (isAr ? 'تعديل الدواء' : 'Edit Medicine'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Step Indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: List.generate(steps.length, (i) {
                    final isActive = i == _currentStep;
                    final isDone = i < _currentStep;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isDone
                                  ? () {
                                      setState(() => _currentStep = i);
                                      _pageController.animateToPage(i,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut);
                                    }
                                  : null,
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: isActive ? 36 : 28,
                                    height: isActive ? 36 : 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDone
                                          ? Colors.green
                                          : isActive
                                              ? primary
                                              : (isDark
                                                  ? Colors.white12
                                                  : Colors.black12),
                                    ),
                                    child: Center(
                                      child: isDone
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 16)
                                          : Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                color: isActive || isDone
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white54
                                                        : Colors.black38),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    steps[i],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? primary
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                margin: const EdgeInsets.only(bottom: 20),
                                color: i < _currentStep
                                    ? Colors.green
                                    : (isDark
                                        ? Colors.white12
                                        : Colors.black12),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(isAr, isDark, primary),
                    _buildStep2(isAr, isDark, primary),
                    _buildStep3(isAr, isDark, primary),
                  ],
                ),
              ),

              // Next Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStep < 2
                                    ? (isAr ? 'التالي' : 'Next')
                                    : (widget.docId == null
                                        ? (isAr ? 'حفظ' : 'Save')
                                        : (isAr ? 'تحديث' : 'Update')),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (_currentStep < 2) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white, size: 16),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Step 1 =====
  Widget _buildStep1(bool isAr, bool isDark, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionTitle(isAr ? 'اسم الدواء' : 'Medicine Name', isDark),
          const SizedBox(height: 12),
          _buildTextField(
            controller: nameController,
            hint: isAr ? 'مثال: باراسيتامول' : 'e.g. Paracetamol',
            icon: Icons.medication_rounded,
            isDark: isDark,
            primary: primary,
          ),
          const SizedBox(height: 20),
          _sectionTitle(
              isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)', isDark),
          const SizedBox(height: 12),
          _buildTextField(
            controller: descController,
            hint: isAr ? 'مثال: حبة واحدة' : 'e.g. One tablet',
            icon: Icons.notes_rounded,
            isDark: isDark,
            primary: primary,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _sectionTitle(isAr ? 'التكرار' : 'Repeat', isDark),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'يومياً' : 'Daily',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: isDaily,
                      activeColor: primary,
                      onChanged: (val) => setState(() => isDaily = val),
                    ),
                  ],
                ),
                if (!isDaily) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: weekDays.map((day) {
                      final isSelected = selectedDays.contains(day['id']);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected
                              ? selectedDays.remove(day['id'])
                              : selectedDays.add(day['id']);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary
                                : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAr ? day['ar'] : day['en'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Step 2 =====
  Widget _buildStep2(bool isAr, bool isDark, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionTitle(
              isAr ? 'كام مرة في اليوم؟' : 'How many times a day?', isDark),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _toggleChip(
                        label: isAr ? 'مرات محددة' : 'Fixed times',
                        selected: !isEveryXHours,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => setState(() => isEveryXHours = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _toggleChip(
                        label: isAr ? 'كل X ساعات' : 'Every X hours',
                        selected: isEveryXHours,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => setState(() => isEveryXHours = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isEveryXHours) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circleButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (timesPerDay > 1) {
                            setState(() {
                              timesPerDay--;
                              // ضبط الاختيارات الافتراضية للوجبات
                              if (timesPerDay == 1) {
                                isBreakfastSelected = true;
                                isLunchSelected = false;
                                isDinnerSelected = false;
                              } else if (timesPerDay == 2) {
                                isBreakfastSelected = true;
                                isLunchSelected = true;
                                isDinnerSelected = false;
                              }
                            });
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '$timesPerDay',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          Text(
                            isAr ? 'مرة يومياً' : 'times/day',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      _circleButton(
                        icon: Icons.add,
                        onTap: () {
                          if (timesPerDay < 3) {
                            setState(() {
                              timesPerDay++;
                              if (timesPerDay == 2) {
                                isBreakfastSelected = true;
                                isLunchSelected = true;
                              } else if (timesPerDay == 3) {
                                isBreakfastSelected = true;
                                isLunchSelected = true;
                                isDinnerSelected = true;
                              }
                            });
                          }
                        },
                        isDark: isDark,
                        primary: primary,
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circleButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (everyXHours > 1) setState(() => everyXHours--);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '$everyXHours',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          Text(
                            isAr ? 'ساعة' : 'hours',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      _circleButton(
                        icon: Icons.add,
                        onTap: () {
                          if (everyXHours < 24) setState(() => everyXHours++);
                        },
                        isDark: isDark,
                        primary: primary,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(isAr ? 'علاقته بالأكل' : 'Relation to meals', isDark),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _mealChip(
                        label: isAr ? 'قبل' : 'Before',
                        icon: '🍽️',
                        selected: mealRelation == 'before',
                        primary: primary,
                        isDark: isDark,
                        onTap: () => setState(() => mealRelation = 'before'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _mealChip(
                        label: isAr ? 'مع' : 'With',
                        icon: '🥗',
                        selected: mealRelation == 'with',
                        primary: primary,
                        isDark: isDark,
                        onTap: () => setState(() => mealRelation = 'with'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _mealChip(
                        label: isAr ? 'بعد' : 'After',
                        icon: '✅',
                        selected: mealRelation == 'after',
                        primary: primary,
                        isDark: isDark,
                        onTap: () => setState(() => mealRelation = 'after'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _mealChip(
                        label: isAr ? 'مش مهم' : 'Any time',
                        icon: '⏰',
                        selected: mealRelation == 'any',
                        primary: primary,
                        isDark: isDark,
                        onTap: () => setState(() => mealRelation = 'any'),
                      ),
                    ),
                  ],
                ),
                if (mealRelation == 'before' || mealRelation == 'after') ...[
                  const SizedBox(height: 16),
                  Text(
                    isAr
                        ? '${mealRelation == 'before' ? 'قبل' : 'بعد'} الأكل بـ $minutesOffset دقيقة'
                        : '$minutesOffset min ${mealRelation == 'before' ? 'before' : 'after'} meal',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: minutesOffset.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 7,
                    activeColor: primary,
                    label: '$minutesOffset ${isAr ? 'دقيقة' : 'min'}',
                    onChanged: (val) =>
                        setState(() => minutesOffset = val.round()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Step 3 =====
  Widget _buildStep3(bool isAr, bool isDark, Color primary) {
    final showMeals = (mealRelation != 'any') && !isEveryXHours;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (showMeals) ...[
            _sectionTitle(
              isAr ? 'اختر الوجبات ومواعيدها' : 'Select meals and times',
              isDark,
              subtitle: isAr
                  ? 'اختر $timesPerDay وجبة تناسب جدول علاجك'
                  : 'Select $timesPerDay meals for your dose schedule',
            ),
            const SizedBox(height: 12),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  _selectableMealTimeTile(
                    emoji: '🌅',
                    label: isAr ? 'الفطار' : 'Breakfast',
                    time: breakfastTime,
                    isSelected: isBreakfastSelected,
                    primary: primary,
                    isDark: isDark,
                    onToggle: (val) =>
                        setState(() => isBreakfastSelected = val ?? false),
                    onTimeTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: breakfastTime);
                      if (t != null) setState(() => breakfastTime = t);
                    },
                  ),
                  const Divider(height: 1),
                  _selectableMealTimeTile(
                    emoji: '☀️',
                    label: isAr ? 'الغداء' : 'Lunch',
                    time: lunchTime,
                    isSelected: isLunchSelected,
                    primary: primary,
                    isDark: isDark,
                    onToggle: (val) =>
                        setState(() => isLunchSelected = val ?? false),
                    onTimeTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: lunchTime);
                      if (t != null) setState(() => lunchTime = t);
                    },
                  ),
                  const Divider(height: 1),
                  _selectableMealTimeTile(
                    emoji: '🌙',
                    label: isAr ? 'العشاء' : 'Dinner',
                    time: dinnerTime,
                    isSelected: isDinnerSelected,
                    primary: primary,
                    isDark: isDark,
                    onToggle: (val) =>
                        setState(() => isDinnerSelected = val ?? false),
                    onTimeTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: dinnerTime);
                      if (t != null) setState(() => dinnerTime = t);
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            _sectionTitle(
              isEveryXHours
                  ? (isAr ? 'وقت بداية الجرعة الأولى' : 'Start time')
                  : (isAr ? 'تحديد مواعيد الجرعات' : 'Dose Times'),
              isDark,
              subtitle: isEveryXHours
                  ? null
                  : (isAr
                      ? 'حدد وقت كل جرعة يدوياً'
                      : 'Set time for each dose'),
            ),
            const SizedBox(height: 12),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  ...List.generate(
                    isEveryXHours ? 1 : timesPerDay,
                    (i) {
                      while (manualTimes.length <= i) {
                        manualTimes.add(
                            TimeOfDay(hour: (8 + (i * 4)) % 24, minute: 0));
                      }
                      return Column(
                        children: [
                          if (i > 0) const Divider(height: 1),
                          _simpleTimeTile(
                            emoji: '⏰',
                            label: isEveryXHours
                                ? (isAr ? 'وقت البداية' : 'Start time')
                                : (isAr ? 'الجرعة ${i + 1}' : 'Dose ${i + 1}'),
                            time: manualTimes[i],
                            primary: primary,
                            isDark: isDark,
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: context,
                                  initialTime: manualTimes[i]);
                              if (t != null) {
                                setState(() {
                                  manualTimes[i] = t;
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // كارت معاينة أوقات التنبيه النهائية
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        color: primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isAr
                          ? 'مواعيد التنبيهات التي ستصلك'
                          : 'Notification times',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _computeNotificationTimes().map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===== Helpers =====

  Widget _selectableMealTimeTile({
    required String emoji,
    required String label,
    required TimeOfDay time,
    required bool isSelected,
    required Color primary,
    required bool isDark,
    required ValueChanged<bool?> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: primary,
            onChanged: onToggle,
          ),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.black38),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: isSelected ? onTimeTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withOpacity(0.12)
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: isSelected
                      ? primary
                      : (isDark ? Colors.white38 : Colors.black38),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleTimeTile({
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
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

  Widget _sectionTitle(String title, bool isDark, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color primary,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
        prefixIcon: Icon(icon, color: primary, size: 22),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required Color primary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealChip({
    required String label,
    required String icon,
    required bool selected,
    required Color primary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? null
              : Border.all(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary != null
              ? primary
              : (isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Icon(
          icon,
          color: primary != null
              ? Colors.white
              : (isDark ? Colors.white60 : Colors.black54),
          size: 22,
        ),
      ),
    );
  }
}
