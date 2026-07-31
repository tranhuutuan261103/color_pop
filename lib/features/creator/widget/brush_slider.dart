import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';

class BrushSlider extends StatelessWidget {
  final WorkspaceController controller;

  const BrushSlider({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 12,
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            thumbColor: Theme.of(context).primaryColorDark,
            overlayColor: Theme.of(context).primaryColorDark.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: controller.sliderValue,
            onChanged: (value) => controller.updateSlider(value),
          ),
        ),
      ),
    );
  }
}