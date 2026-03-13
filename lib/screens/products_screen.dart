import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'profile_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  final api = ApiService();
  late TabController _tabController;
  bool loading = true;
  String? error;

  final Map<String, List<dynamic>> dataByType = {
    'COURT': [],
    'BALL': [],
    'RACKET': [],
    'COACH': [],
  };

  final Map<String, String> labels = const {
    'COURT': 'Sân',
    'BALL': 'Bóng',
    'RACKET': 'Vợt',
    'COACH': 'Đồ ăn uống',
  };

  List<dynamic> vouchers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });
      final results = await Future.wait<dynamic>([
        api.getProducts(type: 'COURT'),
        api.getProducts(type: 'BALL'),
        api.getProducts(type: 'RACKET'),
        api.getProducts(type: 'COACH'),
        ((context.read<AuthProvider>().token?.isNotEmpty ?? false) ? api.getMyVouchers(token: context.read<AuthProvider>().token!).catchError((_) => <dynamic>[]) : Future.value(<dynamic>[])),
      ]);
      if (!mounted) return;
      setState(() {
        dataByType['COURT'] = List<dynamic>.from(results[0] as List);
        dataByType['BALL'] = List<dynamic>.from(results[1] as List);
        dataByType['RACKET'] = List<dynamic>.from(results[2] as List);
        dataByType['COACH'] = List<dynamic>.from(results[3] as List);
        vouchers = List<dynamic>.from(results[4] as List);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int _toMinutes(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hour * 60 + minute;
  }

  String _fmtMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<int> _generateTimeOptions(String openTime, String closeTime) {
    final start = _toMinutes(openTime);
    final end = _toMinutes(closeTime);
    final values = <int>[];
    for (int t = start; t <= end; t += 60) {
      values.add(t);
    }
    return values;
  }

  double _bookingBasePrice(
    List<Map<String, dynamic>> slots,
    String start,
    String end,
  ) {
    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);
    if (endMin <= startMin) return 0;

    double total = 0;
    for (final slot in slots) {
      final slotStart = _toMinutes('${slot['startTime']}');
      final slotEnd = _toMinutes('${slot['endTime']}');
      final overlapStart = startMin > slotStart ? startMin : slotStart;
      final overlapEnd = endMin < slotEnd ? endMin : slotEnd;
      if (overlapEnd > overlapStart) {
        final hours = (overlapEnd - overlapStart) / 60.0;
        final rate = double.tryParse('${slot['price'] ?? 0}') ?? 0;
        total += hours * rate;
      }
    }
    return total;
  }

  String _normalizePaymentMethodLabel(String raw) {
    final value = raw.trim();
    const allowed = ['Tiền mặt', 'Chuyển khoản QR', 'MoMo', 'ZaloPay'];
    for (final method in allowed) {
      if (value == method || value.startsWith('$method •')) {
        return method;
      }
    }
    return value;
  }

  String _extractAccountFromPaymentLabel(String raw, String method) {
    if (!raw.startsWith(method)) return '';
    final parts = raw.split('•');
    if (parts.length < 2) return '';
    return parts.sublist(1).join('•').trim();
  }

  Future<void> _refreshMyVouchers() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    try {
      final latest = await api.getMyVouchers(token: token);
      if (!mounted) return;
      setState(() => vouchers = List<dynamic>.from(latest));
    } catch (_) {}
  }

  Future<void> _showQrDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thanh toán QR'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 160, color: AppColors.primary),
            SizedBox(height: 12),
            Text('Quét mã QR demo để thanh toán.'),
            SizedBox(height: 6),
            Text(
              'Ngân hàng: Vietcombank\nSTK: 123456789\nChủ TK: TAY MO PICKLEBALL CLUB',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tôi đã thanh toán'),
          ),
        ],
      ),
    );
  }

  Future<void> openBookingForm(Map<String, dynamic> item) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    final slots = List<Map<String, dynamic>>.from(
      (item['priceSlots'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sân này chưa có bảng giá để đặt')),
      );
      return;
    }

    final rentalItems = [
      ...dataByType['BALL']!.map((e) => Map<String, dynamic>.from(e as Map)),
      ...dataByType['RACKET']!.map((e) => Map<String, dynamic>.from(e as Map)),
      ...dataByType['COACH']!.map((e) => Map<String, dynamic>.from(e as Map)),
    ];
    final allVoucherEntries = vouchers
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final availableVouchers = allVoucherEntries.where((data) {
      final voucher = Map<String, dynamic>.from((data['voucher'] ?? data) as Map);
      final status = (data['status'] ?? 'AVAILABLE').toString().toUpperCase();
      final isActive = voucher['isActive'] != false;
      if (status != 'AVAILABLE' || !isActive) return false;
      final now = DateTime.now();
      final start = DateTime.tryParse('${voucher['startDate'] ?? ''}');
      final end = DateTime.tryParse('${voucher['endDate'] ?? ''}');
      if (start != null && now.isBefore(start)) return false;
      if (end != null && now.isAfter(end)) return false;
      return true;
    }).toList();

    DateTime selectedDate = DateTime.now();
    final openTime = item['openTime']?.toString() ?? '${slots.first['startTime']}';
    final closeTime = item['closeTime']?.toString() ?? '${slots.last['endTime']}';
    final timeOptions = _generateTimeOptions(openTime, closeTime);
    int startMinutes = timeOptions.first;
    int endMinutes = timeOptions.length > 1 ? timeOptions[1] : timeOptions.first;
    const allowedPaymentMethods = ['Tiền mặt', 'Chuyển khoản QR', 'MoMo', 'ZaloPay'];
    final savedPaymentMethodLabels = <String>['Tiền mặt'];
    for (final entry in auth.paymentMethods) {
      final label = entry.toString().trim();
      if (label.isEmpty) continue;
      final normalized = _normalizePaymentMethodLabel(label);
      if (!allowedPaymentMethods.contains(normalized)) continue;
      if (!savedPaymentMethodLabels.contains(label)) {
        savedPaymentMethodLabels.add(label);
      }
    }
    String paymentMethod = savedPaymentMethodLabels.first;
    String? paymentOtpRequestId;
    Map<String, dynamic>? selectedVoucher;
    final selectedQty = <String, int>{};

    double computeExtras() {
      double sum = 0;
      for (final product in rentalItems) {
        final key = '${product['type']}-${product['id']}';
        final qty = selectedQty[key] ?? 0;
        sum += qty * (double.tryParse('${product['price'] ?? 0}') ?? 0);
      }
      return sum;
    }

    double computeDiscount(double subtotal) {
      if (selectedVoucher == null) return 0;
      final voucherData = Map<String, dynamic>.from((selectedVoucher!['voucher'] ?? selectedVoucher!) as Map);
      final minOrder = double.tryParse('${voucherData['minOrderValue'] ?? 0}') ?? 0;
      if (subtotal < minOrder) return 0;
      final value = double.tryParse('${voucherData['discountValue'] ?? 0}') ?? 0;
      final rawDiscount = voucherData['discountType'] == 'PERCENT' ? subtotal * value / 100 : value;
      return rawDiscount > subtotal ? subtotal : rawDiscount;
    }

    String voucherSummary(Map<String, dynamic> voucherWrapper) {
      final voucher = Map<String, dynamic>.from((voucherWrapper['voucher'] ?? voucherWrapper) as Map);
      final value = double.tryParse('${voucher['discountValue'] ?? 0}') ?? 0;
      final minOrder = double.tryParse('${voucher['minOrderValue'] ?? 0}') ?? 0;
      final discountText = voucher['discountType'] == 'PERCENT'
          ? 'Giảm ${value.toStringAsFixed(0)}%'
          : 'Giảm ${value.toStringAsFixed(0)}đ';
      return '$discountText • Đơn tối thiểu ${minOrder.toStringAsFixed(0)}đ';
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final validRange = endMinutes > startMinutes;
            final selectedStart = _fmtMinutes(startMinutes);
            final selectedEnd = _fmtMinutes(endMinutes);
            final double basePrice = validRange
                ? _bookingBasePrice(slots, selectedStart, selectedEnd)
                : 0.0;
            final double extras = computeExtras();
            final double discount = computeDiscount(basePrice + extras);
            final double total =
                (basePrice + extras - discount).clamp(0, double.infinity).toDouble();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.68,
              maxChildSize: 0.96,
              expand: false,
              builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 18,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  children: [
                    Text(
                      'Đặt sân ${item['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày chơi'),
                      subtitle: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) setModalState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bảng giá theo giờ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...slots.map((slot) {
                      final rateText =
                          '${(double.tryParse('${slot['price'] ?? 0}') ?? 0).toStringAsFixed(0)}đ/giờ';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${slot['startTime']} - ${slot['endTime']}'),
                              Text(
                                rateText,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Text(
                      'Chọn giờ chơi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: startMinutes,
                            decoration: const InputDecoration(
                              labelText: 'Từ giờ',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: timeOptions
                                .take(timeOptions.length - 1)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(_fmtMinutes(v)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() {
                                startMinutes = value;
                                if (endMinutes <= startMinutes) {
                                  endMinutes = startMinutes + 60;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: endMinutes,
                            decoration: const InputDecoration(
                              labelText: 'Đến giờ',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: timeOptions
                                .where((v) => v > startMinutes)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(_fmtMinutes(v)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setModalState(() => endMinutes = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Thuê / mua thêm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...rentalItems.map((product) {
                      final key = '${product['type']}-${product['id']}';
                      final qty = selectedQty[key] ?? 0;
                      final price = double.tryParse('${product['price'] ?? 0}') ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name']?.toString() ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${labels[product['type']] ?? product['type']} · ${price.toStringAsFixed(0)}đ',
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: qty <= 0
                                    ? null
                                    : () => setModalState(() => selectedQty[key] = qty - 1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => setModalState(() => selectedQty[key] = qty + 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    const Text(
                      'Áp dụng ưu đãi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final eligibleVouchers = availableVouchers.where((entry) {
                          final voucher = Map<String, dynamic>.from((entry['voucher'] ?? entry) as Map);
                          final minOrder = double.tryParse('${voucher['minOrderValue'] ?? 0}') ?? 0;
                          return (basePrice + extras) >= minOrder;
                        }).toList();
                        final lockedVouchers = availableVouchers.where((entry) {
                          final voucher = Map<String, dynamic>.from((entry['voucher'] ?? entry) as Map);
                          final minOrder = double.tryParse('${voucher['minOrderValue'] ?? 0}') ?? 0;
                          return (basePrice + extras) < minOrder;
                        }).toList();

                        String dateText(dynamic raw) {
                          final parsed = DateTime.tryParse('${raw ?? ''}');
                          if (parsed == null) return 'Không giới hạn';
                          return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
                        }

                        Future<void> openVoucherPicker() async {
                          await showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (sheetContext) {
                              Widget buildVoucherCard(Map<String, dynamic> entry, {required bool eligible}) {
                                final voucher = Map<String, dynamic>.from((entry['voucher'] ?? entry) as Map);
                                final code = voucher['code']?.toString() ?? '';
                                final minOrder = double.tryParse('${voucher['minOrderValue'] ?? 0}') ?? 0;
                                final isSelected = selectedVoucher != null &&
                                    ((selectedVoucher!['voucher'] ?? selectedVoucher!)['code']?.toString() == code);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: eligible
                                        ? () {
                                            setModalState(() => selectedVoucher = entry);
                                            Navigator.pop(sheetContext);
                                          }
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : Colors.black12,
                                        ),
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(0.08)
                                            : (eligible ? Colors.white : Colors.grey.shade100),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 88,
                                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: eligible ? AppColors.primary : Colors.grey.shade400,
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(18),
                                                bottomLeft: Radius.circular(18),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.discount, color: Colors.white, size: 26),
                                                const SizedBox(height: 8),
                                                Text(
                                                  code.isEmpty ? 'VOUCHER' : code,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          voucher['title']?.toString() ?? 'Voucher ưu đãi',
                                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        const Icon(Icons.check_circle, color: AppColors.primary),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(voucherSummary(entry)),
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: eligible ? Colors.green.shade50 : Colors.orange.shade50,
                                                          borderRadius: BorderRadius.circular(999),
                                                        ),
                                                        child: Text(
                                                          eligible ? 'Đủ điều kiện' : 'Chưa đủ điều kiện',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: eligible ? Colors.green.shade700 : Colors.orange.shade800,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(999),
                                                        ),
                                                        child: Text(
                                                          'HSD: ${dateText(voucher['endDate'])}',
                                                          style: const TextStyle(fontSize: 12),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    eligible
                                                        ? 'Dùng 1 lần duy nhất, sau khi đặt sân thành công voucher sẽ chuyển sang USED.'
                                                        : 'Cần đơn tối thiểu ${minOrder.toStringAsFixed(0)}đ để áp dụng.',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: eligible ? Colors.black54 : Colors.redAccent,
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
                                );
                              }

                              return SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.10),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.discount_outlined, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Chọn voucher',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setModalState(() => selectedVoucher = null);
                                              Navigator.pop(sheetContext);
                                            },
                                            child: const Text('Không dùng'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF6F8FB),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.black12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tổng tạm tính hiện tại: ${(basePrice + extras).toStringAsFixed(0)}đ',
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    '${eligibleVouchers.length} dùng ngay',
                                                    style: TextStyle(
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    '${lockedVouchers.length} chờ đủ điều kiện',
                                                    style: TextStyle(
                                                      color: Colors.orange.shade800,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                if (selectedVoucher != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.10),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      'Đã chọn ${(selectedVoucher!['voucher'] ?? selectedVoucher!)['code'] ?? ''}',
                                                      style: const TextStyle(
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Flexible(
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            if (eligibleVouchers.isNotEmpty) ...[
                                              const Text('Có thể dùng ngay', style: TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 10),
                                              ...eligibleVouchers.map((entry) => buildVoucherCard(entry, eligible: true)),
                                            ],
                                            if (lockedVouchers.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              const Text('Chưa đủ điều kiện', style: TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 10),
                                              ...lockedVouchers.map((entry) => buildVoucherCard(entry, eligible: false)),
                                            ],
                                            if (availableVouchers.isEmpty)
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: Colors.black12),
                                                ),
                                                child: const Text('Hiện chưa có voucher khả dụng trong ví ưu đãi.'),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        final selectedVoucherData = selectedVoucher == null
                            ? null
                            : Map<String, dynamic>.from((selectedVoucher!['voucher'] ?? selectedVoucher!) as Map);
                        final selectedMinOrder = selectedVoucherData == null
                            ? 0.0
                            : (double.tryParse('${selectedVoucherData['minOrderValue'] ?? 0}') ?? 0.0);
                        final selectedEligible = selectedVoucherData == null
                            ? false
                            : (basePrice + extras) >= selectedMinOrder;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: openVoucherPicker,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: selectedVoucher == null ? Colors.grey.shade50 : AppColors.primary.withOpacity(0.06),
                                    border: Border.all(
                                      color: selectedVoucher == null ? Colors.black12 : AppColors.primary.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: selectedVoucher == null ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          selectedVoucher == null ? Icons.local_offer_outlined : Icons.discount,
                                          color: selectedVoucher == null ? Colors.black54 : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedVoucherData == null
                                                  ? 'Voucher'
                                                  : (selectedVoucherData['title']?.toString() ?? 'Voucher đã chọn'),
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              selectedVoucherData == null
                                                  ? availableVouchers.isEmpty
                                                      ? 'Hiện chưa có voucher khả dụng'
                                                      : '${eligibleVouchers.length} voucher đủ điều kiện • ${lockedVouchers.length} voucher chờ áp dụng'
                                                  : voucherSummary(selectedVoucher!),
                                              style: TextStyle(
                                                color: selectedVoucherData == null ? Colors.black54 : Colors.black87,
                                              ),
                                            ),
                                            if (selectedVoucherData != null) ...[
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: selectedEligible ? Colors.green.shade50 : Colors.orange.shade50,
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      selectedEligible ? 'Đang áp dụng' : 'Chưa đủ điều kiện',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: selectedEligible ? Colors.green.shade700 : Colors.orange.shade800,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      (selectedVoucherData['code'] ?? '').toString(),
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                              if (selectedVoucher != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedEligible
                                            ? 'Voucher sẽ tự trừ ${discount.toStringAsFixed(0)}đ khi xác nhận đặt sân.'
                                            : 'Voucher đã chọn chưa đủ điều kiện áp dụng ở tổng tiền hiện tại.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selectedEligible ? Colors.black54 : Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => setModalState(() => selectedVoucher = null),
                                      child: const Text('Bỏ chọn'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: savedPaymentMethodLabels
                          .map((label) => DropdownMenuItem<String>(value: label, child: Text(label)))
                          .toList(),
                      onChanged: (value) => setModalState(() {
                        paymentMethod = value ?? 'Tiền mặt';
                      }),
                    ),
                    if (savedPaymentMethodLabels.length == 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hiện bạn mới có Tiền mặt. Muốn dùng MoMo, ZaloPay hoặc Chuyển khoản QR, hãy thêm và xác thực trong Thông tin cá nhân.',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileDetailScreen()),
                              );
                              if (!mounted) return;
                              final auth = context.read<AuthProvider>();
                              final refreshed = <String>['Tiền mặt'];
                              for (final entry in auth.paymentMethods) {
                                final label = entry.toString().trim();
                                if (label.isEmpty) continue;
                                final normalized = _normalizePaymentMethodLabel(label);
                                if (!allowedPaymentMethods.contains(normalized)) continue;
                                if (!refreshed.contains(label)) refreshed.add(label);
                              }
                              setModalState(() {
                                savedPaymentMethodLabels
                                  ..clear()
                                  ..addAll(refreshed);
                                if (!savedPaymentMethodLabels.contains(paymentMethod)) {
                                  paymentMethod = savedPaymentMethodLabels.first;
                                }
                              });
                            },
                            child: const Text('Thêm ngay'),
                          ),
                        ],
                      ),
                    ] else if (paymentMethod != 'Tiền mặt') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Đơn sẽ dùng phương thức đã lưu: $paymentMethod. OTP sẽ gửi về Gmail của tài khoản đang đăng nhập để xác thực đơn đặt sân.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _priceRow('Giá sân', basePrice),
                          _priceRow('Thuê / mua thêm', extras),
                          _priceRow('Giảm giá', -discount),
                          const Divider(),
                          _priceRow('Tổng thanh toán', total, emphasize: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: validRange ? () => Navigator.pop(context, true) : null,
                        child: Text(paymentMethod == 'Tiền mặt' ? 'Xác nhận đặt sân' : 'Thanh toán & đặt sân'),
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

    if (ok != true) return;

    final selectedStart = _fmtMinutes(startMinutes);
    final selectedEnd = _fmtMinutes(endMinutes);
    final double basePrice = _bookingBasePrice(slots, selectedStart, selectedEnd);
    double extras = 0;
    for (final product in rentalItems) {
      final key = '${product['type']}-${product['id']}';
      final qty = selectedQty[key] ?? 0;
      extras += qty * (double.tryParse('${product['price'] ?? 0}') ?? 0);
    }
    double discount = 0;
    if (selectedVoucher != null) {
      final voucherData = Map<String, dynamic>.from((selectedVoucher!['voucher'] ?? selectedVoucher!) as Map);
      final minOrder = double.tryParse('${voucherData['minOrderValue'] ?? 0}') ?? 0;
      if (basePrice + extras >= minOrder) {
        final value = double.tryParse('${voucherData['discountValue'] ?? 0}') ?? 0;
        discount = voucherData['discountType'] == 'PERCENT'
            ? (basePrice + extras) * value / 100
            : value;
        if (discount > basePrice + extras) {
          discount = basePrice + extras;
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voucher chỉ áp dụng cho đơn từ ${minOrder.toStringAsFixed(0)}đ')),
        );
        return;
      }
    }
    final double finalTotal =
        (basePrice + extras - discount).clamp(0, double.infinity).toDouble();

    if (paymentMethod != 'Tiền mặt') {
      final normalizedPaymentMethod = _normalizePaymentMethodLabel(paymentMethod);
      if (normalizedPaymentMethod == 'Chuyển khoản QR') {
        await _showQrDialog();
      }
      try {
        final request = await api.requestPaymentOtp(
          token: auth.token!,
          method: normalizedPaymentMethod,
        );
        paymentOtpRequestId = request['requestId']?.toString();
        if (!mounted) return;
        final debugOtp = (request['debugOtp'] ?? '').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(debugOtp.isEmpty ? 'Đã gửi OTP về Gmail của tài khoản đang đăng nhập' : 'Đã gửi OTP. Mã test: $debugOtp')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }

      if (paymentOtpRequestId == null || paymentOtpRequestId!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tạo được yêu cầu OTP thanh toán')),
        );
        return;
      }

      final otpCtrl = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xác thực OTP ${_normalizePaymentMethodLabel(paymentMethod)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mã OTP đã được gửi về Gmail của tài khoản đang đăng nhập.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nhập mã gồm 6 số để hoàn tất thanh toán ${_normalizePaymentMethodLabel(paymentMethod)}.',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'OTP 6 số',
                    hintText: 'Nhập mã OTP',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.password_rounded),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final request = await api.requestPaymentOtp(
                              token: auth.token!,
                              method: _normalizePaymentMethodLabel(paymentMethod),
                            );
                            paymentOtpRequestId = request['requestId']?.toString();
                            if (!mounted) return;
                            final debugOtp = (request['debugOtp'] ?? '').toString();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(debugOtp.isEmpty ? 'Đã gửi lại OTP mới' : 'Đã gửi lại OTP mới. Mã test: $debugOtp')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Gửi lại OTP'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, otpCtrl.text.trim()),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Xác nhận'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (entered == null || entered.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán chưa được xác nhận')),
        );
        return;
      }
      try {
        await api.verifyPaymentOtp(
          token: auth.token!,
          requestId: paymentOtpRequestId!,
          otp: entered,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }
      paymentMethod = paymentMethod.trim();
    }

    final extrasPayload = rentalItems.map((product) {
      final key = '${product['type']}-${product['id']}';
      final qty = selectedQty[key] ?? 0;
      return {
        'id': product['id'],
        'name': product['name'],
        'type': product['type'],
        'qty': qty,
        'price': double.tryParse('${product['price'] ?? 0}') ?? 0,
      };
    }).where((item) => (item['qty'] as int) > 0).map((item) => Map<String, dynamic>.from(item)).toList();

    try {
      final courtId = item['legacyId'] ?? item['id'];
      await api.createBooking(
        token: auth.token!,
        courtId: int.tryParse('$courtId') ?? 0,
        bookingDate: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        ).toIso8601String(),
        startTime: selectedStart,
        endTime: selectedEnd,
        totalPrice: finalTotal,
        paymentMethod: paymentMethod,
        voucherCode: selectedVoucher == null ? null : ((selectedVoucher!['voucher'] ?? selectedVoucher!)['code']?.toString()),
        extras: extrasPayload,
      );
      if (!mounted) return;
      await _refreshMyVouchers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đặt sân thành công. Thanh toán: $paymentMethod · ${finalTotal.toStringAsFixed(0)}đ',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  static Widget _priceRow(String label, double value, {bool emphasize = false}) {
    final display = value < 0
        ? '-${value.abs().toStringAsFixed(0)}đ'
        : '${value.toStringAsFixed(0)}đ';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            display,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String type) {
    final items = dataByType[type] ?? [];
    if (items.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
    return RefreshIndicator(
      onRefresh: fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = Map<String, dynamic>.from(items[i] as Map);
          final subtitleParts = <String>[labels[type] ?? type];
          if (item['price'] != null && type != 'COURT') {
            subtitleParts.add('Giá: ${item['price']}');
          }
          if (item['stock'] != null && type != 'COURT') {
            subtitleParts.add('Kho: ${item['stock']}');
          }
          if (type == 'COURT' && item['openTime'] != null) {
            subtitleParts.add('${item['openTime']} - ${item['closeTime']}');
          }
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(item['name']?.toString() ?? ''),
              subtitle: Text(subtitleParts.join(' • ')),
              trailing: type == 'COURT'
                  ? ElevatedButton(
                      onPressed: () => openBookingForm(item),
                      child: const Text('Đặt'),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm & dịch vụ'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sân'),
            Tab(text: 'Bóng'),
            Tab(text: 'Vợt'),
            Tab(text: 'Đồ ăn uống'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList('COURT'),
                    _buildList('BALL'),
                    _buildList('RACKET'),
                    _buildList('COACH'),
                  ],
                ),
    );
  }
}
