import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';
import '../constants/workspace_colors.dart';
import 'color_swatch.dart';

class ColorPalette extends StatelessWidget {
  final WorkspaceController controller;

  const ColorPalette({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (index) {
                return ColorSwatchWidget(
                  color: workspaceColors[index],
                  isSelected: controller.selectedColorIndex == index,
                  isWhite: index == 5, // Dựa theo vị trí màu trắng trong list
                  onTap: () => controller.updateColor(index),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (index) {
                final colorIndex = index + 8;
                return ColorSwatchWidget(
                  color: workspaceColors[colorIndex],
                  isSelected: controller.selectedColorIndex == colorIndex,
                  onTap: () => controller.updateColor(colorIndex),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}