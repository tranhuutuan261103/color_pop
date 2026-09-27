import 'package:flutter/material.dart';
import '../../../../common/constants/app_colors.dart';

class RecommendationsGrid extends StatelessWidget {
  const RecommendationsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.8,
      children: const [
        _LibraryGridCard(
          title: 'Mèo con ngủ ngày',
          subtitle: 'Mới nhất',
          icon: '🐱',
          bgColor: Color(0xFFFFF0F5),
        ),
        _LibraryGridCard(
          title: 'Gấu Bắc Cực',
          subtitle: 'Phổ biến',
          icon: '🐻',
          bgColor: Color(0xFFF0F8FF),
          isNew: true,
          hasPlay: true,
        ),
        _LibraryGridCard(
          title: 'Vườn hoa anh đào',
          subtitle: 'Thư giãn',
          icon: '🌸',
          bgColor: Color(0xFFFFF8E1),
          hasPlay: true,
        ),
        _LibraryGridCard(
          title: 'Cáo con tinh nghịch',
          subtitle: 'Dễ thương',
          icon: '🦊',
          bgColor: Color(0xFFE8F5E9),
        ),
      ],
    );
  }
}

class TrendingGrid extends StatelessWidget {
  const TrendingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.8,
      children: const [
        _LibraryGridCard(
          title: 'Nàng tiên cá',
          subtitle: 'Fantasy',
          icon: '🧜‍♀️',
          bgColor: Color(0xFFF3E5F5),
        ),
        _LibraryGridCard(
          title: 'Dâu tây ngọt ngào',
          subtitle: 'Food',
          icon: '🍓',
          bgColor: Color(0xFFFFEBEE),
          isHot: true,
        ),
      ],
    );
  }
}

class _LibraryGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color bgColor;
  final bool isNew;
  final bool isHot;
  final bool hasPlay;

  const _LibraryGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    this.isNew = false,
    this.isHot = false,
    this.hasPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: bgColor,
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 60)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🔖', style: TextStyle(fontSize: 14)),
            ),
          ),
          if (isNew || isHot)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isNew ? 'NEW' : 'HOT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          if (hasPlay)
            Positioned(
              bottom: 60,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('▶', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}