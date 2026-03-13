import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chatbot_screen.dart';
import 'login_screen.dart';
import 'profile_detail_screen.dart';
import 'register_screen.dart';
import 'coin_task_screen.dart';
import 'booking_history_screen.dart';
import 'my_classes_screen.dart';
import 'settings_screen.dart';
import 'coach_manage_classes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final api = ApiService();
  bool uploadingAvatar = false;
  bool uploadingCover = false;

  Future<void> _uploadAvatar() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đổi ảnh đại diện')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      setState(() => uploadingAvatar = true);
      final response = await api.uploadMyAvatar(
        token: auth.token!,
        imageFile: File(result.files.single.path!),
      );
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final avatarUrl = api.absoluteFileUrl(data['avatarUrl']?.toString());
      auth.updateProfile(
        nameValue: data['name']?.toString() ?? (auth.userName ?? ''),
        phoneValue: data['phone']?.toString() ?? (auth.phone ?? ''),
        paymentMethodsValue: List<String>.from(
          (data['paymentMethods'] as List?)?.map((e) => e.toString()) ??
              auth.paymentMethods,
        ),
        avatarUrlValue: avatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }


  Future<void> _uploadCover() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đổi ảnh bìa')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      setState(() => uploadingCover = true);
      final response = await api.uploadMyCover(
        token: auth.token!,
        imageFile: File(result.files.single.path!),
      );
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final coverUrl = api.absoluteFileUrl(data['coverUrl']?.toString());
      auth.updateProfile(
        nameValue: data['name']?.toString() ?? (auth.userName ?? ''),
        phoneValue: data['phone']?.toString() ?? (auth.phone ?? ''),
        paymentMethodsValue: List<String>.from(
          (data['paymentMethods'] as List?)?.map((e) => e.toString()) ?? auth.paymentMethods,
        ),
        avatarUrlValue: api.absoluteFileUrl(data['avatarUrl']?.toString()),
        coverUrlValue: coverUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh bìa')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => uploadingCover = false);
    }
  }

  Future<void> _previewImage(String url, String title) async {
    if (url.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
            Positioned(
              top: 20,
              right: 16,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 20,
              child: SafeArea(
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthProvider auth, {double radius = 40}) {
    final name = (auth.userName ?? auth.email ?? 'Người dùng').trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final avatarUrl = api.absoluteFileUrl(auth.avatarUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItem({required BuildContext context, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildFacebookStyleHeader(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 6),
            color: Color(0x16000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 118,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              gradient: (api.absoluteFileUrl(auth.coverUrl).isEmpty) ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFF24C27F), Color(0xFF64D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              image: api.absoluteFileUrl(auth.coverUrl).isNotEmpty ? DecorationImage(image: NetworkImage(api.absoluteFileUrl(auth.coverUrl)), fit: BoxFit.cover) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 18,
                  top: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Trang cá nhân',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: ElevatedButton.icon(
                    onPressed: uploadingCover ? null : _uploadCover,
                    icon: uploadingCover ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.photo_camera_outlined, size: 16),
                    label: const Text('Đổi ảnh bìa'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.88), foregroundColor: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -34),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: GestureDetector(onTap: () => _previewImage(api.absoluteFileUrl(auth.avatarUrl), 'Ảnh đại diện'), child: _buildAvatar(auth, radius: 42)),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: uploadingAvatar ? null : _uploadAvatar,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: uploadingAvatar
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  auth.isLoggedIn ? (auth.userName ?? 'Người dùng Tây Mỗ') : 'Khách',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.isLoggedIn
                      ? (auth.email ?? 'Thành viên câu lạc bộ')
                      : 'Vui lòng đăng nhập để sử dụng đầy đủ tính năng',
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: auth.isLoggedIn
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileDetailScreen(),
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Sửa hồ sơ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploadingAvatar ? null : _uploadAvatar,
                          icon: const Icon(Icons.photo_camera_back_outlined),
                          label: const Text('Đổi avatar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFacebookStyleHeader(auth),
          const SizedBox(height: 18),
          if (!auth.isLoggedIn) ...[
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Đăng ký tài khoản'),
            ),
            const SizedBox(height: 18),
          ],
          _buildMenuItem(
            context: context,
            icon: Icons.person_outline,
            title: 'Thông tin cá nhân',
            subtitle: 'Xem và cập nhật hồ sơ cá nhân',
            onTap: () {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập để xem thông tin cá nhân')),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileDetailScreen()));
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.history,
            title: 'Lịch sử đặt sân',
            subtitle: 'Theo dõi các lịch đặt trước đó',
            onTap: () {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập trước')),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.monetization_on_outlined,
            title: 'Ví ưu đãi',
            subtitle: 'Quản lý coin, voucher và ưu đãi của bạn',
            onTap: () {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập trước')),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinTaskScreen()));
            },
          ),
          if (auth.role == 'COACH') ...[
            _buildMenuItem(
              context: context,
              icon: Icons.class_,
              title: 'Lớp học của tôi',
              subtitle: 'Xem lớp học và học viên của bạn',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyClassesScreen()),
              ),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.edit_note,
              title: 'Quản lý lớp học',
              subtitle: 'Thêm, sửa và xóa lớp học của coach',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CoachManageClassesScreen()),
              ),
            ),
          ],
          _buildMenuItem(
            context: context,
            icon: Icons.support_agent,
            title: 'Hỗ trợ & Chatbot',
            subtitle: 'Hỏi đáp nhanh với AI và bộ phận hỗ trợ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            ),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            subtitle: 'Thông báo, bảo mật và tùy chọn ứng dụng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đăng xuất')),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
