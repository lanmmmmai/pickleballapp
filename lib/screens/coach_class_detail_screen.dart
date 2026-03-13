import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CoachClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classItem;
  const CoachClassDetailScreen({super.key, required this.classItem});

  @override
  State<CoachClassDetailScreen> createState() => _CoachClassDetailScreenState();
}

class _CoachClassDetailScreenState extends State<CoachClassDetailScreen> {
  final api = ApiService();
  late Map<String, dynamic> item;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    item = Map<String, dynamic>.from(widget.classItem);
  }

  Map<String, dynamic> get _schedule {
    final raw = item['schedule']?.toString() ?? '';
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final classes = await api.getMyClasses(token: token);
      final found = classes.cast<dynamic>().map((e) => Map<String, dynamic>.from(e as Map)).firstWhere(
            (e) => '${e['id']}' == '${item['id']}',
            orElse: () => item,
          );
      setState(() => item = found);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addStudentDialog() async {
    final ctrl = TextEditingController();
    final token = context.read<AuthProvider>().token!;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm học viên vào lớp'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nhập ID học viên',
            hintText: 'Ví dụ: 2',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final userId = int.tryParse(ctrl.text.trim());
              if (userId == null) return;
              try {
                await api.enrollStudentToClass(token: token, classId: int.tryParse('${item['id']}') ?? 0, userId: userId);
                if (!mounted) return;
                Navigator.pop(context);
                await _refresh();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            },
            child: const Text('Thêm học viên'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPostForClass() async {
    final token = context.read<AuthProvider>().token!;
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng bài cho lớp học'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Nhập thông báo / nội dung bài đăng cho lớp học'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await api.createPost(
                  token: token,
                  content: '[${item['title']}] ${ctrl.text.trim()}',
                  hashtags: '#lophoc #${(item['title'] ?? 'class').toString().replaceAll(' ', '')}',
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng bài cho lớp học')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            },
            child: const Text('Đăng bài'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enrollments = (item['enrollments'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final schedule = _schedule;
    final weekdays = (schedule['weekdays'] as List? ?? []).join(', ');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(item['title']?.toString() ?? 'Chi tiết lớp học'),
          bottom: const TabBar(tabs: [Tab(text: 'Tổng quan'), Tab(text: 'Học viên'), Tab(text: 'Bài đăng')]),
          actions: [IconButton(onPressed: loading ? null : _refresh, icon: const Icon(Icons.refresh))],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addStudentDialog,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Thêm học viên'),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _box('Mô tả', item['description']?.toString().isNotEmpty == true ? item['description'].toString() : 'Chưa có mô tả'),
                _box('Lịch học', 'Từ ${schedule['startDate'] ?? '-'} đến ${schedule['endDate'] ?? '-'}\n$weekdays\n${schedule['sessionText'] ?? '-'}'),
                _box('Học phí', schedule['note']?.toString() ?? 'Liên hệ coach'),
                _box('Số học viên', '${enrollments.length}/${item['maxStudents'] ?? 0} học viên'),
              ],
            ),
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: enrollments.length,
              itemBuilder: (_, index) {
                final enrollment = enrollments[index];
                final user = Map<String, dynamic>.from((enrollment['user'] ?? {}) as Map);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text((user['name']?.toString() ?? 'U')[0].toUpperCase())),
                    title: Text(user['name']?.toString() ?? 'Học viên'),
                    subtitle: Text(user['email']?.toString() ?? 'Chưa có email'),
                  ),
                );
              },
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _box('Bài đăng lớp học', 'Coach có thể đăng thông báo, bài tập hoặc lịch học mới cho lớp này.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _createPostForClass,
                  icon: const Icon(Icons.post_add),
                  label: const Text('Tạo bài đăng cho lớp'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, String content) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8), Text(content)]),
      );
}
