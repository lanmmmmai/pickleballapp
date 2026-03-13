import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class ApiService {
  String get serverBase => ApiConstants.baseUrl.replaceAll('/api', '');

  String absoluteFileUrl(String? path) {
    final p = (path ?? '').trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    return p.startsWith('/') ? '$serverBase$p' : '$serverBase/$p';
  }

  Future<List<dynamic>> getCourts() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/courts'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Failed to load courts');
  }

  Future<List<dynamic>> getProducts({String? type}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/products${type != null ? '?type=$type' : ''}');
    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được sản phẩm');
  }

  Future<List<dynamic>> getVouchers() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/vouchers'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được voucher');
  }

  Future<Map<String, dynamic>> createBooking({
    required String token,
    required int courtId,
    required String bookingDate,
    required String startTime,
    required String endTime,
    required double totalPrice,
    String? paymentMethod,
    String? voucherCode,
    List<Map<String, dynamic>> extras = const [],
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/bookings'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'courtId': courtId,
        'bookingDate': bookingDate,
        'startTime': startTime,
        'endTime': endTime,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'voucherCode': voucherCode,
        'extras': extras,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Đặt sân thất bại');
  }

  Future<List<dynamic>> getMyBookings({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/bookings/me'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được lịch sử đặt sân');
  }

  Future<Map<String, dynamic>> getBookingById({required String token, required int id}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/bookings/$id'), headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không tải được booking');
  }

  Future<Map<String, dynamic>> getMyProfile({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/users/me'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Không tải được thông tin cá nhân');
  }

  Future<Map<String, dynamic>> updateMyProfile({required String token, required String name, required String phone, required List<String> paymentMethods}) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/users/me'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name, 'phone': phone, 'paymentMethods': paymentMethods}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Cập nhật thông tin thất bại');
  }


  Future<Map<String, dynamic>> uploadMyAvatar({required String token, required File imageFile}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/users/me/avatar'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Không cập nhật được ảnh đại diện');
  }

  Future<Map<String, dynamic>> uploadMyCover({required String token, required File imageFile}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/users/me/cover'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('cover', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Không cập nhật được ảnh bìa');
  }

  Future<Map<String, dynamic>> requestPaymentMethodOtp({required String token, required String method, required String account}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/me/payment-method-otp/request'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'method': method, 'account': account}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không gửi được OTP');
  }

  Future<Map<String, dynamic>> verifyPaymentMethodOtp({required String token, required String requestId, required String otp}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/me/payment-method-otp/verify'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'requestId': requestId, 'otp': otp}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'OTP không đúng');
  }

  Future<List<dynamic>> getPosts() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/posts'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được bài đăng');
  }

  Future<Map<String, dynamic>> createPost({required String token, required String content, String hashtags = '', File? mediaFile}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/posts'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['content'] = content;
    request.fields['hashtags'] = hashtags;
    if (mediaFile != null) {
      request.files.add(await http.MultipartFile.fromPath('media', mediaFile.path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Đăng bài thất bại');
  }

  Future<Map<String, dynamic>> likePost({required String token, required int id}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/posts/$id/like'), headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không thích được bài');
  }

  Future<Map<String, dynamic>> savePost({required String token, required int id}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/posts/$id/save'), headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không lưu được bài');
  }

  Future<Map<String, dynamic>> commentPost({required String token, required int id, required String content}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/posts/$id/comment'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'content': content}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không bình luận được');
  }

  Future<Map<String, dynamic>> sharePost({required String token, required int id}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/posts/$id/share'), headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không chia sẻ được');
  }

  Future<List<dynamic>> getVideos({String query = ''}) async {
    final q = query.trim();
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/videos/feed${q.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(q)}'}'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Failed to load videos');
  }

  Future<Map<String, dynamic>> getVideoById(int id) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/videos/$id'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không tải được video');
  }

  Future<Map<String, dynamic>> likeVideo({required String token, required int id}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/videos/$id/like'), headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không cập nhật được lượt thích');
  }

  Future<Map<String, dynamic>> saveVideo({required String token, required int id}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/videos/$id/save'), headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không lưu được video');
  }

  Future<Map<String, dynamic>> commentVideo({required String token, required int id, required String content}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/videos/$id/comment'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'content': content}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Không bình luận được');
  }

  Future<void> viewVideo({required int id}) async {
    try {
      await http.post(Uri.parse('${ApiConstants.baseUrl}/videos/$id/view'));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> createVideo({required String token, required String title, required String description, required String videoUrl, String category = 'GUIDE'}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/videos'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'title': title, 'description': description, 'videoUrl': videoUrl, 'category': category, 'sourceType': 'YOUTUBE'}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Tạo video thất bại');
  }

  Future<Map<String, dynamic>> uploadVideoFile({required String token, required String title, required String description, required File videoFile, File? thumbnailFile, String category = 'GUIDE'}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/videos'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['sourceType'] = 'FILE';
    request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));
    if (thumbnailFile != null) request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnailFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Tải video thất bại');
  }

  Future<Map<String, dynamic>> requestPaymentOtp({required String token, required String method}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/bookings/payment-otp/request'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'method': method}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['data'] ?? data);
    }
    throw Exception(data['message'] ?? 'Không gửi được OTP');
  }

  Future<Map<String, dynamic>> verifyPaymentOtp({required String token, required String requestId, required String otp}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/bookings/payment-otp/verify'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'requestId': requestId, 'otp': otp}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['data'] ?? data);
    }
    throw Exception(data['message'] ?? 'OTP không hợp lệ');
  }

  Future<List<dynamic>> getNotifications({String? token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/notifications'), headers: token == null ? {} : {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Failed to load notifications');
  }

  Future<Map<String, dynamic>> getCoinTasks({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/coins/tasks'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Không tải được nhiệm vụ coin');
  }

  Future<Map<String, dynamic>> claimCoinTask({required String token, required String taskId}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/coins/tasks/$taskId/claim'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Nhận coin thất bại');
  }

  Future<List<dynamic>> getCoinHistory({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/coins/history/me'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được lịch sử xu');
  }

  Future<List<dynamic>> getMyVouchers({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/coins/vouchers/me'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được voucher của tôi');
  }

  Future<Map<String, dynamic>> redeemVoucher({required String token, required int voucherId}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/vouchers/$voucherId/redeem'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Đổi voucher thất bại');
  }

  Future<List<dynamic>> getSpinRewards({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/spin/rewards'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được vòng quay');
  }

  Future<Map<String, dynamic>> playSpin({required String token}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/spin/play'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Quay thưởng thất bại');
  }

  Future<List<dynamic>> getClasses() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/classes'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được lớp học');
  }

  Future<List<dynamic>> getMyClasses({required String token}) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/classes/me'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'] ?? [];
    throw Exception(data['message'] ?? 'Không tải được lớp học của tôi');
  }

  Future<Map<String, dynamic>> enrollClass({required String token, required int classId}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/classes/$classId/enroll'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Đăng ký lớp thất bại');
  }


  Future<Map<String, dynamic>> enrollStudentToClass({required String token, required int classId, required int userId}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/classes/$classId/enroll'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'userId': userId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    }
    throw Exception(data['message'] ?? 'Thêm học viên thất bại');
  }

  Future<Map<String, dynamic>> createClassManaged({required String token, required String title, required String description, required String startDate, required String endDate, required List<String> weekdays, required String sessionText, required String priceText, int maxStudents = 20}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/classes'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'title': title, 'description': description, 'startDate': startDate, 'endDate': endDate, 'weekdays': weekdays, 'sessionText': sessionText, 'note': priceText, 'maxStudents': maxStudents}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Tạo lớp thất bại');
  }

  Future<Map<String, dynamic>> updateClassManaged({required String token, required int id, required String title, required String description, required String startDate, required String endDate, required List<String> weekdays, required String sessionText, required String priceText, int maxStudents = 20}) async {
    final response = await http.put(Uri.parse('${ApiConstants.baseUrl}/classes/$id'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'title': title, 'description': description, 'startDate': startDate, 'endDate': endDate, 'weekdays': weekdays, 'sessionText': sessionText, 'note': priceText, 'maxStudents': maxStudents}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data['data'] ?? {});
    throw Exception(data['message'] ?? 'Cập nhật lớp thất bại');
  }

  Future<void> deleteClassManaged({required String token, required int id}) async {
    final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}/classes/$id'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Xóa lớp thất bại');
    }
  }

  Future<Map<String, dynamic>> register({required String name, required String email, required String password, String? phone}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': name, 'email': email, 'password': password, 'phone': phone}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Đăng ký thất bại');
  }

  Future<Map<String, dynamic>> verifyEmail({required String email, required String code}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/auth/verify-email-otp'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'otp': code}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Xác nhận email thất bại');
  }

  Future<Map<String, dynamic>> resendVerification({required String email}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/auth/resend-email-otp'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Gửi lại mã thất bại');
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await http.post(Uri.parse('${ApiConstants.baseUrl}/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Đăng nhập thất bại');
  }
}
