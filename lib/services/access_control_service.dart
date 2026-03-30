import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/policies/access_policy.dart';

/// Service untuk mengelola access control
/// Menggunakan AccessPolicy sebagai source of truth untuk permission rules
class AccessControlService {
  // Mengambil roles dari .env di root
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? AccessPolicy.getAllRoles();

  // Action constants (delegasi ke AccessPolicy)
  static const String actionCreate = AccessPolicy.actionCreate;
  static const String actionRead = AccessPolicy.actionRead;
  static const String actionUpdate = AccessPolicy.actionUpdate;
  static const String actionDelete = AccessPolicy.actionDelete;

  /// Cek apakah user dengan role tertentu dapat melakukan action
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    return AccessPolicy.canPerform(role, action, isOwner: isOwner);
  }

  /// Cek apakah user adalah admin
  static bool isAdmin(String role) {
    return AccessPolicy.isAdmin(role);
  }

  /// Cek apakah user dapat mengakses fitur tertentu
  static bool canAccessFeature(String role, String feature) {
    return AccessPolicy.canAccessFeature(role, feature);
  }

  /// Dapatkan deskripsi role
  static String getRoleDescription(String role) {
    return AccessPolicy.getRoleDescription(role);
  }
}
