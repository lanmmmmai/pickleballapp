import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
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
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      final response = await api.getMyClasses(token: token);
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

  Map<String, dynamic> _scheduleOf(Map<String, dynamic> klass) {
    final raw = klass['schedule']?.toString() ?? '';
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lớp học của tôi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = Map<String, dynamic>.from(items[index] as Map);
                    final klass = Map<String, dynamic>.from((item['class'] ?? item) as Map);
                    final schedule = _scheduleOf(klass);
                    final weekdays = (schedule['weekdays'] as List? ?? []).join(', ');
                    final coachName = klass['coach']?['name']?.toString() ?? 'Coach';

                    return Card(
                      child: ListTile(
                        title: Text(klass['title']?.toString() ?? ''),
                        subtitle: Text(
                          'Coach: $coachName\n${schedule['startDate'] ?? '-'} → ${schedule['endDate'] ?? '-'}\n$weekdays\n${schedule['sessionText'] ?? '-'} • ${schedule['note'] ?? 'Liên hệ'}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
