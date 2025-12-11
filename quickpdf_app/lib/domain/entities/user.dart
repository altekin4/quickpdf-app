class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? profilePictureUrl;
  final UserRole role;
  final bool isVerified;
  final double balance;
  final double totalEarnings;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.profilePictureUrl,
    required this.role,
    required this.isVerified,
    required this.balance,
    required this.totalEarnings,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? profilePictureUrl,
    UserRole? role,
    bool? isVerified,
    double? balance,
    double? totalEarnings,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      balance: balance ?? this.balance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'isVerified': isVerified,
      'balance': balance,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      isVerified: json['isVerified'] ?? false,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      totalEarnings: double.tryParse(json['totalEarnings']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

enum UserRole {
  user,
  creator,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Kullanıcı';
      case UserRole.creator:
        return 'İçerik Üreticisi';
      case UserRole.admin:
        return 'Yönetici';
    }
  }
}