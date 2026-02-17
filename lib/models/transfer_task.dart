enum TransferType { upload, download }

enum TransferStatus { queued, inProgress, completed, failed, cancelled }

class TransferTask {
  final String id;
  final String localPath;
  final String remotePath;
  final String bucket;
  final TransferType type;
  TransferStatus status;
  double progress;
  int totalBytes;
  int transferredBytes;
  String? errorMessage;
  final DateTime createdAt;

  TransferTask({
    required this.id,
    required this.localPath,
    required this.remotePath,
    required this.bucket,
    required this.type,
    this.status = TransferStatus.queued,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.transferredBytes = 0,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fileName {
    final parts = localPath.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : localPath;
  }

  bool get isActive =>
      status == TransferStatus.queued || status == TransferStatus.inProgress;
}
