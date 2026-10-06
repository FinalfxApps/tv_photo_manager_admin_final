import 'package:firebase_auth/firebase_auth.dart';

class TenantSession {
  static String? _tenantId;
  static String? _role;
  static String? _username;
  static String? _displayName;

  static String get tenantId => _tenantId ?? '';
  static String get role => _role ?? '';
  static String get username => _username ?? '';
  static String get displayName =>
      (_displayName?.trim().isNotEmpty == true)
          ? _displayName!.trim()
          : (_username?.trim().isNotEmpty == true ? _username!.trim() : 'Workspace');

  static bool get isSuperAdmin => _role == 'superAdmin';
  static bool get isCustomerAdmin => _role == 'customerAdmin';

  static String requireTenant() {
    final value = _tenantId;
    if (value == null || value.isEmpty) {
      throw StateError('No customer workspace is loaded.');
    }
    return value;
  }

  static Future<void> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      clear();
      return;
    }

    // Force-refresh so newly assigned role/tenant claims are available
    // immediately after customer creation or first sign-in.
    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? <String, dynamic>{};

    final role = claims['role']?.toString() ?? '';
    final tenant = claims['tenantId']?.toString() ?? '';

    if (role == 'superAdmin') {
      _role = role;
      _tenantId = null;
    } else if (role == 'customerAdmin' && tenant.isNotEmpty) {
      _role = role;
      _tenantId = tenant;
    } else {
      clear();
      throw StateError(
        'This account is not linked to a Final FX TV workspace.',
      );
    }

    _username =
        claims['username']?.toString() ??
        user.email?.split('@').first ??
        '';
    _displayName = user.displayName ?? '';
  }

  static void clear() {
    _tenantId = null;
    _role = null;
    _username = null;
    _displayName = null;
  }
}
