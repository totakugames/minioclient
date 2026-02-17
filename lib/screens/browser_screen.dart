import 'package:flutter/material.dart';
import 'package:minio_desktop_client/models/s3_object.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'connection_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top bar
          _buildTopBar(context),
          const Divider(height: 1),
          // Breadcrumbs
          _buildBreadcrumbs(context),
          const Divider(height: 1),
          // File list with drag & drop
          Expanded(child: _buildFileArea(context)),
          // Transfer panel
          const TransferPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    final browser = context.read<FileBrowserProvider>();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          // Connection info
          const Icon(Icons.cloud_done, size: 18, color: Color(0xFF45D9A8)),
          const SizedBox(width: 8),
          Text(
            conn.activeProfile?.name ?? 'Verbunden',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Spacer(),
          // Actions
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, size: 20),
            tooltip: 'Neuer Ordner',
            onPressed: browser.isInBucket
                ? () => _createDirectory(context)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, size: 20),
            tooltip: 'Dateien hochladen',
            onPressed: browser.isInBucket ? () => _uploadFiles(context) : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Aktualisieren',
            onPressed: () => browser.refresh(),
          ),
          const SizedBox(width: 8),
          const VerticalDivider(indent: 12, endIndent: 12),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Trennen',
            onPressed: () {
              conn.disconnect();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ConnectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    return Selector<
      FileBrowserProvider,
      ({
        String? currentBucket,
        List<String> pathSegments,
        bool isInBucket,
        bool isInSubdirectory,
      })
    >(
      selector: (_, b) => (
        currentBucket: b.currentBucket,
        pathSegments: b.pathSegments,
        isInBucket: b.isInBucket,
        isInSubdirectory: b.isInSubdirectory,
      ),
      builder: (context, state, _) {
        final browser = context.read<FileBrowserProvider>();
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (state.isInBucket)
                InkWell(
                  onTap: state.isInSubdirectory
                      ? () => browser.goUp()
                      : () => browser.goToBucketList(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back, size: 18),
                  ),
                ),
              InkWell(
                onTap: () => browser.goToBucketList(),
                child: const Text(
                  'Buckets',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              if (state.currentBucket != null) ...[
                const Text(
                  ' / ',
                  style: TextStyle(fontSize: 12, color: Colors.white24),
                ),
                InkWell(
                  onTap: () => browser.openBucket(state.currentBucket!),
                  child: Text(
                    state.currentBucket!,
                    style: TextStyle(
                      fontSize: 12,
                      color: state.pathSegments.isEmpty
                          ? Colors.white
                          : Colors.white54,
                      fontWeight: state.pathSegments.isEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                ...state.pathSegments.asMap().entries.map((entry) {
                  final isLast = entry.key == state.pathSegments.length - 1;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        ' / ',
                        style: TextStyle(fontSize: 12, color: Colors.white24),
                      ),
                      InkWell(
                        onTap: isLast
                            ? null
                            : () => browser.navigateToSegment(entry.key),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: isLast ? Colors.white : Colors.white54,
                            fontWeight: isLast
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileArea(BuildContext context) {
    return Selector<
      FileBrowserProvider,
      ({bool isLoading, String? error, bool isInBucket})
    >(
      selector: (_, b) =>
          (isLoading: b.isLoading, error: b.error, isInBucket: b.isInBucket),
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFFF6B6B),
                ),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<FileBrowserProvider>().refresh(),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }

        if (!state.isInBucket) {
          return _buildBucketList(context, context.read<FileBrowserProvider>());
        }

        return DropTarget(
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          onDragDone: (details) {
            setState(() => _isDragging = false);
            final browser = context.read<FileBrowserProvider>();
            final paths = details.files.map((f) => f.path).toList();
            context.read<TransferProvider>().uploadDroppedFiles(
              bucket: browser.currentBucket!,
              prefix: browser.currentPrefix,
              filePaths: paths,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: _isDragging
                  ? Border.all(color: const Color(0xFF6C63FF), width: 2)
                  : null,
              color: _isDragging
                  ? const Color(0xFF6C63FF).withOpacity(0.05)
                  : null,
            ),
            child: Selector<FileBrowserProvider, List<S3Object>>(
              selector: (_, b) => b.objects,
              builder: (context, objects, _) {
                return objects.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: objects.length,
                        itemBuilder: (context, index) {
                          final obj = objects[index];
                          return RepaintBoundary(
                            child: FileListItem(
                              object: obj,
                              onTap: () {
                                if (obj.isDirectory) {
                                  context
                                      .read<FileBrowserProvider>()
                                      .openDirectory(obj.key);
                                }
                              },
                              onDownload: obj.isDirectory
                                  ? () => context
                                        .read<TransferProvider>()
                                        .downloadDirectory(
                                          bucket: context
                                              .read<FileBrowserProvider>()
                                              .currentBucket!,
                                          prefix: obj.key,
                                          dirName: obj.name,
                                        )
                                  : () => context
                                        .read<TransferProvider>()
                                        .downloadFile(
                                          bucket: context
                                              .read<FileBrowserProvider>()
                                              .currentBucket!,
                                          key: obj.key,
                                          fileName: obj.name,
                                        ),
                              onDelete: () => _confirmDelete(context, obj),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBucketList(BuildContext context, FileBrowserProvider browser) {
    if (browser.buckets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Keine Buckets vorhanden',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Bucket erstellen'),
              onPressed: () => _createBucket(context),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ...browser.buckets.map(
          (bucket) => ListTile(
            leading: const Icon(
              Icons.storage,
              color: Color(0xFF6C63FF),
              size: 22,
            ),
            title: Text(bucket),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => browser.openBucket(bucket),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDragging ? Icons.file_download : Icons.folder_open,
            size: 64,
            color: _isDragging ? const Color(0xFF6C63FF) : Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _isDragging
                ? 'Dateien hier ablegen'
                : 'Ordner ist leer — Dateien hierher ziehen',
            style: TextStyle(
              color: _isDragging ? const Color(0xFF6C63FF) : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────

  Future<void> _createDirectory(BuildContext context) async {
    final name = await _showInputDialog(
      context,
      title: 'Neuer Ordner',
      hint: 'Ordnername',
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<FileBrowserProvider>().createDirectory(name);
    }
  }

  Future<void> _createBucket(BuildContext context) async {
    final name = await _showInputDialog(
      context,
      title: 'Neuer Bucket',
      hint: 'bucket-name (nur Kleinbuchstaben, Zahlen, Bindestriche)',
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<FileBrowserProvider>().createBucket(name);
    }
  }

  Future<void> _uploadFiles(BuildContext context) async {
    final browser = context.read<FileBrowserProvider>();
    context.read<TransferProvider>().pickAndUploadFiles(
      bucket: browser.currentBucket!,
      prefix: browser.currentPrefix,
    );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic obj) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text('Möchtest du "${obj.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<FileBrowserProvider>().deleteObject(obj);
    }
  }

  Future<String?> _showInputDialog(
    BuildContext context, {
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }
}
