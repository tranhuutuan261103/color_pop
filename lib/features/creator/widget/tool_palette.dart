import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';
import 'tool_item.dart';

class ToolPalette extends StatelessWidget {
  final WorkspaceController controller;

  const ToolPalette({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ToolItem(
            index: 0,
            label: 'Tô màu',
            icon: Icons.format_color_fill,
            color: const Color(0xFF90CAF9),
            isSelected: controller.selectedToolIndex == 0,
            onTap: () => controller.updateTool(0),
          ),
          ToolItem(
            index: 1,
            label: 'Tẩy',
            icon: Icons.cleaning_services,
            color: const Color(0xFFF48FB1),
            isSelected: controller.selectedToolIndex == 1,
            onTap: () => controller.updateTool(1),
          ),
          ToolItem(
            index: 2,
            label: 'Cọ lớn',
            icon: Icons.brush,
            color: const Color(0xFFA5D6A7),
            isSelected: controller.selectedToolIndex == 2,
            onTap: () => controller.updateTool(2),
          ),
          ToolItem(
            index: 3,
            label: 'Bút chì',
            icon: Icons.edit,
            color: const Color(0xFFFFF59D),
            isSelected: controller.selectedToolIndex == 3,
            onTap: () => controller.updateTool(3),
          ),
          ToolItem(
            index: 4,
            label: 'Bình xịt',
            icon: Icons.blur_on,
            color: const Color(0xFFCE93D8),
            isSelected: controller.selectedToolIndex == 4,
            onTap: () => controller.updateTool(4),
          ),
        ],
      ),
    );
  }
}