import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';

class WorkspaceAppBar extends StatelessWidget {
  final WorkspaceController controller;

  const WorkspaceAppBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAppBarButton(
            context: context,
            icon: Icons.reply,
            color: Theme.of(context).iconTheme.color ?? Colors.red[300]!,
            onTap: () => Navigator.pop(context),
          ),
          Row(
            children: [
              Text(
                'Sáng tạo: Kỳ lân ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
                ),
              ),
              Text('🎨', style: TextStyle(fontSize: 18)),
            ],
          ),
          Row(
            children: [
              _buildAppBarButton(
                context: context,
                icon: Icons.check,
                color: Theme.of(context).cardColor,
                backgroundColor: Theme.of(context).primaryColor,
                onTap: () async {
                  await controller.markAsCompleted();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dự án đã được lưu vào Hoàn thành!')),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildAppBarButton(
                context: context,
                icon: Icons.block,
                color: Theme.of(context).colorScheme.error,
                text: 'ADS',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    String? text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(text != null ? 4.0 : 8.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: text != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Icon(icon, size: 24, color: color.withValues(alpha: 0.5)),
                ],
              )
            : Icon(icon, size: 24, color: color),
      ),
    );
  }
}