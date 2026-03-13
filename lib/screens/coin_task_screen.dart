import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CoinTaskScreen extends StatefulWidget {
  const CoinTaskScreen({super.key});

  @override
  State<CoinTaskScreen> createState() => _CoinTaskScreenState();
}

class _CoinTaskScreenState extends State<CoinTaskScreen>
    with SingleTickerProviderStateMixin {
  final api = ApiService();
  late TabController _tabController;
  bool loading = true;
  String? error;
  List<dynamic> tasks = [];
  List<dynamic> history = [];
  List<dynamic> rewards = [];
  List<dynamic> myVouchers = [];
  List<dynamic> allVouchers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');

      final results = await Future.wait<dynamic>([
        api.getCoinTasks(token: token),
        api.getCoinHistory(token: token),
        api.getSpinRewards(token: token),
        api.getMyVouchers(token: token),
        api.getVouchers(),
      ]);

      final taskResult = Map<String, dynamic>.from(results[0] as Map);
      setState(() {
        tasks = List<dynamic>.from(taskResult['data'] ?? []);
        history = List<dynamic>.from(results[1] as List);
        rewards = List<dynamic>.from(results[2] as List);
        myVouchers = List<dynamic>.from(results[3] as List);
        allVouchers = List<dynamic>.from(results[4] as List);
      });
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _claim(String id) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      await api.claimCoinTask(token: token, taskId: id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhận thưởng thành công')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _spin() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      final result = await api.playSpin(token: token);
      if (!mounted) return;
      final reward = result['data']?['reward'] ?? {};
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn nhận được: ${reward['label'] ?? 'phần thưởng'}')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _redeemVoucher(int voucherId) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) throw Exception('Bạn chưa đăng nhập');
      await api.redeemVoucher(token: token, voucherId: voucherId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi voucher thành công')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Widget _taskTab() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final item = tasks[index] as Map<String, dynamic>;
          final claimed = item['claimed'] == true;
          final eligible = item['eligible'] != false;
          final rewardText = item['rewardType'] == 'VOUCHER'
              ? 'Voucher #${item['voucherId']}'
              : '+${item['amount'] ?? 0} xu';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(rewardText),
                    if (!claimed && !eligible && item['reason'] != null) ...[
                      const SizedBox(height: 6),
                      Text(item['reason'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ],
                ),
              ),
              ElevatedButton(onPressed: (claimed || !eligible) ? null : () => _claim(item['id'].toString()), child: Text(claimed ? 'Đã nhận' : (eligible ? 'Nhận' : 'Chưa đủ điều kiện'))),
            ]),
          );
        },
      );

  Widget _historyTab() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index] as Map<String, dynamic>;
          return Card(
            child: ListTile(
              title: Text('${item['amount'] ?? 0} xu • ${item['type'] ?? ''}'),
              subtitle: Text(item['note']?.toString() ?? '-'),
              trailing: Text(DateTime.tryParse(item['createdAt']?.toString() ?? '')?.toLocal().toString().substring(0, 16) ?? ''),
            ),
          );
        },
      );

  Widget _spinTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(onPressed: _spin, child: const Text('Quay ngay (1 lần / ngày)')),
          const SizedBox(height: 16),
          const Text('Phần thưởng có thể nhận', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...rewards.map((item) {
            final reward = item as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(reward['label']?.toString() ?? ''),
                subtitle: Text(reward['rewardType'] == 'VOUCHER' ? 'Voucher #${reward['voucherId']}' : '${reward['amount'] ?? 0} xu'),
              ),
            );
          }),
        ],
      );

  String _voucherStatusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'AVAILABLE':
        return 'Có thể dùng';
      case 'USED':
        return 'Đã dùng';
      case 'EXPIRED':
        return 'Hết hạn';
      default:
        return raw;
    }
  }

  Widget _voucherTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Ví voucher của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (myVouchers.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const Text('Bạn chưa có voucher nào trong ví ưu đãi'),
            )
          else
            ...myVouchers.map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final voucher = Map<String, dynamic>.from(data['voucher'] as Map);
              final status = (data['status'] ?? 'AVAILABLE').toString();
              return Card(
                child: ListTile(
                  title: Text(voucher['title']?.toString() ?? voucher['code']?.toString() ?? 'Voucher'),
                  subtitle: Text('${voucher['code']} • ${_voucherStatusLabel(status)}'),
                  trailing: Text('${voucher['coinCost'] ?? 0} xu'),
                ),
              );
            }),
          const SizedBox(height: 16),
          const Text('Đổi voucher bằng xu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...allVouchers.where((v) => v['isActive'] != false).map((item) {
            final voucher = Map<String, dynamic>.from(item as Map);
            return Card(
              child: ListTile(
                title: Text(voucher['title']?.toString() ?? ''),
                subtitle: Text('${voucher['code']} • ${voucher['coinCost'] ?? 0} xu'),
                trailing: ElevatedButton(onPressed: () => _redeemVoucher(int.tryParse('${voucher['id']}') ?? 0), child: const Text('Đổi')),
              ),
            );
          }),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví ưu đãi, coin & spin'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Nhiệm vụ'), Tab(text: 'Lịch sử xu'), Tab(text: 'Spin'), Tab(text: 'Voucher')],
        ),
      ),
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : TabBarView(controller: _tabController, children: [_taskTab(), _historyTab(), _spinTab(), _voucherTab()]),
    );
  }
}
