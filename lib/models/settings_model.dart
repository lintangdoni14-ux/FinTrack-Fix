class SettingsModel {
  final int? id;
  final int initialBalance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SettingsModel({
    this.id,
    this.initialBalance = 0,
    this.currency = 'IDR',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'initial_balance': initialBalance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as int?,
      initialBalance: map['initial_balance'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'IDR',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SettingsModel copyWith({
    int? id,
    int? initialBalance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
