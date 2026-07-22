import 'package:flutter/material.dart';

import '../pages/about_page.dart';
import '../pages/user_guide_page.dart';
import '../utils/appearance_bottom_sheet.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Customize your ColorPop experience",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 28),

            //--------------------------------------------------
            // Appearance
            //--------------------------------------------------
            SettingsTile(
              icon: Icons.palette_outlined,
              title: "Appearance",
              subtitle: "Light, Dark and System theme",
              onTap: () {
                AppearanceBottomSheet.show(context);
              },
            ),

            //--------------------------------------------------
            // Language
            //--------------------------------------------------
            SettingsTile(
              icon: Icons.language_outlined,
              title: "Language",
              subtitle: "English",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Language selection is coming soon."),
                  ),
                );
              },
            ),

            //--------------------------------------------------
            // User Guide
            //--------------------------------------------------
            SettingsTile(
              icon: Icons.help_outline_rounded,
              title: "User Guide",
              subtitle: "Learn how to use ColorPop",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserGuidePage(),
                  ),
                );
              },
            ),

            //--------------------------------------------------
            // About
            //--------------------------------------------------
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: "About",
              subtitle: "Version 1.0.0",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),

            const Divider(),
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.palette,
                    size: 42,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "ColorPop",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Version 1.0.0",
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Made with ❤️ using Flutter",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}