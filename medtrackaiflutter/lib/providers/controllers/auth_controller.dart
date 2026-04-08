import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../core/utils/logger.dart';

class AuthController extends ChangeNotifier {
  final IUserRepository userRepo;
  
  AppPhase _phase = AppPhase.loading;
  UserProfile? _profile;
  bool _isLocked = false;
  String _language = 'en';
  bool _isPurchasing = false;

  AuthController({required this.userRepo});

  AppPhase get phase => _phase;
  set phase(AppPhase p) {
    _phase = p;
    notifyListeners();
  }

  UserProfile? get profile => _profile;
  set profile(UserProfile? p) {
    _profile = p;
    notifyListeners();
  }

  bool get isLocked => _isLocked;
  set isLocked(bool v) {
    _isLocked = v;
    notifyListeners();
  }

  String get language => _language;
  bool get darkMode => _profile?.amoledMode ?? false;
  
  bool get isPurchasing => _isPurchasing;
  set isPurchasing(bool v) {
    _isPurchasing = v;
    notifyListeners();
  }

  bool get isAuthenticated => AuthService.uid != null;

  Future<void> loadProfile() async {
    try {
      _profile = await userRepo.getProfile();
      _language = await userRepo.getLanguage();
      if (_profile != null) {
        _phase = AppPhase.app;
        _isLocked = _profile?.biometricEnabled ?? false;
      } else {
        _phase = AppPhase.onboarding;
      }
      notifyListeners();
    } catch (e) {
      appLogger.e('[AuthController] Profile load failed', error: e);
      _phase = AppPhase.onboarding;
      notifyListeners();
    }
  }

  Future<void> updateProfileFromMap(Map<String, dynamic> data) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      name: data['name'] ?? _profile!.name,
      // mapping logic simplified just for stability
    );
    await saveProfile(updated);
  }


  Future<void> saveProfile(UserProfile p) async {
    _profile = p;
    _phase = AppPhase.app;
    if (p.preferredLanguage != _language) {
      _language = p.preferredLanguage;
      await userRepo.saveLanguage(_language);
    }
    await userRepo.saveProfile(p);
    notifyListeners();
  }

  void incrementScanCount() {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      scansUsed: (_profile!.scansUsed) + 1,
    );
    userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.signOut();
    _profile = null;
    _phase = AppPhase.auth;
    notifyListeners();
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    _phase = AppPhase.app;
    await userRepo.saveProfile(profile);
    notifyListeners();
  }

  void skipAuth() {
    _phase = AppPhase.app;
    notifyListeners();
  }

  void skipAuthOnboarding() {
    _phase = AppPhase.onboarding;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? accentColor, bool? amoledMode, bool? biometricEnabled}) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      name: name ?? _profile!.name,
      accentColor: accentColor ?? _profile!.accentColor,
      amoledMode: amoledMode ?? _profile!.amoledMode,
      biometricEnabled: biometricEnabled ?? _profile!.biometricEnabled,
    );
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  void toggleDarkMode() {
    if (_profile == null) return;
    updateProfile(amoledMode: !(_profile!.amoledMode));
  }

  void toggleBiometricLock(bool v) {
    if (_profile == null) return;
    updateProfile(biometricEnabled: v);
  }

  Future<void> manageSubscription() async {
    // Bridge to platform-specific store logic if needed
    appLogger.i('[Auth] Opening subscription management');
  }

  Future<void> signInWithGoogle() async {
    final user = await AuthService.signInWithGoogle();
    if (user != null) await loadProfile();
  }

  Future<void> signInWithApple() async {
    final user = await AuthService.signInWithApple();
    if (user != null) await loadProfile();
  }

  Future<void> updateAccentColor(String color) => updateProfile(accentColor: color);
  Future<void> updateAppIcon(String icon) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(appIcon: icon);
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }
  Future<void> updateReminderSound(String sound) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(reminderSound: sound);
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> incrementDosesMarked() async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      dosesMarked: (_profile!.dosesMarked) + 1,
    );
    await userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_profile == null) return;
    updateProfile(); // Trigger background sync if needed
    userRepo.saveLanguage(lang);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await AuthService.deleteAccount();
    _profile = null;
    _phase = AppPhase.auth;
    notifyListeners();
  }
}
