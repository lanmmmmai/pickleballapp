import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.notifications_none,
            title: 'Thông báo',
            subtitle: 'Bật tắt thông báo đặt sân, lớp học và bài đăng',
            page: const _SettingsDetailPage(
              title: 'Thông báo',
              items: [
                'Thông báo đặt sân',
                'Thông báo lớp học',
                'Thông báo bình luận và lượt thích',
                'Thông báo ưu đãi và voucher',
              ],
            ),
          ),
          _tile(
            context,
            icon: Icons.lock_outline,
            title: 'Bảo mật',
            subtitle: 'Đổi mật khẩu, xác thực OTP và phiên đăng nhập',
            page: const _SettingsDetailPage(
              title: 'Bảo mật',
              items: [
                'Đổi mật khẩu',
                'Xác thực OTP khi thanh toán',
                'Thiết bị đã đăng nhập',
                'Đăng xuất khỏi thiết bị khác',
              ],
            ),
          ),
          _tile(
            context,
            icon: Icons.palette_outlined,
            title: 'Giao diện',
            subtitle: 'Màu sắc, kích thước chữ và hiển thị',
            page: const _SettingsDetailPage(
              title: 'Giao diện',
              items: [
                'Chế độ sáng',
                'Cỡ chữ bình thường',
                'Bo góc thẻ thông tin',
                'Hiển thị kiểu TikTok cho video',
              ],
            ),
          ),
          _tile(
            context,
            icon: Icons.info_outline,
            title: 'Phiên bản ứng dụng',
            subtitle: 'Thông tin ứng dụng và liên hệ hỗ trợ',
            page: const _SettingsDetailPage(
              title: 'Phiên bản ứng dụng',
              items: [
                'Tây Mỗ Pickleball Club',
                'Phiên bản 1.0.0',
                'Hỗ trợ: support@taymopickleball.local',
                'Bản build dành cho đồ án',
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SettingsDetailPage({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(items[index]),
        ),
      ),
    );
  }
}
