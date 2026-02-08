enum UserRole {
  buyer('buyer'),
  seller('seller'),
  admin('admin'),
  runner('runner');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.buyer,
    );
  }
}
