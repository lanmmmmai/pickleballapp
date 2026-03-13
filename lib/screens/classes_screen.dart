import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final api = ApiService();
  bool loading = true;
  List<dynamic> items = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await api.getClasses();
      setState(() {
        items = List<dynamic>.from(response);
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> _scheduleOf(Map<String, dynamic> item) {
    final raw = item['schedule']?.toString() ?? '';
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> enroll(Map<String, dynamic> item) async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      final schedule = _scheduleOf(item);
      final tuition = schedule['note']?.toString() ?? 'Liên hệ coach';
      String method = auth.paymentMethods.where((e) => e != 'Tiền mặt').isNotEmpty ? auth.paymentMethods.firstWhere((e) => e != 'Tiền mặt') : 'Tiền mặt';
      final accountCtrl = TextEditingController();
      String? requestId;

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Thanh toán tham gia lớp'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']?.toString() ?? 'Lớp học'),
                  const SizedBox(height: 8),
                  Text('Học phí: $tuition'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    items: const [
                      DropdownMenuItem(value: 'Tiền mặt', child: Text('Tiền mặt')),
                      DropdownMenuItem(value: 'Chuyển khoản QR', child: Text('Chuyển khoản QR')),
                      DropdownMenuItem(value: 'MoMo', child: Text('MoMo')),
                      DropdownMenuItem(value: 'ZaloPay', child: Text('ZaloPay')),
                    ],
                    onChanged: (v) => setModal(() => method = v ?? 'Tiền mặt'),
                  ),
                  if (method != 'Tiền mặt') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số tài khoản / số ví',
                        helperText: 'Nếu chưa lưu ở trang tài khoản, nhập nhanh tại đây',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (method != 'Tiền mặt') {
                      if (accountCtrl.text.trim().isEmpty) {
                        throw Exception('Vui lòng nhập số tài khoản / số ví');
                      }
                      final req = await api.requestPaymentMethodOtp(token: token, method: method, account: accountCtrl.text.trim());
                      requestId = req['requestId']?.toString();
                      final otpCtrl = TextEditingController();
                      final otp = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Nhập OTP'),
                          content: TextField(controller: otpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'OTP 6 số')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, otpCtrl.text.trim()), child: const Text('Xác nhận')),
                          ],
                        ),
                      );
                      if (otp == null || otp.isEmpty || requestId == null) return;
                      await api.verifyPaymentMethodOtp(token: token, requestId: requestId!, otp: otp);
                    }
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                  }
                },
                child: const Text('Thanh toán & tham gia'),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
      await api.enrollClass(token: token, classId: int.tryParse('${item['id']}') ?? 0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký lớp thành công')));
      load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lớp học')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = Map<String, dynamic>.from(items[index] as Map);
                    final schedule = _scheduleOf(item);
                    final weekdays = (schedule['weekdays'] as List? ?? []).join(', ');
                    final count = (item['enrollments'] as List? ?? []).length;
                    return Card(
                      child: ListTile(
                        title: Text(item['title']?.toString() ?? ''),
                        subtitle: Text('${item['description'] ?? ''}\n$weekdays\n${schedule['sessionText'] ?? '-'} • ${schedule['note'] ?? 'Liên hệ'}\nHọc viên: $count/${item['maxStudents'] ?? 0}'),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () => enroll(item),
                          child: const Text('Tham gia'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
