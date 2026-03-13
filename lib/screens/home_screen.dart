
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chatbot_screen.dart';
import 'video_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'products_screen.dart';
import 'classes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  int currentIndex = 0;
  bool postsLoading = true;
  String? postsError;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        postsLoading = true;
        postsError = null;
      });
      final result = await api.getPosts();
      setState(() {
        posts = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      setState(() {
        postsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => postsLoading = false);
    }
  }

  void _openChatbot(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  String _timeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return 'Vừa xong';
    final d = DateTime.tryParse(raw);
    if (d == null) return 'Vừa xong';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    return '${diff.inDays} ngày';
  }

  Future<void> _showCreatePostSheet() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đăng bài')));
      return;
    }
    final contentCtrl = TextEditingController();
    final hashtagCtrl = TextEditingController();
    File? mediaFile;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tạo bài đăng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(hintText: 'Bạn đang nghĩ gì?', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: hashtagCtrl, decoration: const InputDecoration(hintText: '#pickleball #giaoluu', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','mp4','mov','m4v']);
                            if (result != null && result.files.single.path != null) {
                              setModal(() => mediaFile = File(result.files.single.path!));
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Chọn ảnh/video'),
                        ),
                        const SizedBox(width: 12),
                        if (mediaFile != null) Expanded(child: Text(mediaFile!.path.split('/').last, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await api.createPost(
                              token: auth.token!,
                              content: contentCtrl.text.trim(),
                              hashtags: hashtagCtrl.text.trim(),
                              mediaFile: mediaFile,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Đăng bài thành công')));
                            _loadPosts();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                          }
                        },
                        child: const Text('Đăng bài'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _commentDialog(Map<String, dynamic> post) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }
    final ctrl = TextEditingController();
    List<Map<String, dynamic>> comments = (post['comments'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
          ),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.72,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bình luận',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(child: Text('Chưa có bình luận nào'))
                        : ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final c = comments[index];
                              final author = c['authorName']?.toString() ?? 'Thành viên';
                              final content = c['content']?.toString() ?? '';
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAvatar(author, radius: 14, avatarUrl: c['authorAvatarUrl']?.toString()),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F5F7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            author,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            content,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              height: 1.3,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Viết bình luận...',
                            filled: true,
                            fillColor: const Color(0xFFF5F6F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (ctrl.text.trim().isEmpty) return;
                          try {
                            final updated = await api.commentPost(
                              token: auth.token!,
                              id: int.tryParse('${post['id']}') ?? 0,
                              content: ctrl.text.trim(),
                            );
                            if (!mounted) return;
                            comments = (updated['comments'] as List? ?? [])
                                .map((e) => Map<String, dynamic>.from(e as Map))
                                .toList();
                            setState(() {
                              final idx = posts.indexWhere((p) => p['id'] == post['id']);
                              if (idx >= 0) posts[idx] = Map<String, dynamic>.from(updated);
                            });
                            ctrl.clear();
                            setModal(() {});
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Gửi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {double radius = 22, String? avatarUrl}) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'T';
    final resolvedUrl = api.absoluteFileUrl(avatarUrl);
    if (resolvedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(resolvedUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  Future<void> _openImagePreview(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.9,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 18,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final auth = context.read<AuthProvider>();
    final comments = (post['comments'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final mediaUrl = api.absoluteFileUrl(post['mediaUrl']?.toString());
    final mediaType = post['mediaType']?.toString() ?? '';
    final authorName = post['authorName']?.toString() ?? 'Thành viên';
    final authorAvatarUrl = post['authorAvatarUrl']?.toString();
    final role = post['authorRole']?.toString() ?? 'USER';
    final content = post['content']?.toString() ?? '';
    final hashtags = (post['hashtags'] as List? ?? [])
        .map((e) => e.toString().replaceFirst('#', ''))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(authorName, avatarUrl: authorAvatarUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${_timeAgo(post['createdAt']?.toString())} · $role',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black87,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: hashtags
                    .map(
                      (e) => Text(
                        '#$e',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (mediaUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: mediaType == 'video'
                    ? Container(
                        height: 168,
                        width: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 62,
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Text(
                                'Video đã tải lên',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _openImagePreview(mediaUrl),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            width: double.infinity,
                            color: const Color(0xFFF6F7F9),
                            child: Image.network(
                              mediaUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${post['likeCount'] ?? 0} lượt thích',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                Text(
                  '${post['commentCount'] ?? 0} bình luận · ${post['shareCount'] ?? 0} chia sẻ',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: post['liked'] == true ? Icons.favorite : Icons.favorite_border,
                    label: 'Thích',
                    active: post['liked'] == true,
                    onTap: () async {
                      if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng đăng nhập để thích bài')),
                        );
                        return;
                      }
                      final updated = await api.likePost(
                        token: auth.token!,
                        id: int.tryParse('${post['id']}') ?? 0,
                      );
                      if (!mounted) return;
                      setState(() {
                        final idx = posts.indexWhere((p) => p['id'] == post['id']);
                        if (idx >= 0) posts[idx] = updated;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _actionButton(
                    icon: Icons.mode_comment_outlined,
                    label: 'Bình luận',
                    onTap: () => _commentDialog(post),
                  ),
                ),
                Expanded(
                  child: _actionButton(
                    icon: post['saved'] == true ? Icons.bookmark : Icons.bookmark_border,
                    label: 'Lưu',
                    active: post['saved'] == true,
                    onTap: () async {
                      if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng đăng nhập để lưu bài')),
                        );
                        return;
                      }
                      final updated = await api.savePost(
                        token: auth.token!,
                        id: int.tryParse('${post['id']}') ?? 0,
                      );
                      if (!mounted) return;
                      setState(() {
                        final idx = posts.indexWhere((p) => p['id'] == post['id']);
                        if (idx >= 0) posts[idx] = updated;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _actionButton(
                    icon: Icons.share_outlined,
                    label: 'Chia sẻ',
                    onTap: () async {
                      if (!auth.isLoggedIn || (auth.token?.isEmpty ?? true)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng đăng nhập để chia sẻ')),
                        );
                        return;
                      }
                      final updated = await api.sharePost(
                        token: auth.token!,
                        id: int.tryParse('${post['id']}') ?? 0,
                      );
                      if (!mounted) return;
                      setState(() {
                        final idx = posts.indexWhere((p) => p['id'] == post['id']);
                        if (idx >= 0) posts[idx] = updated;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chia sẻ bài viết')),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...comments.take(2).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(c['authorName']?.toString() ?? 'Thành viên', radius: 10, avatarUrl: c['authorAvatarUrl']?.toString()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['authorName']?.toString() ?? 'Thành viên',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c['content']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (comments.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: InkWell(
                    onTap: () => _commentDialog(post),
                    child: Text(
                      'Xem tất cả ${comments.length} bình luận',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, bool active = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 20, color: active ? Colors.red : Colors.grey.shade700),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }


  Widget _buildComposerCard() {
    final auth = context.read<AuthProvider>();
    final name = (auth.userName ?? auth.email ?? 'Bạn').trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(name, radius: 20, avatarUrl: auth.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _showCreatePostSheet,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Bạn đang nghĩ gì về buổi chơi hôm nay?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _showCreatePostSheet,
                  icon: const Icon(Icons.image_outlined, color: Colors.green),
                  label: const Text('Ảnh / Video', style: TextStyle(color: Colors.black87)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _showCreatePostSheet,
                  icon: const Icon(Icons.edit_note, color: AppColors.primary),
                  label: const Text('Viết bài', style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadPosts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF13A96B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tây Mỗ Pickleball Club',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Đặt sân nhanh, xem video hướng dẫn, nhận thông báo ưu đãi và tham gia cộng đồng pickleball.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Mở cửa: 06:00 - 22:00',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Tiện ích nhanh'),
              const SizedBox(height: 12),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildQuickAction(
                    icon: Icons.calendar_month,
                    label: 'Đặt sân',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProductsScreen()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.play_circle_fill,
                    label: 'Video',
                    onTap: () {
                      setState(() => currentIndex = 1);
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.notifications,
                    label: 'Thông báo',
                    onTap: () {
                      setState(() => currentIndex = 2);
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.class_,
                    label: 'Lớp học',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClassesScreen()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.smart_toy,
                    label: 'Chat AI',
                    onTap: () => _openChatbot(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildComposerCard(),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Bảng tin cộng đồng'),
                  TextButton.icon(onPressed: _loadPosts, icon: const Icon(Icons.refresh, size: 18), label: const Text('Tải lại')),
                ],
              ),
              const SizedBox(height: 8),
              if (postsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (postsError != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Text(postsError!),
                )
              else if (posts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Chưa có bài đăng nào. Hãy là người đầu tiên chia sẻ khoảnh khắc pickleball của bạn!', style: TextStyle(fontSize: 13, height: 1.4)),
                )
              else
                ...posts.map(_postCard),
              const SizedBox(height: 100),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: FloatingActionButton.extended(
            elevation: 4,
            onPressed: _showCreatePostSheet,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
            label: const Text('Tạo bài viết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      AppConfig.appName,
      'Video',
      'Thông báo',
      'Tài khoản',
    ];

    final pages = [
      _buildHomeTab(),
      const VideoScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        backgroundColor: AppColors.background,
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
