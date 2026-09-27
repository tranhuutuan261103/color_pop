// File: creator_screen.dart
// Chức năng: Màn hình chọn tính năng tạo ảnh.
// Xử lý việc chọn ảnh từ thư viện và điều hướng tới các màn hình xử lý tương ứng.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/cubit/home_cubit.dart';
import '../../dev/cpop_generator_screen.dart';
import '../widget/creator_app_bar.dart';
import '../widget/action_card.dart';

class CreatorScreen extends StatefulWidget {
  const CreatorScreen({super.key});

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  /// Xử lý logic chọn ảnh và điều hướng
  /// - [modelType]: Tên thuật toán (sobel, canny, sketch, ai)
  /// - Hiện tại, chủ yếu chỉ còn AI.
  Future<void> _pickImageAndNavigate(String modelType) async {
    // Mở thư viện lấy ảnh
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      if (modelType == 'ai') {
        // LUỒNG 1: Dành cho model AI
        // 1. Chuyển ảnh thành bytes để màn preview xử lý
        final bytes = await image.readAsBytes();
        if (!mounted) return;

        // 2. Chọn nguồn AI và thông số trước khi chạy preview.
        final settingsResult = await Navigator.pushNamed(
          context,
          '/edge-settings',
        );
        if (settingsResult == null || !mounted) return;

        // 3. Chạy preview bằng cấu hình đã chọn.
        final result = await Navigator.pushNamed(
          context,
          '/edge-preview',
          arguments: {
            'imageBytes': bytes,
            'imagePath': image.path,
            'settings': (settingsResult as Map)['settings'],
          },
        );

        // 4. Nếu user ấn xác nhận ở màn preview -> Sang màn hình vẽ.
        if (result != null && result is Map && mounted) {
          await Navigator.pushNamed(
            context,
            '/workspace',
            arguments: {
              'path': result['imagePath'],
              'model': 'ai',
              'edgeBytes': result['edgeBytes'],
            },
          );
        }
      } else {
        // LUỒNG 2: Dành cho các filter cơ bản (Sobel, Canny, Sketch)
        // Không cần preview, đẩy thẳng dữ liệu vào màn hình vẽ (/workspace)
        await Navigator.pushNamed(
          context,
          '/workspace',
          arguments: {'path': image.path, 'model': modelType},
        );
      }

      // Sau khi hoàn tất luồng, refresh lại dữ liệu màn hình Home (trạng thái, coin, project...)
      if (mounted) {
        context.read<HomeCubit>().loadHomeData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CreatorAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionCard(
              title: 'AI Photo to Draw',
              subtitle: 'Create your coloring pages\nfrom any photo',
              gradientColors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
              ],
              icon: Icons.photo_camera,
              buttons: [_buildModelButton(context, 'AI Model', 'ai')],
            ),
            const SizedBox(height: 16),
            ActionCard(
              title: 'AI Text to Draw',
              subtitle: 'Create your dream drawings\nwith your words',
              gradientColors: [
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ],
              icon: Icons.auto_awesome,
              onTap: () {
                // TODO: Xử lý Text to Image
              },
            ),
            const SizedBox(height: 16),
            ActionCard(
              title: 'Blank Canvas',
              subtitle: 'A space to express yourself\nfreely',
              gradientColors: [
                Theme.of(context).primaryColorDark.withValues(alpha: 0.1),
                Theme.of(context).primaryColorDark.withValues(alpha: 0.05),
              ],
              icon: Icons.play_circle_fill,
              iconColor: Theme.of(context).primaryColor,
              onTap: () {
                // TODO: Mở trang vẽ trống
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CpopGeneratorScreen()),
          );
        },
        backgroundColor: Colors.redAccent,
        tooltip: 'Dev Tool: Gen .cpop',
        child: const Icon(Icons.developer_mode, color: Colors.white),
      ),
    );
  }

  // Xây dựng nút chọn model (AI, Sobel, Canny, Sketch)
  Widget _buildModelButton(
    BuildContext context,
    String label,
    String modelType,
  ) {
    return ElevatedButton(
      onPressed: () => _pickImageAndNavigate(modelType),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
