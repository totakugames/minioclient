import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'browser_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    //await prefs.setBool('has_launched', false); // debug reset
    final hasLaunched = prefs.getBool('has_launched') ?? false;

    if (!hasLaunched && mounted) {
      await prefs.setBool('has_launched', true);

      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Color(0xFF6C63FF), size: 24),
            const SizedBox(width: 10),
            const Text('Welcome!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for using our S3 / MinIO Desktop Client!',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'If you\'d like to support our work, consider checking out our games.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe later'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Visit our website'),
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse('https://totakugames.studio'));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Center(
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title
                  const Icon(
                    Icons.cloud_outlined,
                    size: 64,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'S3 / MinIO Desktop Client',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect to your S3 / MinIO server',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 32),

                  // Saved profiles
                  Consumer<ConnectionProvider>(
                    builder: (context, conn, _) {
                      if (conn.profiles.isEmpty) {
                        return const Text(
                          'No saved connections yet.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved Connections',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...conn.profiles.map(
                            (profile) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.dns),
                                title: Text(profile.name),
                                subtitle: Text(
                                  '${profile.endpoint}:${profile.port}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () =>
                                          _editProfile(context, profile),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          conn.removeProfile(profile.id),
                                    ),
                                  ],
                                ),
                                onTap: () => _connect(context, profile),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Error message
                  Consumer<ConnectionProvider>(
                    builder: (context, conn, _) {
                      if (conn.error == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFFF6B6B),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                conn.error!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFF6B6B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Loading indicator
                  Consumer<ConnectionProvider>(
                    builder: (context, conn, _) {
                      if (!conn.isConnecting) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(),
                      );
                    },
                  ),

                  // Add connection button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Connection'),
                      onPressed: () => _addProfile(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer link - bottom right
          Positioned(
            bottom: 16,
            right: 16,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse('https://totakugames.studio')),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Made by ',
                      style: TextStyle(fontSize: 11, color: Colors.white24),
                    ),
                    Text(
                      'Totaku Games',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(
                          0xFF6C63FF,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProfile(BuildContext context) async {
    final profile = await showDialog<dynamic>(
      context: context,
      builder: (_) => const ConnectionDialog(),
    );
    if (profile != null && context.mounted) {
      final conn = context.read<ConnectionProvider>();
      await conn.addProfile(profile);
    }
  }

  Future<void> _editProfile(BuildContext context, dynamic existing) async {
    final profile = await showDialog<dynamic>(
      context: context,
      builder: (_) => ConnectionDialog(existingProfile: existing),
    );
    if (profile != null && context.mounted) {
      final conn = context.read<ConnectionProvider>();
      await conn.updateProfile(profile);
    }
  }

  Future<void> _connect(BuildContext context, dynamic profile) async {
    final conn = context.read<ConnectionProvider>();
    final success = await conn.connect(profile);

    if (success && context.mounted) {
      context.read<FileBrowserProvider>().loadBuckets();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BrowserScreen()),
      );
    }
  }
}
