import 'category_model.dart';

enum TransactionType {
  expense,
  income;

  String toDbString() {
    switch (this) {
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.income:
        return 'INCOME';
    }
  }

  static TransactionType fromDbString(String str) {
    if (str.toUpperCase() == 'INCOME') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }
}

class TransactionModel {
  final int? id;
  final int amount; // IDR in whole integer units
  final TransactionType type;
  final int categoryId;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel? category; // Joined/resolved category

  const TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type.toDbString(),
      'category_id': categoryId,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {CategoryModel? category}) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      type: TransactionType.fromDbString(map['type'] as String),
      categoryId: map['category_id'] as int,
      description: map['description'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      category: category,
    );
  }

  TransactionModel copyWith({
    int? id,
    int? amount,
    TransactionType? type,
    int? categoryId,
    String? description,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryModel? category,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}
