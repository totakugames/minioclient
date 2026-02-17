import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class TransferPanel extends StatelessWidget {
  const TransferPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (context, transfer, _) {
        if (transfer.tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Transfers (${transfer.activeTasks.length} aktiv)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    if (transfer.completedTasks.isNotEmpty)
                      TextButton(
                        onPressed: transfer.clearCompleted,
                        child: const Text('Abgeschlossene entfernen',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Task list
              Expanded(
                child: ListView.builder(
                  itemCount: transfer.tasks.length,
                  itemBuilder: (context, index) {
                    final task = transfer.tasks[index];
                    return _TransferItem(task: task);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransferItem extends StatelessWidget {
  final TransferTask task;

  const _TransferItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            task.type == TransferType.upload
                ? Icons.upload
                : Icons.download,
            size: 16,
            color: _statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (task.status == TransferStatus.inProgress)
                  LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 3,
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                if (task.status == TransferStatus.failed)
                  Text(
                    task.errorMessage ?? 'Fehler',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFFF6B6B)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (task.totalBytes > 0)
            Text(
              FileTypeHelper.formatSize(task.totalBytes),
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          const SizedBox(width: 8),
          _StatusBadge(status: task.status),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (task.status) {
      case TransferStatus.queued:
        return Colors.white38;
      case TransferStatus.inProgress:
        return const Color(0xFF6C63FF);
      case TransferStatus.completed:
        return const Color(0xFF45D9A8);
      case TransferStatus.failed:
        return const Color(0xFFFF6B6B);
      case TransferStatus.cancelled:
        return Colors.white24;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TransferStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TransferStatus.queued => ('Wartend', Colors.white38),
      TransferStatus.inProgress => ('Läuft', const Color(0xFF6C63FF)),
      TransferStatus.completed => ('Fertig', const Color(0xFF45D9A8)),
      TransferStatus.failed => ('Fehler', const Color(0xFFFF6B6B)),
      TransferStatus.cancelled => ('Abgebrochen', Colors.white24),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
