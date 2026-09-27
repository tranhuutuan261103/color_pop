import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/constants/app_colors.dart';
import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';
import '../../home/cubit/home_cubit.dart';
import '../../settings/pages/settings_page.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeTab = 'in-progress';
  List<ColorProject> _inProgressProjects = [];
  List<ColorProject> _completedProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final inProgress = await DatabaseHelper.instance.getProjectsByStatus(
      'in_progress',
    );
    final completed = await DatabaseHelper.instance.getProjectsByStatus(
      'completed',
    );

    if (mounted) {
      setState(() {
        _inProgressProjects = inProgress;
        _completedProjects = completed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.reply,
                                  size: 24,
                                  color: Colors.red[300],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Lịch sử',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Text(
                      'Quản lý tất cả tác phẩm của bạn',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          icon: Text('🔍', style: TextStyle(fontSize: 18)),
                          hintText: 'Tìm tác phẩm, chủ đề...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppColors.secondaryText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tabs (Pill style)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildTab('⏳ Đang tô', 'in-progress'),
                          const SizedBox(width: 8),
                          _buildTab('✅ Đã xong', 'completed'),
                          const SizedBox(width: 8),
                          _buildTab('❤️ Yêu thích', 'favorites'),
                          const SizedBox(width: 8),
                          _buildTab('📝 Nháp', 'drafts'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '🖍️',
                            _inProgressProjects.length.toString(),
                            'Đang tô',
                            Theme.of(context).primaryColor,
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '✨',
                            _completedProjects.length.toString(),
                            'Hoàn thành',
                            AppColors.accent3,
                            AppColors.accent2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '❤️',
                            '0',
                            'Yêu thích',
                            AppColors.accent4,
                            AppColors.accent1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tab Content
                    if (_activeTab == 'in-progress') _buildInProgressTab(),
                    if (_activeTab == 'completed') _buildCompletedTab(),
                    if (_activeTab == 'favorites')
                      _buildEmptyState(
                        '❤️',
                        'Chưa có yêu thích nào',
                        'Nhấn vào trái tim khi tô màu để lưu vào đây!',
                      ),
                    if (_activeTab == 'drafts')
                      _buildEmptyState(
                        '📝',
                        'Không có nháp nào',
                        'Các bản nháp tự động lưu sẽ xuất hiện ở đây',
                      ),

                    const SizedBox(height: 24),

                    // Collections Section (Always visible at bottom)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📁 Bộ sưu tập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '+ Tạo mới',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildCollectionItem(
                      '❤️',
                      'Yêu thích',
                      '0 tác phẩm',
                      const [Color(0xFFFFE0E3), Color(0xFFFFD1D6)],
                    ),
                    const SizedBox(height: 10),
                    _buildCollectionItem(
                      '📥',
                      'Đã tải xuống',
                      '15 tác phẩm',
                      const [Color(0xFFE0F5E0), Color(0xFFD1EBD1)],
                    ),
                    const SizedBox(height: 10),
                    _buildCollectionItem('🎁', 'Premium', '8 tác phẩm', const [
                      Color(0xFFE0E0F5),
                      Color(0xFFD1D1F0),
                    ]),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTab(String title, String tabId) {
    final isActive = _activeTab == tabId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? null : Theme.of(context).cardColor,
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.transparent,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
              ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.secondaryText,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String icon,
    String num,
    String label,
    Color c1,
    Color c2,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c1, c2]),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  num,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressTab() {
    if (_inProgressProjects.isEmpty) {
      return _buildEmptyState(
        '⏳',
        'Chưa có dự án nào',
        'Bắt đầu tô màu ngay nhé!',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⏳ Đang tô màu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Xem tất cả ›',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._inProgressProjects.map((p) => _buildProgressCard(p)),
      ],
    );
  }

  Widget _buildCompletedTab() {
    if (_completedProjects.isEmpty) {
      return _buildEmptyState(
        '🏆',
        'Chưa hoàn thành',
        'Hoàn thành một bức tranh để hiển thị tại đây.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🏆 Vừa hoàn thành',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Xem tất cả ›',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _completedProjects.length,
          itemBuilder: (context, index) {
            final p = _completedProjects[index];
            return GestureDetector(
              onTap: () => _openWorkspace(p.imagePath),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.file(
                          File(p.imagePath),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Tác phẩm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('✅', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hoàn thành',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressCard(ColorProject p) {
    return GestureDetector(
      onTap: () => _openWorkspace(p.imagePath),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(p.imagePath),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dự án',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Đang tiến hành',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.5, // Dummy progress
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tagPinkBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '50%',
                style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String emoji, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionItem(
    String icon,
    String name,
    String count,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.secondaryText),
        ],
      ),
    );
  }

  Future<void> _openWorkspace(String path) async {
    await Navigator.pushNamed(context, '/workspace', arguments: path);
    _loadProjects();
    if (mounted) {
      context.read<HomeCubit>().loadHomeData();
    }
  }
}
