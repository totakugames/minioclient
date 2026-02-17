import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:minio_desktop_client/providers/file_browser_provider.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../services/services.dart';

class TransferProvider extends ChangeNotifier {
  final S3Service _s3Service;
  FileBrowserProvider? _fileBrowser;

  void setFileBrowser(FileBrowserProvider fileBrowser) {
    _fileBrowser = fileBrowser;
  }

  final List<TransferTask> _tasks = [];
  bool _isProcessing = false;
  DateTime? _lastNotify;

  TransferProvider({required S3Service s3Service}) : _s3Service = s3Service;

  // ── Getters ──────────────────────────────────────────────

  List<TransferTask> get tasks => List.unmodifiable(_tasks);
  List<TransferTask> get activeTasks =>
      _tasks.where((t) => t.isActive).toList();
  List<TransferTask> get completedTasks =>
      _tasks.where((t) => t.status == TransferStatus.completed).toList();
  bool get hasActiveTasks => _tasks.any((t) => t.isActive);

  // ── Upload ───────────────────────────────────────────────

  /// Pick and upload files via file picker
  Future<void> pickAndUploadFiles({
    required String bucket,
    required String prefix,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Dateien zum Upload auswählen',
    );

    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.path == null) continue;

      final remotePath = '$prefix${file.name}';

      final alreadyExists = _tasks.any(
        (t) =>
            t.remotePath == remotePath &&
            t.status != TransferStatus.failed &&
            t.status != TransferStatus.cancelled,
      );
      if (alreadyExists) continue;

      final task = TransferTask(
        id: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
        localPath: file.path!,
        remotePath: remotePath,
        bucket: bucket,
        type: TransferType.upload,
        totalBytes: file.size,
      );
      _tasks.insert(0, task);
    }

    notifyListeners();
    _processQueue();
  }

  void _throttledNotify() {
    final now = DateTime.now();
    if (_lastNotify == null ||
        now.difference(_lastNotify!).inMilliseconds > 500) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  /// Upload files from drag & drop
  Future<void> uploadDroppedFiles({
    required String bucket,
    required String prefix,
    required List<String> filePaths,
  }) async {
    for (final path in filePaths) {
      final file = File(path);
      final isDir = await FileSystemEntity.isDirectory(path);

      if (isDir) {
        final dirName = p.basename(path);
        final dir = Directory(path);
        final files = await dir
            .list(recursive: true)
            .where((e) => e is File)
            .cast<File>()
            .toList();

        for (final f in files) {
          final relativePath = p.relative(f.path, from: path);
          final remotePath = '$prefix$dirName/$relativePath'.replaceAll(
            '\\',
            '/',
          );
          final stat = await f.stat();

          final alreadyExists = _tasks.any(
            (t) =>
                t.remotePath == remotePath &&
                t.status != TransferStatus.failed &&
                t.status != TransferStatus.cancelled,
          );
          if (alreadyExists) continue;

          final task = TransferTask(
            id: '${DateTime.now().millisecondsSinceEpoch}_${f.path}',
            localPath: f.path,
            remotePath: remotePath,
            bucket: bucket,
            type: TransferType.upload,
            totalBytes: stat.size,
          );
          _tasks.insert(0, task);
        }
      } else {
        final stat = await file.stat();
        final fileName = p.basename(path);
        final remotePath = '$prefix$fileName';

        final alreadyExists = _tasks.any(
          (t) =>
              t.remotePath == remotePath &&
              t.status != TransferStatus.failed &&
              t.status != TransferStatus.cancelled,
        );
        if (alreadyExists) continue;

        final task = TransferTask(
          id: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
          localPath: path,
          remotePath: remotePath,
          bucket: bucket,
          type: TransferType.upload,
          totalBytes: stat.size,
        );
        _tasks.insert(0, task);
      }
    }

    notifyListeners();
    _processQueue();
  }

  // ── Download ─────────────────────────────────────────────

  /// Download a single file
  Future<void> downloadFile({
    required String bucket,
    required String key,
    required String fileName,
  }) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Speicherort wählen',
      fileName: fileName,
    );

    if (savePath == null) return;

    final task = TransferTask(
      id: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
      localPath: savePath,
      remotePath: key,
      bucket: bucket,
      type: TransferType.download,
    );

    _tasks.insert(0, task);
    notifyListeners();
    _processQueue();
  }

  /// Download a directory
  Future<void> downloadDirectory({
    required String bucket,
    required String prefix,
    required String dirName,
  }) async {
    final savePath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Speicherort für "$dirName" wählen',
    );

    if (savePath == null) return;

    final localDir = p.join(savePath, dirName);
    final task = TransferTask(
      id: '${DateTime.now().millisecondsSinceEpoch}_$dirName',
      localPath: localDir,
      remotePath: prefix,
      bucket: bucket,
      type: TransferType.download,
    );

    _tasks.insert(0, task);
    notifyListeners();
    _processQueue();
  }

  // ── Task Management ──────────────────────────────────────

  void clearCompleted() {
    _tasks.removeWhere(
      (t) =>
          t.status == TransferStatus.completed ||
          t.status == TransferStatus.failed,
    );
    notifyListeners();
  }

  void cancelTask(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TransferStatus.cancelled;
    notifyListeners();
  }

  // ── Queue Processing ─────────────────────────────────────

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_tasks.any((t) => t.status == TransferStatus.queued)) {
      final task = _tasks.firstWhere((t) => t.status == TransferStatus.queued);

      if (task.status == TransferStatus.cancelled) continue;

      task.status = TransferStatus.inProgress;
      notifyListeners();

      try {
        if (task.type == TransferType.upload) {
          task.startedAt = DateTime.now();
          await _s3Service.uploadFile(
            task.bucket,
            task.remotePath,
            task.localPath,
            onProgress: (transferred, total) {
              task.transferredBytes = transferred;
              task.totalBytes = total;
              task.progress = total > 0 ? transferred / total : 0;
              if (task.startedAt != null) {
                final elapsed =
                    DateTime.now().difference(task.startedAt!).inMilliseconds /
                    1000;
                if (elapsed > 0) {
                  task.speedBytesPerSecond = transferred / elapsed;
                }
              }
              _throttledNotify();
              //notifyListeners();
            },
          );
        } else {
          task.startedAt = DateTime.now();
          if (task.remotePath.endsWith('/')) {
            await _s3Service.downloadDirectory(
              task.bucket,
              task.remotePath,
              task.localPath,
            );
          } else {
            await _s3Service.downloadFile(
              task.bucket,
              task.remotePath,
              task.localPath,
              onProgress: (transferred, total) {
                task.transferredBytes = transferred;
                task.totalBytes = total;
                task.progress = total > 0 ? transferred / total : 0;
                if (task.startedAt != null) {
                  final elapsed =
                      DateTime.now()
                          .difference(task.startedAt!)
                          .inMilliseconds /
                      1000;
                  if (elapsed > 0) {
                    task.speedBytesPerSecond = transferred / elapsed;
                  }
                }
                _throttledNotify();
                //notifyListeners();
              },
            );
          }
        }

        task.status = TransferStatus.completed;
        task.progress = 1.0;
      } catch (e) {
        task.status = TransferStatus.failed;
        task.errorMessage = e.toString();
      }

      notifyListeners();
    }

    _isProcessing = false;
    _fileBrowser?.refresh();
  }
}
