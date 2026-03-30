/// Access Policy untuk mengatur izin berdasarkan role
/// Memisahkan konfigurasi policy dari logic service
class AccessPolicy {
  // ============ ROLE DEFINITIONS ============
  static const String roleKetua = 'Ketua';
  static const String roleAnggota = 'Anggota';
  static const String roleAsisten = 'Asisten';

  // ============ ACTION DEFINITIONS ============
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';
  static const String actionExport = 'export';
  static const String actionApprove = 'approve';

  // ============ VISIBILITY DEFINITIONS ============
  static const String visibilityPrivate = 'Private';
  static const String visibilityPublic = 'Public';

  // ============ PERMISSION MATRIX ============
  /// Matrix perizinan: Role -> List of Actions
  static final Map<String, List<String>> permissions = {
    roleKetua: [
      actionCreate,
      actionRead,
    ],
    roleAnggota: [
      actionCreate,
      actionRead,

    ],
    roleAsisten: [actionRead, actionUpdate, actionApprove],
  };

  // ============ POLICY RULES ============

  /// Cek apakah role memiliki permission untuk action tertentu
  static bool hasPermission(String role, String action) {
    final rolePermissions = permissions[role] ?? [];
    return rolePermissions.contains(action);
  }

  /// Cek apakah role dapat melakukan action (dengan owner-based logic)
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // Cek basic permission
    final hasBasicPermission = hasPermission(role, action);

    // Owner-based RBAC: HANYA pemilik yang bisa edit/delete (Ketua juga tidak bisa!)
    if (action == actionUpdate || action == actionDelete) {
      return isOwner; // Hanya pemilik yang bisa edit/hapus
    }

    return hasBasicPermission;
  }

  /// Cek apakah user bisa melihat log tertentu berdasarkan visibility
  /// @param visibility: 'Private' atau 'Public'
  /// @param isOwner: Apakah user adalah pemilik log
  static bool canViewLog(String visibility, bool isOwner) {
    // Private: Hanya pemilik yang bisa lihat
    if (visibility == visibilityPrivate) {
      return isOwner;
    }

    // Public: Semua orang di tim bisa lihat
    return true;
  }

  /// Cek apakah role adalah admin/ketua
  static bool isAdmin(String role) {
    return role == roleKetua;
  }

  /// Cek apakah role dapat mengakses fitur tertentu
  static bool canAccessFeature(String role, String feature) {
    switch (feature) {
      case 'team_management':
        return role == roleKetua;
      case 'log_approval':
        return role == roleKetua || role == roleAsisten;
      case 'export_data':
        return role == roleKetua;
      case 'view_all_logs':
        return true; // Semua role bisa lihat logs tim
      default:
        return false;
    }
  }

  /// Dapatkan deskripsi role
  static String getRoleDescription(String role) {
    switch (role) {
      case roleKetua:
        return 'Memiliki akses penuh untuk semua operasi';
      case roleAnggota:
        return 'Dapat membuat dan mengedit data milik sendiri';
      case roleAsisten:
        return 'Dapat membaca dan menyetujui data';
      default:
        return 'Role tidak dikenali';
    }
  }

  /// Dapatkan semua role yang tersedia
  static List<String> getAllRoles() {
    return [roleKetua, roleAnggota, roleAsisten];
  }
}
