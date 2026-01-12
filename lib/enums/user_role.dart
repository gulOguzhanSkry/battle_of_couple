import '../core/constants/app_strings.dart';

/// Kullanıcı rolleri için enum
/// Magic string kullanımını ortadan kaldırır
enum UserRole {
  user('user'),
  editor('editor'),
  admin('admin');

  final String value;

  const UserRole(this.value);

  /// String'den UserRole'e çevir
  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'editor':
        return UserRole.editor;
      default:
        return UserRole.user;
    }
  }

  /// Localized display name
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return AppStrings.roleAdmin;
      case UserRole.editor:
        return AppStrings.roleEditor;
      case UserRole.user:
        return AppStrings.roleUser;
    }
  }

  /// Role'e göre yetki kontrolü
  bool get isAdmin => this == UserRole.admin;
  bool get isEditor => this == UserRole.editor;
  bool get hasElevatedAccess => isAdmin || isEditor;
  bool get canAccessDevTools => hasElevatedAccess;
  bool get canManageUsers => isAdmin;
}
