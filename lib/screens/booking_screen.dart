import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/court.dart';
import '../services/api_service.dart';
import '../widgets/court_card.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<CourtModel> _courts = [];

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.getCourts();
      final courts = response.map((item) => CourtModel.fromJson(item)).toList();

      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không tải được danh sách sân';
        _isLoading = false;
      });
    }
  }

  Widget _buildTopCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF19B36F)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đặt sân nhanh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chọn sân phù hợp, xem giá và đặt lịch chơi ngay trong hôm nay.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.textDark),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _fetchCourts,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_courts.isEmpty) {
      return const Center(
        child: Text('Hiện chưa có sân nào'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCourts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopCard(),
          const SizedBox(height: 18),
          const Text(
            'Danh sách sân',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._courts.map(
            (court) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourtCard(court: court),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
        backgroundColor: AppColors.background,
      ),
      body: _buildBody(),
    );
  }
}