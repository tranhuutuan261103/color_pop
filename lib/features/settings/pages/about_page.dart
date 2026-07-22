import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appName = "ColorPop";
  static const String version = "1.0.0";
  static const String description =
      "ColorPop is an AI-powered coloring app that transforms photos into beautiful coloring pages for kids and adults. Create, color, save and share your artwork in just a few taps.";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          //----------------------------------------
          // App Info
          //----------------------------------------

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [

                  CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: .12),
                    child: Icon(
                      Icons.palette,
                      size: 42,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Version $version",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          //----------------------------------------
          // Information
          //----------------------------------------

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [

                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text("Privacy Policy"),
                  subtitle:
                      const Text("How we collect and protect your data"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO:
                    // Open Privacy Policy
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text("Terms of Service"),
                  subtitle:
                      const Text("Read the terms and conditions"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO:
                    // Open Terms
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text("Open Source Licenses"),
                  subtitle:
                      const Text("Third-party libraries used"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: appName,
                      applicationVersion: version,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          //----------------------------------------
          // Contact
          //----------------------------------------

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [

                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("Contact"),
                  subtitle:
                      const Text("support@colorpop.app"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO:
                    // Launch email
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Website"),
                  subtitle:
                      const Text("www.colorpop.app"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO:
                    // Launch website
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text("Rate ColorPop"),
                  subtitle:
                      const Text("Enjoying the app? Leave a review."),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO:
                    // Open Google Play / App Store
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          //----------------------------------------
          // Footer
          //----------------------------------------

          Center(
            child: Column(
              children: [

                Text(
                  "Made with ❤️ using Flutter",
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(height: 8),

                Text(
                  "© 2026 ColorPop",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}