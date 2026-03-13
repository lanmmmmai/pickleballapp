import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/api.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Xin chào, tôi là trợ lý AI của Tây Mỗ Pickleball Club. Bạn có thể hỏi về đặt sân, huấn luyện viên, video hoặc ưu đãi.',
      isUser: false,
    ),
  ];

  bool _isSending = false;

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;

    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _isSending = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/chatbot/ask');

      print('CHATBOT URL: $url');
      print('CHATBOT TOKEN: ${token ?? "NULL"}');
      print('CHATBOT QUESTION: $question');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'question': question,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('CHATBOT STATUS: ${response.statusCode}');
      print('CHATBOT BODY: ${response.body}');

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        String answer = body['data']?['answer'] ?? 'Tôi chưa có câu trả lời phù hợp.';
        if (answer.toLowerCase().contains('knowledge base chưa được load')) {
          answer = 'CLB mở cửa từ 06:00 đến 22:00 mỗi ngày. Bạn có thể hỏi về đặt sân, giá sân, video, voucher hoặc lớp học.';
        }

        setState(() {
          _messages.add(ChatMessage(text: answer, isUser: false));
        });
      } else {
        String message = body['message'] ?? 'Hiện chưa kết nối được chatbot backend.';
        if (message.toLowerCase().contains('knowledge base chưa được load')) {
          message = 'CLB mở cửa từ 06:00 đến 22:00 mỗi ngày. Bạn có thể hỏi về đặt sân, giá sân, video, voucher hoặc lớp học.';
        }
        setState(() {
          _messages.add(ChatMessage(text: message, isUser: false));
        });
      }
    } catch (e) {
      print('CHATBOT ERROR: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Không thể kết nối chatbot. Kiểm tra lại backend hoặc token đăng nhập.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 3),
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textDark,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Hỏi về sân, coach, voucher...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_isSending) _sendMessage();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _isSending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}