import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'browser_screen.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Title
              const Icon(Icons.cloud_outlined, size: 64, color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              const Text(
                'Totaku Asset Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verbinde dich mit deinem MinIO Server',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),

              // Saved profiles
              Consumer<ConnectionProvider>(
                builder: (context, conn, _) {
                  if (conn.profiles.isEmpty) {
                    return const Text(
                      'Noch keine Verbindungen gespeichert.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gespeicherte Verbindungen',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...conn.profiles.map((profile) => Card(
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
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    onPressed: () =>
                                        conn.removeProfile(profile.id),
                                  ),
                                ],
                              ),
                              onTap: () => _connect(context, profile),
                            ),
                          )),
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
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFFF6B6B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(conn.error!,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFFF6B6B))),
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
                  label: const Text('Neue Verbindung'),
                  onPressed: () => _addProfile(context),
                ),
              ),
            ],
          ),
        ),
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
      // Load buckets and navigate
      context.read<FileBrowserProvider>().loadBuckets();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BrowserScreen()),
      );
    }
  }
}
