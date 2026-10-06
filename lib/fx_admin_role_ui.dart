
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FxAdminRole { customerAdmin, superAdmin }

class FxAdminRoleService {
  /// Existing `admin` username resolves to this account in auth_gate.dart.
  static const String ownerEmail = 'admin@final-fx-tv.com';

  static Future<FxAdminRole> currentRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return FxAdminRole.customerAdmin;

    final email = user.email?.trim().toLowerCase();
    if (email == ownerEmail) return FxAdminRole.superAdmin;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(user.uid)
          .get();
      final role = snap.data()?['role']?.toString().trim().toLowerCase();
      if (role == 'super_admin' || role == 'owner') {
        return FxAdminRole.superAdmin;
      }
    } catch (_) {
      // Fail closed: keep the customer UI if role lookup is unavailable.
    }

    return FxAdminRole.customerAdmin;
  }

  static Future<bool> isSuperAdmin() async {
    return (await currentRole()) == FxAdminRole.superAdmin;
  }
}
