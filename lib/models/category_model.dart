import 'package:flutter/material.dart';

enum CategoryType {
  expense,
  income;

  String toDbString() {
    switch (this) {
      case CategoryType.expense:
        return 'EXPENSE';
      case CategoryType.income:
        return 'INCOME';
    }
  }

  static CategoryType fromDbString(String str) {
    if (str.toUpperCase() == 'INCOME') {
      return CategoryType.income;
    }
    return CategoryType.expense;
  }
}

class CategoryModel {
  final int? id;
  final String name;
  final String iconName;
  final CategoryType type;
  final bool isDefault;

  const CategoryModel({
    this.id,
    required this.name,
    required this.iconName,
    required this.type,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': iconName,
      'type': type.toDbString(),
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon'] as String,
      type: CategoryType.fromDbString(map['type'] as String),
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  IconData get iconData {
    return iconMap[iconName] ?? Icons.category_rounded;
  }

  static const Map<String, IconData> iconMap = {
    // Expense
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'directions_car': Icons.directions_car_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'school': Icons.school_rounded,
    'medical_services': Icons.medical_services_rounded,
    'movie': Icons.movie_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'person': Icons.person_rounded,
    'category': Icons.category_rounded,

    // Income
    'wallet': Icons.account_balance_wallet_rounded,
    'savings': Icons.savings_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'storefront': Icons.storefront_rounded,
    'gift': Icons.card_giftcard_rounded,
    'payments': Icons.payments_rounded,
  };

  static List<CategoryModel> get defaultExpenseCategories => const [
    CategoryModel(id: 1, name: 'Makanan', iconName: 'restaurant', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 2, name: 'Minuman', iconName: 'local_cafe', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 3, name: 'Transportasi', iconName: 'directions_car', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 4, name: 'Belanja', iconName: 'shopping_bag', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 5, name: 'Pendidikan', iconName: 'school', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 6, name: 'Kesehatan', iconName: 'medical_services', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 7, name: 'Hiburan', iconName: 'movie', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 8, name: 'Tagihan', iconName: 'receipt_long', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 9, name: 'Kebutuhan Pribadi', iconName: 'person', type: CategoryType.expense, isDefault: true),
    CategoryModel(id: 10, name: 'Lainnya', iconName: 'category', type: CategoryType.expense, isDefault: true),
  ];

  static List<CategoryModel> get defaultIncomeCategories => const [
    CategoryModel(id: 101, name: 'Gaji', iconName: 'wallet', type: CategoryType.income, isDefault: true),
    CategoryModel(id: 102, name: 'Uang Saku', iconName: 'savings', type: CategoryType.income, isDefault: true),
    CategoryModel(id: 103, name: 'Freelance', iconName: 'laptop', type: CategoryType.income, isDefault: true),
    CategoryModel(id: 104, name: 'Bisnis', iconName: 'storefront', type: CategoryType.income, isDefault: true),
    CategoryModel(id: 105, name: 'Hadiah', iconName: 'gift', type: CategoryType.income, isDefault: true),
    CategoryModel(id: 106, name: 'Pemasukan Lainnya', iconName: 'payments', type: CategoryType.income, isDefault: true),
  ];
}
