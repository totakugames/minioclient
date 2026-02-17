import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class TransferPanel extends StatefulWidget {
  const TransferPanel({super.key});

  @override
  State<TransferPanel> createState() => _TransferPanelState();
}

class _TransferPanelState extends State<TransferPanel> {
  bool _expanded = false;

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '';
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (context, transfer, _) {
        if (transfer.tasks.isEmpty) return const SizedBox.shrink();

        final active = transfer.activeTasks;
        final allTasks = transfer.tasks;
        final totalProgress = allTasks.isEmpty
            ? 1.0
            : allTasks.fold(0.0, (sum, t) => sum + t.progress) /
                  allTasks.length;
        final totalSpeed = active.fold(
          0.0,
          (sum, t) => sum + t.speedBytesPerSecond,
        );

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Kompakter Header mit Gesamtfortschritt ──
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_vert, size: 18),
                      const SizedBox(width: 8),
                      // Gesamtfortschrittsbalken
                      Expanded(
                        child: RepaintBoundary(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: totalProgress),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            builder: (context, value, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        active.isNotEmpty
                                            ? '${active.length} Transfer${active.length > 1 ? 's' : ''} aktiv'
                                            : 'Alle Transfers abgeschlossen',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (active.isNotEmpty) ...[
                                        Text(
                                          '${(value * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6C63FF),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatSpeed(totalSpeed),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (active.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: value,
                                      minHeight: 3,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).dividerColor,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF6C63FF),
                                          ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (transfer.completedTasks.isNotEmpty)
                        TextButton(
                          onPressed: transfer.clearCompleted,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Fertige entfernen',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Aufklappbare Detailliste ──
              if (_expanded) ...[
                Divider(height: 1, color: Theme.of(context).dividerColor),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: transfer.tasks.length,
                    itemBuilder: (context, index) {
                      final task = transfer.tasks[index];
                      return _TransferItem(
                        task: task,
                        formatSpeed: _formatSpeed,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TransferItem extends StatelessWidget {
  final TransferTask task;
  final String Function(double) formatSpeed;

  const _TransferItem({required this.task, required this.formatSpeed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            task.type == TransferType.upload ? Icons.upload : Icons.download,
            size: 16,
            color: _statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.fileName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.status == TransferStatus.inProgress) ...[
                      Text(
                        '${(task.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatSpeed(task.speedBytesPerSecond),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (task.status == TransferStatus.inProgress)
                  LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 3,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF),
                    ),
                  ),
                if (task.status == TransferStatus.failed)
                  Text(
                    task.errorMessage ?? 'Fehler',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFFF6B6B),
                    ),
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
