import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final api = ApiService();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool loading = true;
  bool saving = false;
  bool uploadingAvatar = false;
  bool uploadingCover = false;
  List<String> paymentMethods = [];
  String avatarUrl = '';
  String coverUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      final result = await api.getMyProfile(token: token);
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      nameController.text = (data['name'] ?? auth.userName ?? '').toString();
      emailController.text = (data['email'] ?? auth.email ?? '').toString();
      phoneController.text = (data['phone'] ?? auth.phone ?? '').toString();
      paymentMethods = List<String>.from((data['paymentMethods'] as List?)?.map((e) => e.toString()) ?? auth.paymentMethods);
      avatarUrl = api.absoluteFileUrl(data['avatarUrl']?.toString().isNotEmpty == true ? data['avatarUrl']?.toString() : auth.avatarUrl);
      coverUrl = api.absoluteFileUrl(data['coverUrl']?.toString().isNotEmpty == true ? data['coverUrl']?.toString() : auth.coverUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration deco(String label) => InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));

  Future<void> _pickAndUpload({required bool isCover}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp']);
    if (result == null || result.files.single.path == null) return;
    try {
      setState(() {
        if (isCover) {
          uploadingCover = true;
        } else {
          uploadingAvatar = true;
        }
      });
      final response = isCover
          ? await api.uploadMyCover(token: token, imageFile: File(result.files.single.path!))
          : await api.uploadMyAvatar(token: token, imageFile: File(result.files.single.path!));
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final resolvedAvatar = api.absoluteFileUrl(data['avatarUrl']?.toString().isNotEmpty == true ? data['avatarUrl']?.toString() : avatarUrl);
      final resolvedCover = api.absoluteFileUrl(data['coverUrl']?.toString().isNotEmpty == true ? data['coverUrl']?.toString() : coverUrl);
      auth.updateProfile(
        nameValue: data['name']?.toString() ?? nameController.text.trim(),
        phoneValue: data['phone']?.toString() ?? phoneController.text.trim(),
        paymentMethodsValue: List<String>.from((data['paymentMethods'] as List?)?.map((e) => e.toString()) ?? paymentMethods),
        avatarUrlValue: resolvedAvatar,
        coverUrlValue: resolvedCover,
      );
      if (!mounted) return;
      setState(() {
        avatarUrl = resolvedAvatar;
        coverUrl = resolvedCover;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCover ? 'Đã cập nhật ảnh bìa' : 'Đã cập nhật ảnh đại diện')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) {
        setState(() {
          uploadingAvatar = false;
          uploadingCover = false;
        });
      }
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
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => saving = true);
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      final result = await api.updateMyProfile(token: token, name: nameController.text.trim(), phone: phoneController.text.trim(), paymentMethods: paymentMethods);
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      auth.updateProfile(
        nameValue: (data['name'] ?? nameController.text.trim()).toString(),
        phoneValue: (data['phone'] ?? phoneController.text.trim()).toString(),
        paymentMethodsValue: List<String>.from((data['paymentMethods'] as List?)?.map((e) => e.toString()) ?? paymentMethods),
        avatarUrlValue: avatarUrl,
        coverUrlValue: coverUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> _addPaymentMethod() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.token!.isEmpty) return;
    final result = await Navigator.of(context).push<_PaymentMethodFlowResult>(
      MaterialPageRoute(
        builder: (_) => PaymentMethodOtpFullScreen(
          token: auth.token!,
          api: api,
        ),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || result == null) return;
    try {
      final nextMethods = paymentMethods.contains(result.label)
          ? paymentMethods
          : [...paymentMethods, result.label];
      setState(() => paymentMethods = nextMethods);
      final profileResult = await api.updateMyProfile(
        token: auth.token!,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        paymentMethods: nextMethods,
      );
      final profileData = Map<String, dynamic>.from(profileResult['data'] ?? {});
      final syncedMethods = List<String>.from(
        (profileData['paymentMethods'] as List?)?.map((e) => e.toString()) ?? nextMethods,
      );
      setState(() => paymentMethods = syncedMethods);
      auth.updateProfile(
        nameValue: (profileData['name'] ?? nameController.text.trim()).toString(),
        phoneValue: (profileData['phone'] ?? phoneController.text.trim()).toString(),
        paymentMethodsValue: syncedMethods,
        avatarUrlValue: avatarUrl,
        coverUrlValue: coverUrl,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm phương thức thanh toán thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() { nameController.dispose(); emailController.dispose(); phoneController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : (auth.userName ?? 'Bạn');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tài khoản & thông tin cá nhân'), backgroundColor: AppColors.background),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: coverUrl.isEmpty ? null : () => _previewImage(coverUrl, 'Ảnh bìa'),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        child: SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: coverUrl.isNotEmpty
                              ? Image.network(coverUrl, fit: BoxFit.cover)
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary, Color(0xFF24C27F), Color(0xFF64D2FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: ElevatedButton.icon(
                        onPressed: uploadingCover ? null : () => _pickAndUpload(isCover: true),
                        icon: uploadingCover ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.photo_camera_outlined),
                        label: const Text('Đổi ảnh bìa'),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      bottom: -34,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: avatarUrl.isEmpty ? null : () => _previewImage(avatarUrl, 'Ảnh đại diện'),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl.isEmpty ? Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary)) : null,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: uploadingAvatar ? null : () => _pickAndUpload(isCover: false),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: uploadingAvatar ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Tài khoản hiện tại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text(emailController.text.isEmpty ? 'Chưa có email' : emailController.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Bạn có thể cập nhật hồ sơ, ảnh đại diện, ảnh bìa và thêm phương thức thanh toán đã xác thực OTP trước khi dùng khi đặt sân.'),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: nameController, decoration: deco('Họ và tên')),
          const SizedBox(height: 16),
          TextField(controller: emailController, readOnly: true, decoration: deco('Email')),
          const SizedBox(height: 16),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: deco('Số điện thoại')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Phương thức thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ElevatedButton.icon(onPressed: _addPaymentMethod, icon: const Icon(Icons.add), label: const Text('Thêm')),
              ]),
              const SizedBox(height: 8),
              if (paymentMethods.isEmpty) const Text('Chưa có phương thức nào') else ...paymentMethods.map((m) => ListTile(contentPadding: EdgeInsets.zero, title: Text(m), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => paymentMethods.remove(m))))),
            ]),
          ),
          const SizedBox(height: 28),
          ElevatedButton(onPressed: saving ? null : _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4)) : const Text('Lưu thay đổi')),
        ],
      ),
    );
  }
}


class _PaymentMethodFlowResult {
  final String label;
  const _PaymentMethodFlowResult({required this.label});
}

class PaymentMethodOtpFullScreen extends StatefulWidget {
  final String token;
  final ApiService api;
  const PaymentMethodOtpFullScreen({super.key, required this.token, required this.api});

  @override
  State<PaymentMethodOtpFullScreen> createState() => _PaymentMethodOtpFullScreenState();
}

class _PaymentMethodOtpFullScreenState extends State<PaymentMethodOtpFullScreen> {
  final accountCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final List<String> methods = const ['Chuyển khoản QR', 'MoMo', 'ZaloPay'];
  String method = 'Chuyển khoản QR';
  String requestId = '';
  String sentTo = '';
  String helperMessage = 'Mã OTP sẽ gửi về Gmail của tài khoản này. Xác thực xong mới dùng được ở màn đặt sân.';
  bool requestingOtp = false;
  bool verifyingOtp = false;
  bool resendLoading = false;

  bool get isOtpStep => requestId.isNotEmpty;

  Future<void> _sendOtp({bool isResend = false}) async {
    final account = accountCtrl.text.trim();
    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tài khoản / số ví')),
      );
      return;
    }
    try {
      setState(() {
        if (isResend) {
          resendLoading = true;
        } else {
          requestingOtp = true;
        }
      });
      final result = await widget.api.requestPaymentMethodOtp(
        token: widget.token,
        method: method,
        account: account,
      );
      final debugOtp = (result['debugOtp'] ?? '').toString();
      final message = (result['message'] ?? 'Đã gửi OTP về Gmail').toString();
      setState(() {
        requestId = (result['requestId'] ?? '').toString();
        sentTo = account;
        helperMessage = debugOtp.isEmpty ? message : '$message · OTP test: $debugOtp';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(helperMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          requestingOtp = false;
          resendLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = otpCtrl.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP')),
      );
      return;
    }
    try {
      setState(() => verifyingOtp = true);
      final result = await widget.api.verifyPaymentMethodOtp(
        token: widget.token,
        requestId: requestId,
        otp: otp,
      );
      final methodLabel = (result['label'] ?? '$method • ${accountCtrl.text.trim()}').toString();
      if (!mounted) return;
      Navigator.pop(context, _PaymentMethodFlowResult(label: methodLabel));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => verifyingOtp = false);
    }
  }

  @override
  void dispose() {
    accountCtrl.dispose();
    otpCtrl.dispose();
    super.dispose();
  }

  Widget _buildStepChip({required int number, required String label, required bool active, required bool done}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done || active ? AppColors.primary : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: done || active ? AppColors.primary : Colors.black12,
              child: Text(
                done ? '✓' : '$number',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active || done ? AppColors.primary : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Xác thực phương thức thanh toán'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _buildStepChip(number: 1, label: 'Thông tin', active: !isOtpStep, done: isOtpStep),
                  const SizedBox(width: 10),
                  _buildStepChip(number: 2, label: 'Nhập OTP', active: isOtpStep, done: false),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOtpStep ? 'Nhập mã OTP' : 'Thêm phương thức thanh toán',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isOtpStep
                              ? 'Mã xác thực đã được gửi về Gmail của tài khoản. Nhập đúng 6 số để kích hoạt phương thức thanh toán.'
                              : 'Điền thông tin phương thức bạn muốn dùng khi thanh toán đặt sân.',
                          style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.45),
                        ),
                        const SizedBox(height: 24),
                        if (!isOtpStep) ...[
                          DropdownButtonFormField<String>(
                            initialValue: method,
                            decoration: InputDecoration(
                              labelText: 'Phương thức',
                              filled: true,
                              fillColor: const Color(0xFFF5F7F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: methods
                                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                .toList(),
                            onChanged: (value) => setState(() => method = value ?? methods.first),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: accountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: method == 'Chuyển khoản QR' ? 'Số tài khoản' : 'Số ví',
                              hintText: method == 'Chuyển khoản QR' ? 'Nhập số tài khoản ngân hàng' : 'Nhập số ví điện tử',
                              filled: true,
                              fillColor: const Color(0xFFF5F7F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Sau khi bấm gửi OTP, hệ thống sẽ chuyển sang màn nhập mã để bạn xác thực ngay.',
                                    style: TextStyle(fontSize: 13.5, height: 1.45, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        method,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Tài khoản / ví: $sentTo', style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 8),
                                Text(helperMessage, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.45)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Mã OTP 6 số',
                              hintText: 'Nhập mã OTP',
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF5F7F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: resendLoading ? null : () => _sendOtp(isResend: true),
                                icon: resendLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh),
                                label: const Text('Gửi lại OTP'),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    requestId = '';
                                    otpCtrl.clear();
                                  });
                                },
                                child: const Text('Quay lại'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: requestingOtp || verifyingOtp
                          ? null
                          : (isOtpStep ? _verifyOtp : _sendOtp),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: requestingOtp || verifyingOtp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(isOtpStep ? 'Xác thực và lưu' : 'Gửi OTP'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
