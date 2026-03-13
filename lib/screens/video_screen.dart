import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> videos = [];
  bool loading = true;
  String? errorMessage;
  VideoPlayerController? _playerController;
  Timer? _progressTicker;
  int currentIndex = 0;
  bool _showPlayOverlay = false;
  double _videoProgress = 0;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  @override
  void dispose() {
    _progressTicker?.cancel();
    _searchController.dispose();
    _commentController.dispose();
    _pageController.dispose();
    _disposePlayer();
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    _progressTicker?.cancel();
    try {
      await _playerController?.pause();
      await _playerController?.dispose();
    } catch (_) {}
    _playerController = null;
    _videoProgress = 0;
  }

  void _startTicker() {
    _progressTicker?.cancel();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final ctrl = _playerController;
      if (!mounted || ctrl == null || !ctrl.value.isInitialized) return;
      final duration = ctrl.value.duration.inMilliseconds;
      final position = ctrl.value.position.inMilliseconds;
      if (duration <= 0) return;
      setState(() => _videoProgress = (position / duration).clamp(0.0, 1.0));
    });
  }

  Future<void> fetchVideos({String query = ''}) async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });
      final response = await apiService.getVideos(query: query);
      setState(() {
        videos = List<dynamic>.from(response);
        currentIndex = 0;
      });
      await _setupPlayer();
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setupPlayer() async {
    await _disposePlayer();
    if (videos.isEmpty || currentIndex >= videos.length) return;
    final item = Map<String, dynamic>.from(videos[currentIndex] as Map);
    final fileUrl = apiService.absoluteFileUrl(item['fileUrl']?.toString());
    if (fileUrl.isEmpty) return;
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(fileUrl));
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
      await apiService.viewVideo(id: int.tryParse('${item['id']}') ?? 0);
      if (!mounted) return;
      _playerController = ctrl;
      _videoProgress = 0;
      _startTicker();
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Video chưa sẵn sàng hoặc đường dẫn tệp không đúng.');
    }
  }

  Future<void> _togglePlayPause() async {
    final ctrl = _playerController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isPlaying) {
      await ctrl.pause();
      setState(() => _showPlayOverlay = true);
    } else {
      await ctrl.play();
      setState(() => _showPlayOverlay = false);
    }
  }

  Future<void> _showAddVideoDialog() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để thêm video')));
      return;
    }
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String mode = 'FILE';
    File? selectedFile;
    File? selectedThumb;
    final urlCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Thêm video'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên video')),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Nội dung')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  items: const [
                    DropdownMenuItem(value: 'FILE', child: Text('Chọn tệp từ máy')),
                    DropdownMenuItem(value: 'YOUTUBE', child: Text('Dùng link YouTube')),
                  ],
                  onChanged: (value) => setStateDialog(() => mode = value ?? 'FILE'),
                ),
                const SizedBox(height: 12),
                if (mode == 'FILE')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.video);
                          if (result != null && result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            final thumbPath = await VideoThumbnail.thumbnailFile(video: file.path, imageFormat: ImageFormat.PNG, quality: 75);
                            setStateDialog(() {
                              selectedFile = file;
                              selectedThumb = thumbPath != null ? File(thumbPath) : null;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Chọn video'),
                      ),
                      const SizedBox(height: 8),
                      Text(selectedFile?.path.split('/').last ?? 'Chưa chọn tệp'),
                    ],
                  )
                else
                  TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Link video / YouTube')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (mode == 'FILE') {
                    if (selectedFile == null) throw Exception('Bạn chưa chọn tệp video');
                    await apiService.uploadVideoFile(
                      token: auth.token!,
                      title: titleCtrl.text.trim(),
                      description: contentCtrl.text.trim(),
                      videoFile: selectedFile!,
                      thumbnailFile: selectedThumb,
                    );
                  } else {
                    await apiService.createVideo(
                      token: auth.token!,
                      title: titleCtrl.text.trim(),
                      description: contentCtrl.text.trim(),
                      videoUrl: urlCtrl.text.trim(),
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  fetchVideos();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: const Text('Đăng video'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.token == null || videos.isEmpty) return;
    final id = int.tryParse('${videos[currentIndex]['id']}') ?? 0;
    final updated = await apiService.likeVideo(token: auth.token!, id: id);
    if (!mounted) return;
    setState(() => videos[currentIndex] = updated);
  }

  Future<void> _toggleSave() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.token == null || videos.isEmpty) return;
    final id = int.tryParse('${videos[currentIndex]['id']}') ?? 0;
    final updated = await apiService.saveVideo(token: auth.token!, id: id);
    if (!mounted) return;
    setState(() => videos[currentIndex] = updated);
  }

  Future<void> _showComments() async {
    if (videos.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final id = int.tryParse('${videos[currentIndex]['id']}') ?? 0;
    final detail = await apiService.getVideoById(id);
    if (!mounted) return;
    List<dynamic> comments = List<dynamic>.from(detail['comments'] ?? []);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.72,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 12),
                  const Text('Bình luận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = Map<String, dynamic>.from(comments[i] as Map);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Text((c['user']?['name']?.toString() ?? 'U')[0].toUpperCase()),
                          ),
                          title: Text(c['user']?['name']?.toString() ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(c['content']?.toString() ?? '', style: const TextStyle(fontSize: 13, height: 1.35)),
                        );
                      },
                    ),
                  ),
                  if (auth.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Viết bình luận...'))),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              if (_commentController.text.trim().isEmpty) return;
                              final updated = await apiService.commentVideo(token: auth.token!, id: id, content: _commentController.text.trim());
                              comments = List<dynamic>.from(updated['comments'] ?? []);
                              setModal(() {});
                              _commentController.clear();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() => Positioned(
        top: 16,
        left: 16,
        right: 78,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (query) => fetchVideos(query: query),
          decoration: InputDecoration(
            hintText: 'Tìm video...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) => Column(
        children: [
          IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white, size: 34)),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildRightActions(Map<String, dynamic> item) => Positioned(
        right: 12,
        bottom: 120,
        child: Column(
          children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Text((item['creator']?['name']?.toString() ?? 'T')[0].toUpperCase())),
            const SizedBox(height: 18),
            _actionButton(item['liked'] == true ? Icons.favorite : Icons.favorite_border, '${item['likesCount'] ?? 0}', _toggleLike),
            const SizedBox(height: 16),
            _actionButton(Icons.mode_comment_outlined, '${item['commentsCount'] ?? 0}', _showComments),
            const SizedBox(height: 16),
            _actionButton(item['saved'] == true ? Icons.bookmark : Icons.bookmark_border, '${item['savesCount'] ?? 0}', _toggleSave),
            const SizedBox(height: 16),
            _actionButton(Icons.visibility_outlined, '${item['viewsCount'] ?? 0}', () {}),
          ],
        ),
      );

  Widget _buildBottomInfo(Map<String, dynamic> item) => Positioned(
        left: 16,
        right: 90,
        bottom: 34,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['creator']?['name']?.toString() ?? 'Tây Mỗ Club', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(item['title']?.toString() ?? 'Video', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 6),
            Text(item['description']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.35)),
          ],
        ),
      );

  Widget _buildProgressBar() => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: LinearProgressIndicator(
          minHeight: 2.5,
          value: _videoProgress,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );

  Widget _buildVideoLayer(Map<String, dynamic> item, bool isCurrent) {
    final fileUrl = apiService.absoluteFileUrl(item['fileUrl']?.toString());
    final thumb = apiService.absoluteFileUrl(item['thumbnailUrl']?.toString());
    final youtubeUrl = item['videoUrl']?.toString() ?? '';
    if (fileUrl.isNotEmpty && isCurrent && _playerController != null && _playerController!.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _playerController!.value.size.width,
                height: _playerController!.value.size.height,
                child: VideoPlayer(_playerController!),
              ),
            ),
            if (_showPlayOverlay || !_playerController!.value.isPlaying)
              const Center(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0x55000000),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 38),
                ),
              ),
          ],
        ),
      );
    }
    if (thumb.isNotEmpty) {
      return GestureDetector(
        onTap: youtubeUrl.isNotEmpty ? () => _openExternal(youtubeUrl) : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: Colors.black54)),
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.black45,
                child: Icon(youtubeUrl.isEmpty ? Icons.videocam_off : Icons.play_arrow, color: Colors.white, size: 38),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: youtubeUrl.isEmpty ? null : () => _openExternal(youtubeUrl),
        icon: const Icon(Icons.play_circle_fill),
        label: Text(youtubeUrl.isEmpty ? 'Video chưa sẵn sàng' : 'Mở video'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (errorMessage != null && videos.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Video')), body: Center(child: Text(errorMessage!)));
    if (videos.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Video')), body: const Center(child: Text('Chưa có video phù hợp')));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) async {
              setState(() {
                currentIndex = index;
                _showPlayOverlay = false;
              });
              await _setupPlayer();
            },
            itemBuilder: (context, index) {
              final item = Map<String, dynamic>.from(videos[index] as Map);
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoLayer(item, index == currentIndex),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0x00000000), Color(0xAA000000)],
                      ),
                    ),
                  ),
                  _buildSearch(),
                  _buildRightActions(item),
                  _buildBottomInfo(item),
                  _buildProgressBar(),
                ],
              );
            },
          ),
          Positioned(
            top: 26,
            right: 18,
            child: SafeArea(
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                onPressed: _showAddVideoDialog,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
