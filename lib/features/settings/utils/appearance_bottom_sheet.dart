import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/theme_provider.dart';

class AppearanceBottomSheet {
  const AppearanceBottomSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) {
        return const _AppearanceContent();
      },
    );
  }
}

class _AppearanceContent extends StatefulWidget {
  const _AppearanceContent();

  @override
  State<_AppearanceContent> createState() => _AppearanceContentState();
}

class _AppearanceContentState extends State<_AppearanceContent> {
  late AppThemeMode _localThemeMode;

  @override
  void initState() {
    super.initState();
    // Lấy theme hiện tại ngay khi vừa mở BottomSheet (chỉ lấy 1 lần, không dùng listen)
    _localThemeMode = context.read<ThemeProvider>().appThemeMode;
  }

  void _handleThemeChange(AppThemeMode mode) {
    if (_localThemeMode == mode) return;

    // 1. Cập nhật UI cục bộ ngay lập tức để chạy Animation nút bấm cực mượt
    setState(() {
      _localThemeMode = mode;
    });

    // 2. Trì hoãn việc rebuild toàn App khoảng 150ms để nhường chỗ cho Animation
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.read<ThemeProvider>().setThemeMode(mode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Handle
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Appearance",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                "Choose your favorite theme",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              _ThemeOption(
                icon: Icons.light_mode_rounded,
                title: "Light",
                subtitle: "Bright and colorful",
                mode: AppThemeMode.light1,
                selected: _localThemeMode == AppThemeMode.light1,
                onTap: () => _handleThemeChange(AppThemeMode.light1),
              ),

              _ThemeOption(
                icon: Icons.sunny,
                title: "Soft Light",
                subtitle: "Warm pastel appearance",
                mode: AppThemeMode.light2,
                selected: _localThemeMode == AppThemeMode.light2,
                onTap: () => _handleThemeChange(AppThemeMode.light2),
              ),

              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                title: "Dark",
                subtitle: "Perfect for night",
                mode: AppThemeMode.dark,
                selected: _localThemeMode == AppThemeMode.dark,
                onTap: () => _handleThemeChange(AppThemeMode.dark),
              ),

              _ThemeOption(
                icon: Icons.phone_android_rounded,
                title: "Follow System",
                subtitle: "Use device settings",
                mode: AppThemeMode.system,
                selected: _localThemeMode == AppThemeMode.system,
                onTap: () => _handleThemeChange(AppThemeMode.system),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const animDuration = Duration(milliseconds: 350);
    const animCurve = Curves.easeInOut;

    return AnimatedContainer(
      duration: animDuration,
      curve: animCurve,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: animDuration,
                  curve: animCurve,
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(selected ? 20 : 16),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: animDuration,
                        curve: animCurve,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                        child: Text(title),
                      ),
                      const SizedBox(height: 4),

                      AnimatedDefaultTextStyle(
                        duration: animDuration,
                        curve: animCurve,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer.withValues(
                                  alpha: .75,
                                )
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        child: Text(subtitle),
                      ),
                    ],
                  ),
                ),

                AnimatedSwitcher(
                  duration: animDuration,
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: selected
                      ? Icon(
                          Icons.check_circle,
                          key: const ValueKey('checked'),
                          color: theme.colorScheme.primary,
                          size: 28,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          key: const ValueKey('unchecked'),
                          color: theme.colorScheme.outline,
                          size: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
