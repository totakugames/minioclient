import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class FileListItem extends StatelessWidget {
  final S3Object object;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const FileListItem({
    super.key,
    required this.object,
    required this.onTap,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Icon
            Icon(
              FileTypeHelper.getIcon(object),
              color: FileTypeHelper.getColor(object),
              size: 22,
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                object.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      object.isDirectory ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Size
            if (!object.isDirectory)
              SizedBox(
                width: 80,
                child: Text(
                  FileTypeHelper.formatSize(object.size),
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                  textAlign: TextAlign.right,
                ),
              ),
            // Date
            if (object.lastModified != null)
              SizedBox(
                width: 120,
                child: Text(
                  DateFormat('dd.MM.yy HH:mm').format(object.lastModified!),
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                  textAlign: TextAlign.right,
                ),
              ),
            // Actions
            const SizedBox(width: 8),
            if (onDownload != null)
              IconButton(
                icon: const Icon(Icons.download, size: 18),
                tooltip: 'Herunterladen',
                onPressed: onDownload,
                splashRadius: 16,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFFF6B6B)),
                tooltip: 'Löschen',
                onPressed: onDelete,
                splashRadius: 16,
              ),
          ],
        ),
      ),
    );
  }
}
