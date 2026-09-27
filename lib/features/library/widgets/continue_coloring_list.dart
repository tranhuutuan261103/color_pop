import 'package:flutter/material.dart';
import '../../../../common/constants/app_colors.dart';

class ContinueColoringList extends StatelessWidget {
  const ContinueColoringList({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _ContinueCard(
            title: 'Gấu Teddy dễ thương',
            progress: 0.75,
            icon: '🧸',
            bgColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            statusText: '⏸ Paused',
            statusBgColor: const Color(0xFFE8F5E9),
            statusTextColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 14),
          _ContinueCard(
            title: 'Kỳ lân giữa trời sao',
            progress: 0.30,
            icon: '🦄',
            bgColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            statusText: '▶ Bắt đầu',
            statusBgColor: const Color(0xFFFFF3E0),
            statusTextColor: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String title;
  final double progress;
  final String icon;
  final Color bgColor;
  final String statusText;
  final Color statusBgColor;
  final Color statusTextColor;

  const _ContinueCard({
    required this.title,
    required this.progress,
    required this.icon,
    required this.bgColor,
    required this.statusText,
    required this.statusBgColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã hoàn thành ${(progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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