import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_provider.dart';

/// Put this file next to settings_screen.dart (lib/settings/).
class LinkMachineScreen extends StatefulWidget {
  const LinkMachineScreen({super.key});

  @override
  State<LinkMachineScreen> createState() => _LinkMachineScreenState();
}

class _LinkMachineScreenState extends State<LinkMachineScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _machineId;
  Timer? _tick;

  static const Color _primary = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    _loadLinked();
    // refresh the "online" label even when Firebase sends no new event
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLinked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final id = doc.data()?['machineId'] as String?;
    if (!mounted) return;
    setState(() {
      _machineId = (id == null || id.isEmpty) ? null : id;
      _loading = false;
    });
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _link(bool isAr) async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _snack(isAr ? 'اكتب الكود المكوّن من 6 أرقام' : 'Enter the 6-digit code');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      final snap = await FirebaseDatabase.instance.ref('pairing/$code').get();
      final value = snap.value;
      if (!snap.exists || value is! Map || value['machineUid'] == null) {
        _snack(isAr
            ? 'الكود غير صحيح أو انتهت صلاحيته'
            : 'Invalid or expired code');
        return;
      }
      final mid = value['machineUid'].toString();

      await FirebaseDatabase.instance.ref('machines/$mid/owner').set(uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'machineId': mid}, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _machineId = mid);
      _codeCtrl.clear();
      _snack(isAr ? 'تم ربط الماكينة ✓' : 'Machine linked ✓',
          color: Colors.green);
    } on FirebaseException catch (e) {
      _snack(e.code == 'permission-denied'
          ? (isAr
              ? 'الماكينة دي مربوطة بحساب تاني'
              : 'This machine is already linked to another account')
          : '${e.code}: ${e.message}');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink(bool isAr) async {
    final mid = _machineId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (mid == null || uid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isAr ? 'فك ربط الماكينة' : 'Unlink machine'),
        content: Text(isAr
            ? 'الماكينة هتتوقف عن قراءة أدويتك وهتطلب ربط جديد.'
            : 'The machine will stop reading your medicines and ask for a new link.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'فك الربط' : 'Unlink',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await FirebaseDatabase.instance.ref('machines/$mid/owner').remove();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'machineId': FieldValue.delete()});
      if (!mounted) return;
      setState(() => _machineId = null);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _lastDoseText(Map? dose, bool isAr) {
    if (dose == null) return isAr ? 'لا توجد جرعات بعد' : 'No doses yet';
    final result = dose['result']?.toString() ?? '';
    final labels = {
      'taken': isAr ? 'تم أخذ الدواء' : 'Taken',
      'missed': isAr ? 'لم يؤخذ' : 'Missed',
      'no_strip': isAr ? 'لم يُكتشف شريط' : 'No strip detected',
      'motor_error': isAr ? 'عطل في المحرك' : 'Motor error',
      'skipped': isAr ? 'تم تخطيه' : 'Skipped',
    };
    return '${dose['at'] ?? ''}  •  ${labels[result] ?? result}';
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAr = appProvider.locale.languageCode == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                  isAr ? 'ربط الماكينة' : 'Link Machine',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _machineId == null
                              ? _buildLinkCard(isAr, isDark)
                              : _buildLinkedCard(isAr, isDark),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12))
              ],
      ),
      child: child,
    );
  }

  Widget _buildLinkCard(bool isAr, bool isDark) {
    return _card(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
              child: Icon(Icons.medication_liquid_rounded,
                  size: 56, color: _primary)),
          const SizedBox(height: 16),
          Text(
            isAr
                ? 'شغّل الماكينة وهيظهر على شاشتها كود من 6 أرقام. اكتبه هنا.'
                : 'Turn the machine on. A 6-digit code appears on its screen. Type it here.',
            style: TextStyle(
                height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _busy ? null : () => _link(isAr),
              child: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(isAr ? 'ربط' : 'Link',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedCard(bool isAr, bool isDark) {
    final ref = FirebaseDatabase.instance.ref('machines/$_machineId');
    return _card(
      isDark,
      StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snap) {
          final raw = snap.data?.snapshot.value;
          final Map? data = raw is Map ? raw : null;

          final int lastSeen = (data?['lastSeen'] is num)
              ? (data!['lastSeen'] as num).toInt()
              : 0;
          final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final bool isOnline = lastSeen > 0 && (nowSec - lastSeen) < 150;
          final Map? lastDose =
              data?['lastDose'] is Map ? data!['lastDose'] as Map : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: isOnline ? Colors.green : Colors.orange),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'الماكينة مربوطة' : 'Machine linked',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isOnline
                    ? (isAr ? 'متصلة الآن' : 'Online now')
                    : (isAr ? 'غير متصلة بالإنترنت' : 'Offline'),
                style: TextStyle(
                    color: isOnline ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                '${isAr ? 'آخر جرعة' : 'Last dose'}: ${_lastDoseText(lastDose, isAr)}',
                style: TextStyle(
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.link_off_rounded),
                  label: Text(isAr ? 'فك الربط' : 'Unlink'),
                  onPressed: _busy ? null : () => _unlink(isAr),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}