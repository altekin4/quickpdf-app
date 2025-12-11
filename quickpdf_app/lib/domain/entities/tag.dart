class Tag {
  final String id;
  final String name;
  final String slug;
  final int usageCount;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.slug,
    required this.usageCount,
    required this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      usageCount: json['usage_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tag(id: $id, name: $name, usageCount: $usageCount)';
}