import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
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
      setState(() {
        loading = true;
        error = null;
      });
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) {
        throw Exception('Bạn chưa đăng nhập');
      }
      final response = await api.getMyBookings(token: token);
      if (!mounted) return;
      setState(() {
        items = List<dynamic>.from(response);
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _money(dynamic value) {
    final amount = double.tryParse('$value') ?? 0;
    return '${amount.toStringAsFixed(0)}đ';
  }

  String _date(dynamic value) {
    final raw = value?.toString() ?? '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw.split('T').first;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _dateTime(dynamic value) {
    final raw = value?.toString() ?? '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _bookingCode(Map<String, dynamic> detail) {
    final id = detail['id']?.toString() ?? '0';
    final datePart = _date(detail['bookingDate']).replaceAll('/', '');
    return 'PB-$datePart-${id.padLeft(4, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'COMPLETED':
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'PAID':
        return 'Đã thanh toán';
      case 'PENDING':
        return 'Chờ xử lý';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'FAILED':
        return 'Thất bại';
      default:
        return raw.isEmpty ? 'Không rõ' : raw;
    }
  }

  Widget _infoRow(String label, String value, {bool emphasize = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? (emphasize ? AppColors.primary : AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }


  String _buildInvoiceText({
    required Map<String, dynamic> detail,
    required Map<String, dynamic> court,
    required List<Map<String, dynamic>> extras,
    required String bookingCode,
    required String paymentMethod,
    required String voucherCode,
    required double courtPrice,
    required double totalPrice,
    required double discountValue,
  }) {
    final buffer = StringBuffer()
      ..writeln('HOA DON DAT SAN PICKLEBALL')
      ..writeln('Ma hoa don: $bookingCode')
      ..writeln('Ma booking: #${detail['id'] ?? '-'}')
      ..writeln('San: ${court['name'] ?? '-'}')
      ..writeln('Ngay choi: ${_date(detail['bookingDate'])}')
      ..writeln('Khung gio: ${detail['startTime'] ?? ''} - ${detail['endTime'] ?? ''}')
      ..writeln('Thanh toan: $paymentMethod')
      ..writeln('Voucher: ${voucherCode.isEmpty ? 'Khong dung' : voucherCode}')
      ..writeln('Trang thai: ${_statusLabel(detail['status']?.toString() ?? '')}')
      ..writeln('--- CHI TIET ---')
      ..writeln('Tien san: ${_money(courtPrice)}');

    for (final item in extras) {
      final qty = int.tryParse('${item['qty'] ?? 0}') ?? 0;
      final price = double.tryParse('${item['price'] ?? 0}') ?? 0;
      buffer.writeln('${item['name'] ?? item['type'] ?? 'Dich vu'} x$qty: ${_money(qty * price)}');
    }

    if (discountValue > 0) {
      buffer.writeln('Giam gia: -${_money(discountValue)}');
    }

    buffer
      ..writeln('Tong thanh toan: ${_money(totalPrice)}')
      ..writeln('Tao luc: ${_dateTime(detail['createdAt'] ?? detail['updatedAt'] ?? '')}');
    return buffer.toString();
  }

  Future<void> _downloadInvoiceText(String bookingCode, String invoiceText) async {
    final safeCode = bookingCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${Directory.systemTemp.path}/$safeCode.txt');
    await file.writeAsString(invoiceText);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu bill tạm tại: ${file.path}')),
    );
  }

  Future<void> _shareInvoiceText(String bookingCode, String invoiceText) async {
    await Share.share(invoiceText, subject: 'Hoa don $bookingCode');
  }

  Widget _summaryStat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBill(Map<String, dynamic> booking) async {
    final auth = context.read<AuthProvider>();
    final id = int.tryParse('${booking['id']}') ?? 0;
    Map<String, dynamic> detail = booking;
    try {
      detail = await api.getBookingById(token: auth.token!, id: id);
    } catch (_) {}
    if (!mounted) return;

    final court = detail['court'] is Map
        ? Map<String, dynamic>.from(detail['court'] as Map)
        : <String, dynamic>{};
    final extras = (detail['extras'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    final status = detail['status']?.toString() ?? '';
    final voucherCode = detail['voucherCode']?.toString() ?? '';
    final paymentMethod = detail['paymentMethod']?.toString() ?? 'Tiền mặt';
    final totalPrice = double.tryParse('${detail['totalPrice'] ?? 0}') ?? 0;
    final courtPrice = double.tryParse('${detail['courtPrice'] ?? detail['totalPrice'] ?? 0}') ?? 0;
    final extrasTotal = extras.fold<double>(0, (sum, item) {
      final qty = int.tryParse('${item['qty'] ?? 0}') ?? 0;
      final price = double.tryParse('${item['price'] ?? 0}') ?? 0;
      return sum + qty * price;
    });
    final discountValue = (courtPrice + extrasTotal - totalPrice).clamp(0, double.infinity).toDouble();
    final bookingCode = _bookingCode(detail);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.62,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E8E5A), Color(0xFF38B173)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331E8E5A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hóa đơn điện tử',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Booking #${detail['id']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      court['name']?.toString() ?? 'Sân Pickleball',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã giao dịch $bookingCode',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _summaryStat(Icons.calendar_month_outlined, 'Ngày chơi', _date(detail['bookingDate'])),
                        const SizedBox(width: 10),
                        _summaryStat(Icons.access_time_rounded, 'Khung giờ', '${detail['startTime'] ?? ''} - ${detail['endTime'] ?? ''}'),
                        const SizedBox(width: 10),
                        _summaryStat(Icons.payments_outlined, 'Tổng tiền', _money(totalPrice)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin giao dịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 14),
                    _infoRow('Mã booking', '#${detail['id'] ?? '-'}'),
                    _infoRow('Mã hóa đơn', bookingCode),
                    _infoRow('Sân', court['name']?.toString() ?? '-'),
                    _infoRow('Ngày chơi', _date(detail['bookingDate'])),
                    _infoRow('Khung giờ', '${detail['startTime'] ?? ''} - ${detail['endTime'] ?? ''}'),
                    _infoRow('Thanh toán', paymentMethod),
                    _infoRow('Voucher', voucherCode.isEmpty ? 'Không dùng' : voucherCode),
                    _infoRow('Tạo lúc', _dateTime(detail['createdAt'] ?? detail['updatedAt'] ?? '')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FBFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text('Chi tiết hóa đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          _infoRow('Tiền sân', _money(courtPrice)),
                          if (extras.isNotEmpty) ...[
                            const Divider(height: 20),
                            ...extras.map((item) {
                              final qty = int.tryParse('${item['qty'] ?? 0}') ?? 0;
                              final price = double.tryParse('${item['price'] ?? 0}') ?? 0;
                              return _infoRow(
                                '${item['name'] ?? item['type'] ?? 'Dịch vụ'} x$qty',
                                _money(qty * price),
                              );
                            }),
                          ],
                          if (discountValue > 0) ...[
                            const Divider(height: 20),
                            _infoRow('Giảm giá', '-${_money(discountValue)}', valueColor: Colors.redAccent),
                          ],
                          const Divider(height: 24, thickness: 1.2),
                          _infoRow('Tổng thanh toán', _money(totalPrice), emphasize: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.verified_user_outlined, color: _statusColor(status)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trạng thái booking', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Booking hiện ở trạng thái ${_statusLabel(status).toLowerCase()}. Bạn có thể dùng bill này để đối chiếu khi tới sân.',
                            style: const TextStyle(color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final invoiceText = _buildInvoiceText(
                          detail: detail,
                          court: court,
                          extras: extras,
                          bookingCode: bookingCode,
                          paymentMethod: paymentMethod,
                          voucherCode: voucherCode,
                          courtPrice: courtPrice,
                          totalPrice: totalPrice,
                          discountValue: discountValue,
                        );
                        await _downloadInvoiceText(bookingCode, invoiceText);
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Tải bill'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final invoiceText = _buildInvoiceText(
                          detail: detail,
                          court: court,
                          extras: extras,
                          bookingCode: bookingCode,
                          paymentMethod: paymentMethod,
                          voucherCode: voucherCode,
                          courtPrice: courtPrice,
                          totalPrice: totalPrice,
                          discountValue: discountValue,
                        );
                        await _shareInvoiceText(bookingCode, invoiceText);
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Chia sẻ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  final invoiceText = _buildInvoiceText(
                    detail: detail,
                    court: court,
                    extras: extras,
                    bookingCode: bookingCode,
                    paymentMethod: paymentMethod,
                    voucherCode: voucherCode,
                    courtPrice: courtPrice,
                    totalPrice: totalPrice,
                    discountValue: discountValue,
                  );
                  await Clipboard.setData(ClipboardData(text: invoiceText));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép hóa đơn vào clipboard')),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Sao chép bill'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Đóng hóa đơn'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final court = booking['court'] is Map
        ? Map<String, dynamic>.from(booking['court'] as Map)
        : <String, dynamic>{};
    final status = booking['status']?.toString() ?? '';
    final voucherCode = booking['voucherCode']?.toString() ?? '';

    return InkWell(
      onTap: () => _showBill(booking),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 5),
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    court['name']?.toString() ?? 'Sân Pickleball',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(_date(booking['bookingDate'])),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text('${booking['startTime'] ?? ''} - ${booking['endTime'] ?? ''}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          booking['paymentMethod']?.toString() ?? 'Tiền mặt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _money(booking['totalPrice'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (voucherCode.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 18, color: Colors.black54),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Voucher: $voucherCode',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Nhấn để xem hóa đơn chi tiết',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                SizedBox(width: 6),
                Icon(Icons.receipt_long, size: 18, color: Colors.black54),
              ],
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
        title: const Text('Lịch sử đặt sân'),
        backgroundColor: AppColors.background,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: load,
                  child: items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.event_busy, size: 72, color: Colors.black26),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Bạn chưa có lịch đặt sân nào',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final booking = Map<String, dynamic>.from(items[index] as Map);
                            return _buildBookingCard(booking);
                          },
                        ),
                ),
    );
  }
}
