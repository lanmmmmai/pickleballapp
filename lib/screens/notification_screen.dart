import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> notifications = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final token = context.read<AuthProvider>().token;
      final response = await apiService.getNotifications(token: token).timeout(
            const Duration(seconds: 12),
          );

      setState(() {
        notifications = List<dynamic>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Không tải được thông báo';
        loading = false;
      });
    }
  }

  Widget _buildTopCard() {
    final auth = context.watch<AuthProvider>();
    final name = (auth.userName ?? '').trim();
    final email = (auth.email ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1AB06E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông báo theo tài khoản',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? 'Bạn đang xem thông báo của tài khoản hiện tại.' : 'Bạn đang xem thông báo của $name.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: fetchNotifications,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    } else if (notifications.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopCard(),
          const SizedBox(height: 16),
          const Text('Chưa có thông báo nào cho tài khoản này'),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: fetchNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTopCard(),
              );
            }

            final item = Map<String, dynamic>.from(notifications[index - 1] as Map);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NotificationTile(
                title: item['title']?.toString() ?? '',
                content: item['content']?.toString() ?? '',
                type: item['type']?.toString(),
                createdAt: item['createdAt']?.toString(),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(body: body);
  }
}
