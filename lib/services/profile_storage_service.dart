import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ProfileStorageService {
  static const _key = 'connection_profiles';

  Future<List<ConnectionProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => ConnectionProfile.decode(e)).toList();
  }

  Future<void> saveProfiles(List<ConnectionProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = profiles.map((p) => p.encode()).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<void> addProfile(ConnectionProfile profile) async {
    final profiles = await loadProfiles();
    profiles.add(profile);
    await saveProfiles(profiles);
  }

  Future<void> removeProfile(String id) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await saveProfiles(profiles);
  }

  Future<void> updateProfile(ConnectionProfile profile) async {
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      profiles[index] = profile;
      await saveProfiles(profiles);
    }
  }
}
