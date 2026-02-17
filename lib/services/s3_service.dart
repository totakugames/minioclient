import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:minio/io.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class S3Service {
  Minio? _minio;
  ConnectionProfile? _currentProfile;

  bool get isConnected => _minio != null;
  ConnectionProfile? get currentProfile => _currentProfile;

  /// Connect to a MinIO/S3 endpoint
  void connect(ConnectionProfile profile) {
    _minio = Minio(
      endPoint: profile.endpoint,
      port: profile.port,
      useSSL: profile.useSSL,
      accessKey: profile.accessKey,
      secretKey: profile.secretKey,
      region: 'us-east-1',
      enableTrace: true, // ← nur diese Zeile neu
    );
    _currentProfile = profile;
  }

  /// Disconnect
  void disconnect() {
    _minio = null;
    _currentProfile = null;
  }

  Minio get _client {
    if (_minio == null) {
      throw StateError('Not connected. Call connect() first.');
    }
    return _minio!;
  }

  // ── Buckets ──────────────────────────────────────────────

  Future<List<String>> listBuckets() async {
    final buckets = await _client.listBuckets();
    return buckets.map((b) => b.name).toList();
  }

  Future<void> createBucket(String name) async {
    await _client.makeBucket(name);
  }

  Future<void> deleteBucket(String name) async {
    await _client.removeBucket(name);
  }

  // ── Objects ──────────────────────────────────────────────

  Future<List<S3Object>> listObjects(
    String bucket, {
    String prefix = '',
  }) async {
    final objects = <S3Object>[];
    final seenPrefixes = <String>{};

    // Use listAllObjects which returns a Future<ListObjectsResult>
    final result = await _client.listAllObjects(
      bucket,
      prefix: prefix,
      recursive: false,
    );

    // Normalize result: some versions of the Minio client return an object
    // with `contents` and `commonPrefixes`, others return an Iterable of
    // objects directly. Handle both shapes here.
    final List<dynamic> contents = <dynamic>[];
    final List<dynamic> prefixes = <dynamic>[];

    final dyn = result as dynamic;
    try {
      if (dyn.commonPrefixes != null) {
        prefixes.addAll((dyn.commonPrefixes as Iterable).cast<dynamic>());
      }
    } catch (_) {}
    try {
      if (dyn.contents != null) {
        contents.addAll((dyn.contents as Iterable).cast<dynamic>());
      }
    } catch (_) {}

    // Handle prefixes (directories)
    for (final cp in prefixes) {
      String dirKey = '';
      try {
        dirKey = (cp as dynamic).prefix ?? cp.toString();
      } catch (_) {
        dirKey = cp.toString();
      }
      if (dirKey.isEmpty) continue;
      if (seenPrefixes.add(dirKey)) {
        final dirName = dirKey
            .substring(prefix.length)
            .replaceAll(RegExp(r'/$'), '');
        if (dirName.isNotEmpty) {
          objects.add(S3Object(key: dirKey, name: dirName, isDirectory: true));
        }
      }
    }

    // Handle files from contents (or from iterable result)
    for (final obj in contents) {
      final key = (obj as dynamic).key ?? obj.toString();
      if (key == null || key == prefix || key.isEmpty) continue;

      final name = key.substring(prefix.length);
      if (name.isEmpty) continue;

      // Directory marker (key ending with /)
      if (name.endsWith('/')) {
        final dirName = name.substring(0, name.length - 1);
        if (dirName.isNotEmpty && seenPrefixes.add(key)) {
          objects.add(S3Object(key: key, name: dirName, isDirectory: true));
        }
      } else {
        objects.add(
          S3Object(
            key: key,
            name: name,
            isDirectory: false,
            size: (obj as dynamic).size,
            lastModified: (obj as dynamic).lastModified,
            etag: (obj as dynamic).eTag ?? (obj as dynamic).etag,
          ),
        );
      }
    }

    // Sort: directories first, then alphabetically
    objects.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return objects;
  }

  Future<void> createDirectory(String bucket, String path) async {
    final dirPath = path.endsWith('/') ? path : '$path/';
    await _client.putObject(bucket, dirPath, Stream<Uint8List>.empty());
  }

  Future<void> deleteObject(String bucket, String key) async {
    await _client.removeObject(bucket, key);
  }

  Future<void> deleteDirectory(String bucket, String prefix) async {
    final result = await _client.listAllObjects(
      bucket,
      prefix: prefix,
      recursive: true,
    );

    final List<dynamic> contents = <dynamic>[];
    try {
      final dyn = result as dynamic;
      if (dyn.contents != null) {
        contents.addAll((dyn.contents as Iterable).cast<dynamic>());
      }
    } catch (_) {}

    for (final obj in contents) {
      try {
        final key = (obj as dynamic).key;
        if (key != null) {
          await _client.removeObject(bucket, key);
        }
      } catch (_) {}
    }
  }

  // ── Upload / Download ────────────────────────────────────

  Future<void> uploadFile(
    String bucket,
    String remotePath,
    String localPath, {
    void Function(int transferred, int total)? onProgress,
  }) async {
    final file = File(localPath);
    final fileSize = await file.length();

    // Use fPutObject from MinioX extension (import minio/io.dart)
    await _client.fPutObject(
      bucket,
      remotePath,
      localPath,
      onProgress: onProgress != null
          ? (bytes) => onProgress(bytes, fileSize)
          : null,
    );
  }

  Future<void> uploadDirectory(
    String bucket,
    String remotePrefix,
    String localDirPath, {
    void Function(String fileName, int fileIndex, int totalFiles)?
    onFileProgress,
  }) async {
    final dir = Directory(localDirPath);
    final files = await dir
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = p.relative(file.path, from: localDirPath);
      final remotePath = '$remotePrefix$relativePath'.replaceAll('\\', '/');

      onFileProgress?.call(relativePath, i, files.length);
      await uploadFile(bucket, remotePath, file.path);
    }
  }

  Future<void> downloadFile(
    String bucket,
    String remotePath,
    String localPath, {
    void Function(int transferred, int total)? onProgress,
  }) async {
    final stat = await _client.statObject(bucket, remotePath);
    final totalSize = stat.size ?? 0;

    final stream = await _client.getObject(bucket, remotePath);

    final file = File(localPath);
    await file.parent.create(recursive: true);

    final sink = file.openWrite();
    var transferred = 0;

    await for (final chunk in stream) {
      sink.add(chunk);
      transferred += chunk.length;
      onProgress?.call(transferred, totalSize);
    }

    await sink.flush();
    await sink.close();
  }

  Future<void> downloadDirectory(
    String bucket,
    String remotePrefix,
    String localDirPath, {
    void Function(String fileName, int fileIndex, int totalFiles)?
    onFileProgress,
  }) async {
    final keys = <String>[];
    final result = await _client.listAllObjects(
      bucket,
      prefix: remotePrefix,
      recursive: true,
    );

    final List<dynamic> contents = <dynamic>[];
    try {
      final dyn = result as dynamic;
      if (dyn.contents != null) {
        contents.addAll((dyn.contents as Iterable).cast<dynamic>());
      }
    } catch (_) {}

    for (final obj in contents) {
      try {
        final key = (obj as dynamic).key;
        if (key != null && !key.endsWith('/')) {
          keys.add(key);
        }
      } catch (_) {}
    }

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final relativePath = key.substring(remotePrefix.length);
      final localPath = p.join(localDirPath, relativePath);

      onFileProgress?.call(relativePath, i, keys.length);
      await downloadFile(bucket, key, localPath);
    }
  }

  // ── Utility ──────────────────────────────────────────────

  Future<bool> testConnection() async {
    try {
      await _client.listBuckets();
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('access key') || msg.contains('does not exist')) {
        throw Exception(
          'Ungültiger Access Key. Bitte überprüfe deine Zugangsdaten.',
        );
      } else if (msg.contains('signature') || msg.contains('secret')) {
        throw Exception(
          'Ungültiger Secret Key. Bitte überprüfe dein Passwort.',
        );
      } else if (msg.contains('socket') ||
          msg.contains('connection refused') ||
          msg.contains('host')) {
        throw Exception('Server nicht erreichbar. Überprüfe Adresse und Port.');
      }
      throw Exception('Verbindungsfehler: $e');
    }
  }

  Future<String> getPresignedUrl(
    String bucket,
    String key, {
    int expirySeconds = 3600,
  }) async {
    return await _client.presignedGetObject(
      bucket,
      key,
      expires: expirySeconds,
    );
  }
}
