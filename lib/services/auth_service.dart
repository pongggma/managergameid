import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Who is using the app, shown in Settings.
class Account {
  const Account(
      {required this.uid,
      required this.name,
      required this.email,
      required this.photoUrl,
      required this.provider});

  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String provider; // 'google.com' | 'facebook.com' | ''

  String get providerLabel => provider == 'google.com'
      ? 'Google'
      : (provider == 'facebook.com'
          ? 'Facebook'
          : (provider == 'password' ? 'ອີເມລ' : ''));
}

/// Login with Google or Facebook through Firebase Auth, plus a "use without
/// login" guest mode so the app still works before Firebase is configured
/// (and on desktop, where Google / Facebook sign-in is not available).
class AuthService extends ChangeNotifier {
  static const _guestKey = 'ledger-guest';

  SharedPreferences? _prefs;
  bool _firebaseReady = false;
  bool _guest = false;
  User? _user;
  StreamSubscription<User?>? _sub;

  /// True when Firebase was found and started (google-services.json / plist present).
  bool get firebaseReady => _firebaseReady;

  /// Google / Facebook login only exists on Android and iOS.
  bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isGuest => _guest && _user == null;
  bool get signedIn => _user != null;
  /// Email + password accounts must confirm their email before using the app.
  /// (Google / Facebook accounts are not asked.)
  bool get needsVerification {
    final u = _user;
    if (u == null) return false;
    return u.providerData.any((p) => p.providerId == 'password') && !u.emailVerified;
  }

  bool get hasSession => signedIn || isGuest;

  Account? get account {
    final u = _user;
    if (u == null) return null;
    return Account(
      uid: u.uid,
      name: u.displayName ?? '',
      email: u.email ?? '',
      photoUrl: u.photoURL ?? '',
      provider:
          u.providerData.isNotEmpty ? u.providerData.first.providerId : '',
    );
  }

  static const _guestNameKey = 'ledger-guest-name';

  /// The name the person chose (signed-in: saved on the account, guest: on this device).
  /// Empty when none was set.
  String get profileName => signedIn ? (_user!.displayName ?? '') : (_prefs?.getString(_guestNameKey) ?? '');

  /// What to show as the user's name: chosen name, else email, else a guest label.
  String get displayLabel {
    if (profileName.isNotEmpty) return profileName;
    final e = _user?.email ?? '';
    if (e.isNotEmpty) return e;
    return signedIn ? 'ຜູ້ໃຊ້' : 'ບໍ່ໄດ້ເຂົ້າສູ່ລະບົບ';
  }

  /// Returns null on success or a Lao error message.
  Future<String?> setName(String name) async {
    final n = name.trim();
    try {
      if (signedIn) {
        await _user!.updateDisplayName(n.isEmpty ? null : n);
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
      } else {
        if (n.isEmpty) {
          await _prefs?.remove(_guestNameKey);
        } else {
          await _prefs?.setString(_guestNameKey, n);
        }
      }
      notifyListeners();
      return null;
    } catch (_) {
      return 'ບັນທຶກຊື່ບໍ່ສຳເລັດ ກວດອິນເຕີເນັດແລ້ວລອງໃໝ່';
    }
  }

  int _avatar = 0;

  /// Chosen profile character, 0..5 (see widgets/avatar.dart). Saved per account.
  int get avatar => _avatar;

  String get _avatarKey => 'ledger-avatar-${signedIn ? _user!.uid : 'guest'}';

  void _loadAvatar() {
    final saved = _prefs?.getInt(_avatarKey);
    if (saved != null) {
      _avatar = saved.clamp(0, 5);
    } else {
      // a stable default per account so people do not all start with the same one
      _avatar = signedIn ? _user!.uid.codeUnits.fold<int>(0, (a, b) => a + b) % 6 : 0;
    }
  }

  Future<void> setAvatar(int i) async {
    _avatar = i.clamp(0, 5);
    await _prefs?.setInt(_avatarKey, _avatar);
    notifyListeners();
  }

  /// Name of the local storage slot: guests keep the original ledger,
  /// every signed-in account gets its own.
  String get storageSuffix => signedIn ? _user!.uid : '';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Guest access is temporary. Do not persist it across launches, otherwise
    // returning users can bypass the login/register screen indefinitely.
    _guest = false;
    await _prefs!.remove(_guestKey);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseReady = true;
      _user = FirebaseAuth.instance.currentUser;
      _loadAvatar();
      _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
        _user = u;
        _loadAvatar();
        notifyListeners();
      });
    } catch (_) {
      _firebaseReady = false; // not configured yet: guest mode only
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Each sign-in method returns null on success or when the person cancels,
  /// and a Lao error message otherwise.
  Future<String?> signInWithGoogle() async {
    final pre = _precheck();
    if (pre != null) return pre;
    try {
      final g = await GoogleSignIn().signIn();
      if (g == null) return null; // cancelled
      final a = await g.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: a.accessToken, idToken: a.idToken);
      await FirebaseAuth.instance.signInWithCredential(cred);
      await _setGuest(false);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'ເຂົ້າສູ່ລະບົບດ້ວຍ Google ບໍ່ສຳເລັດ';
    }
  }

  Future<String?> signInWithFacebook() async {
    final pre = _precheck();
    if (pre != null) return pre;
    try {
      final r = await FacebookAuth.instance.login();
      if (r.status == LoginStatus.cancelled) return null;
      if (r.status != LoginStatus.success || r.accessToken == null)
        return 'ເຂົ້າສູ່ລະບົບດ້ວຍ Facebook ບໍ່ສຳເລັດ';
      final cred = FacebookAuthProvider.credential(r.accessToken!.tokenString);
      await FirebaseAuth.instance.signInWithCredential(cred);
      await _setGuest(false);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'ເຂົ້າສູ່ລະບົບດ້ວຍ Facebook ບໍ່ສຳເລັດ';
    }
  }

  /// Register with email + password (also sets the display name).
  Future<String?> registerWithEmail(
      String name, String email, String password) async {
    if (!_firebaseReady) return _notConfigured;
    try {
      final c = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      if (name.trim().isNotEmpty) {
        await c.user?.updateDisplayName(name.trim());
        await c.user?.reload();
        _user = FirebaseAuth.instance.currentUser;
      }
      try {
        await _user?.sendEmailVerification();
      } catch (_) {}
      await _setGuest(false);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'ສະໝັກບໍ່ສຳເລັດ';
    }
  }

  /// Sends the confirmation email again. Null on success.
  Future<String?> resendVerification() async {
    try {
      await _user?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'ສົ່ງອີເມລບໍ່ສຳເລັດ';
    }
  }

  /// Re-reads the account from Firebase. Returns true once the email is confirmed.
  Future<bool> checkVerified() async {
    try {
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    notifyListeners();
    return !needsVerification;
  }

  Future<String?> signInWithEmail(String email, String password) async {
    if (!_firebaseReady) return _notConfigured;
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      await _setGuest(false);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ';
    }
  }

  /// Sends a reset link to [email].
  Future<String?> resetPassword(String email) async {
    if (!_firebaseReady) return _notConfigured;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'ສົ່ງລິ້ງບໍ່ສຳເລັດ';
    }
  }

  static const _notConfigured =
      'ຍັງບໍ່ໄດ້ຕັ້ງຄ່າ Firebase (ເບິ່ງ README ຫົວຂໍ້ Login)';

  String? _precheck() {
    if (!platformSupported)
      return 'Google / Facebook ໃຊ້ໄດ້ສະເພາະ Android ແລະ iOS';
    if (!_firebaseReady) return _notConfigured;
    return null;
  }

  String _msg(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'ອີເມລນີ້ເຄີຍສະໝັກດ້ວຍວິທີອື່ນແລ້ວ ລອງເຂົ້າດ້ວຍ Google ແທນ Facebook (ຫຼືກົງກັນຂ້າມ)';
      case 'email-already-in-use':
        return 'ອີເມລນີ້ມີບັນຊີແລ້ວ ລອງເຂົ້າສູ່ລະບົບ';
      case 'invalid-email':
        return 'ຮູບແບບອີເມລບໍ່ຖືກຕ້ອງ';
      case 'weak-password':
        return 'ລະຫັດຜ່ານງ່າຍເກີນໄປ (ຢ່າງໜ້ອຍ 6 ຕົວ)';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'ອີເມລ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກ';
      case 'too-many-requests':
        return 'ລອງຫຼາຍເກີນໄປ ລໍຖ້າສັກຄູ່ແລ້ວລອງໃໝ່';
      case 'network-request-failed':
        return 'ບໍ່ມີອິນເຕີເນັດ';
      default:
        return 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ (${e.code})';
    }
  }

  Future<void> continueAsGuest() async {
    await _setGuest(true);
  }

  Future<void> _setGuest(bool v) async {
    _guest = v;
    await _prefs?.setBool(_guestKey, v);
    _loadAvatar();
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_firebaseReady) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    await _setGuest(false);
  }
}
