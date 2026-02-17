import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class ConnectionProvider extends ChangeNotifier {
  final S3Service _s3Service;
  final ProfileStorageService _profileStorage;

  List<ConnectionProfile> _profiles = [];
  ConnectionProfile? _activeProfile;
  bool _isConnecting = false;
  String? _error;

  ConnectionProvider({
    required S3Service s3Service,
    required ProfileStorageService profileStorage,
  })  : _s3Service = s3Service,
        _profileStorage = profileStorage;

  // ── Getters ──────────────────────────────────────────────

  List<ConnectionProfile> get profiles => List.unmodifiable(_profiles);
  ConnectionProfile? get activeProfile => _activeProfile;
  bool get isConnected => _s3Service.isConnected;
  bool get isConnecting => _isConnecting;
  String? get error => _error;

  // ── Init ─────────────────────────────────────────────────

  Future<void> loadProfiles() async {
    _profiles = await _profileStorage.loadProfiles();
    notifyListeners();
  }

  // ── Connection ───────────────────────────────────────────

  Future<bool> connect(ConnectionProfile profile) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      _s3Service.connect(profile);
      final success = await _s3Service.testConnection();

      if (success) {
        _activeProfile = profile;
        _isConnecting = false;
        notifyListeners();
        return true;
      } else {
        _s3Service.disconnect();
        _error = 'Verbindung fehlgeschlagen. Überprüfe deine Zugangsdaten.';
        _isConnecting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _s3Service.disconnect();
      _error = 'Verbindungsfehler: ${e.toString()}';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    _s3Service.disconnect();
    _activeProfile = null;
    notifyListeners();
  }

  // ── Profile CRUD ─────────────────────────────────────────

  Future<void> addProfile(ConnectionProfile profile) async {
    await _profileStorage.addProfile(profile);
    _profiles = await _profileStorage.loadProfiles();
    notifyListeners();
  }

  Future<void> removeProfile(String id) async {
    if (_activeProfile?.id == id) {
      disconnect();
    }
    await _profileStorage.removeProfile(id);
    _profiles = await _profileStorage.loadProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(ConnectionProfile profile) async {
    await _profileStorage.updateProfile(profile);
    _profiles = await _profileStorage.loadProfiles();
    notifyListeners();
  }
}
