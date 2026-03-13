import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotificationTile extends StatelessWidget {
  final String title;
  final String content;
  final String? type;
  final String? createdAt;

  const NotificationTile({
    super.key,
    required this.title,
    required this.content,
    this.type,
    this.createdAt,
  });

  String _timeText() {
    final raw = (createdAt ?? '').trim();
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final local = date.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} • $hh:$mi';
  }

  IconData _iconForType() {
    switch ((type ?? '').toUpperCase()) {
      case 'BOOKING':
        return Icons.calendar_month;
      case 'VOUCHER':
      case 'PROMOTION':
        return Icons.local_offer;
      case 'COIN':
        return Icons.monetization_on;
      case 'EVENT':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _timeText();
    final typeText = (type ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForType(), color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Thông báo mới' : title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (typeText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          typeText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  content.isEmpty ? 'Chưa có nội dung thông báo' : content,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
