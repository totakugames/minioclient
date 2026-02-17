import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class FileBrowserProvider extends ChangeNotifier {
  final S3Service _s3Service;

  List<String> _buckets = [];
  String? _currentBucket;
  String _currentPrefix = '';
  List<S3Object> _objects = [];
  bool _isLoading = false;
  String? _error;

  // Navigation history for breadcrumbs
  List<String> get pathSegments {
    if (_currentPrefix.isEmpty) return [];
    return _currentPrefix
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  FileBrowserProvider({required S3Service s3Service})
      : _s3Service = s3Service;

  // ── Getters ──────────────────────────────────────────────

  List<String> get buckets => List.unmodifiable(_buckets);
  String? get currentBucket => _currentBucket;
  String get currentPrefix => _currentPrefix;
  List<S3Object> get objects => List.unmodifiable(_objects);
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isInBucket => _currentBucket != null;
  bool get isInSubdirectory => _currentPrefix.isNotEmpty;
  bool get canGoUp => isInSubdirectory;

  // ── Bucket Operations ────────────────────────────────────

  Future<void> loadBuckets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _buckets = await _s3Service.listBuckets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Laden der Buckets: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBucket(String name) async {
    try {
      await _s3Service.createBucket(name);
      await loadBuckets();
    } catch (e) {
      _error = 'Fehler beim Erstellen des Buckets: $e';
      notifyListeners();
    }
  }

  // ── Navigation ───────────────────────────────────────────

  Future<void> openBucket(String bucket) async {
    _currentBucket = bucket;
    _currentPrefix = '';
    await _loadObjects();
  }

  Future<void> openDirectory(String dirKey) async {
    _currentPrefix = dirKey;
    await _loadObjects();
  }

  Future<void> navigateToSegment(int segmentIndex) async {
    // Navigate to a specific breadcrumb segment
    final segments = pathSegments;
    if (segmentIndex < 0) {
      // Go to bucket root
      _currentPrefix = '';
    } else if (segmentIndex < segments.length) {
      _currentPrefix =
          '${segments.sublist(0, segmentIndex + 1).join('/')}/';
    }
    await _loadObjects();
  }

  Future<void> goUp() async {
    if (!canGoUp) return;
    final segments = pathSegments;
    if (segments.length <= 1) {
      _currentPrefix = '';
    } else {
      _currentPrefix =
          '${segments.sublist(0, segments.length - 1).join('/')}/';
    }
    await _loadObjects();
  }

  void goToBucketList() {
    _currentBucket = null;
    _currentPrefix = '';
    _objects = [];
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentBucket != null) {
      await _loadObjects();
    } else {
      await loadBuckets();
    }
  }

  // ── Object Operations ────────────────────────────────────

  Future<void> createDirectory(String name) async {
    if (_currentBucket == null) return;
    try {
      final path = '$_currentPrefix$name/';
      await _s3Service.createDirectory(_currentBucket!, path);
      await _loadObjects();
    } catch (e) {
      _error = 'Fehler beim Erstellen des Ordners: $e';
      notifyListeners();
    }
  }

  Future<void> deleteObject(S3Object obj) async {
    if (_currentBucket == null) return;
    try {
      if (obj.isDirectory) {
        await _s3Service.deleteDirectory(_currentBucket!, obj.key);
      } else {
        await _s3Service.deleteObject(_currentBucket!, obj.key);
      }
      await _loadObjects();
    } catch (e) {
      _error = 'Fehler beim Löschen: $e';
      notifyListeners();
    }
  }

  // ── Internal ─────────────────────────────────────────────

  Future<void> _loadObjects() async {
    if (_currentBucket == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _objects = await _s3Service.listObjects(
        _currentBucket!,
        prefix: _currentPrefix,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Laden: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
