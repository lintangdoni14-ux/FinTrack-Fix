class BudgetModel {
  final int? id;
  final int amount; // Monthly limit
  final int month;  // 1 - 12
  final int year;

  const BudgetModel({
    this.id,
    required this.amount,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }
}
