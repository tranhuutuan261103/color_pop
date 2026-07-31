import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';
import 'toolbar_button.dart';
import 'small_dot.dart';

class BottomToolbar extends StatelessWidget {
  final WorkspaceController controller;

  const BottomToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const ToolbarButton(
            icon: Icons.access_time,
            iconColor: Colors.black87,
            backgroundColor: Color(0xFFB3E5FC),
          ),
          const ToolbarButton(icon: Icons.colorize, iconColor: Colors.black87),
          const Icon(Icons.chevron_left, color: Colors.grey, size: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SmallDot(color: Color(0xFF673AB7)),
                            SizedBox(width: 2),
                            SmallDot(color: Color(0xFF03A9F4)),
                            SizedBox(width: 2),
                            SmallDot(color: Color(0xFF2196F3)),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SmallDot(color: Color(0xFF4CAF50)),
                            SizedBox(width: 2),
                            SmallDot(color: Colors.black),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Text('Basic', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 30),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF03A9F4),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.togglePanMode,
            child: ToolbarButton(
              icon: controller.isPanMode ? Icons.draw : Icons.open_in_full,
              iconColor: controller.isPanMode
                  ? Theme.of(context).primaryColorDark
                  : Colors.black54,
              backgroundColor: controller.isPanMode
                  ? Theme.of(context).primaryColorLight
                  : Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }
}