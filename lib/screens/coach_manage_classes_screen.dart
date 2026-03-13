import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'coach_class_detail_screen.dart';

class CoachManageClassesScreen extends StatefulWidget {
  const CoachManageClassesScreen({super.key});

  @override
  State<CoachManageClassesScreen> createState() => _CoachManageClassesScreenState();
}

class _CoachManageClassesScreenState extends State<CoachManageClassesScreen> {
  final api = ApiService();
  bool loading = true;
  List<dynamic> classes = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().token;
      final data = await api.getMyClasses(token: token!);
      setState(() {
        classes = List<dynamic>.from(data);
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

  Future<void> _showForm([Map<String, dynamic>? existing]) async {
    final token = context.read<AuthProvider>().token!;
    final schedule = existing == null ? <String, dynamic>{} : _scheduleOf(existing);
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final startCtrl = TextEditingController(text: schedule['startDate']?.toString() ?? '2026-03-11');
    final endCtrl = TextEditingController(text: schedule['endDate']?.toString() ?? '2026-04-11');
    final sessionCtrl = TextEditingController(text: schedule['sessionText']?.toString() ?? '18:00 - 19:30');
    final priceCtrl = TextEditingController(text: schedule['note']?.toString() ?? '300000đ / buổi');
    final maxCtrl = TextEditingController(text: existing?['maxStudents']?.toString() ?? '20');
    final selected = <String>{...((schedule['weekdays'] as List?)?.map((e) => '$e') ?? ['Thứ 2', 'Thứ 4'])};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Thêm lớp học' : 'Sửa lớp học'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Ngày bắt đầu YYYY-MM-DD')),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Ngày kết thúc YYYY-MM-DD')),
                TextField(controller: sessionCtrl, decoration: const InputDecoration(labelText: 'Buổi học / giờ')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Học phí')),
                TextField(controller: maxCtrl, decoration: const InputDecoration(labelText: 'Số lượng tối đa')),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật']
                      .map(
                        (d) => FilterChip(
                          label: Text(d),
                          selected: selected.contains(d),
                          onSelected: (v) {
                            setDialog(() {
                              if (v) {
                                selected.add(d);
                              } else {
                                selected.remove(d);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (existing == null) {
                    await api.createClassManaged(
                      token: token,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      startDate: startCtrl.text.trim(),
                      endDate: endCtrl.text.trim(),
                      weekdays: selected.toList(),
                      sessionText: sessionCtrl.text.trim(),
                      priceText: priceCtrl.text.trim(),
                      maxStudents: int.tryParse(maxCtrl.text.trim()) ?? 20,
                    );
                  } else {
                    await api.updateClassManaged(
                      token: token,
                      id: int.tryParse('${existing['id']}') ?? 0,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      startDate: startCtrl.text.trim(),
                      endDate: endCtrl.text.trim(),
                      weekdays: selected.toList(),
                      sessionText: sessionCtrl.text.trim(),
                      priceText: priceCtrl.text.trim(),
                      maxStudents: int.tryParse(maxCtrl.text.trim()) ?? 20,
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý lớp học')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final item = Map<String, dynamic>.from(classes[index] as Map);
                    final schedule = _scheduleOf(item);
                    final weekdays = (schedule['weekdays'] as List? ?? []).join(', ');
                    final enrolledCount = (item['enrollments'] as List? ?? []).length;
                    final classId = int.tryParse('${item['id']}') ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CoachClassDetailScreen(classItem: item)),
                          );
                          _load();
                        },
                        title: Text(item['title']?.toString() ?? '-'),
                        subtitle: Text(
                          '${item['description'] ?? ''}\n$weekdays\n${schedule['sessionText'] ?? '-'} • ${schedule['note'] ?? 'Liên hệ'}\nHọc viên: $enrolledCount/${item['maxStudents'] ?? 0}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'detail') {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => CoachClassDetailScreen(classItem: item)));
                              _load();
                            } else if (v == 'edit') {
                              _showForm(item);
                            } else if (v == 'delete') {
                              final token = context.read<AuthProvider>().token!;
                              await api.deleteClassManaged(token: token, id: classId);
                              _load();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'detail', child: Text('Quản lý lớp')),
                            PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
