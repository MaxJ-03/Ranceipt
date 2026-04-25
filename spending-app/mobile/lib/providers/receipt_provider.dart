import 'package:flutter/material.dart';

import '../models/receipt.dart';

class ReceiptProvider extends ChangeNotifier {
final List<Receipt> _receipts = [
Receipt(
id: '1',
merchant: 'Starbucks',
date: DateTime.now(),
currency: 'EUR',
transactionId: 'txn_1001',
items: const [
ReceiptItem(
id: '1',
name: 'Iced latte',
category: 'Prepared coffee drinks',
quantity: 1,
unitPrice: 5.40,
),
ReceiptItem(
id: '2',
name: 'Cappuccino',
category: 'Prepared coffee drinks',
quantity: 1,
unitPrice: 4.60,
),
ReceiptItem(
id: '3',
name: 'Croissant',
category: 'Pastries',
quantity: 1,
unitPrice: 4.30,
),
],
),
Receipt(
id: '2',
merchant: 'Albert Heijn',
date: DateTime.now().subtract(const Duration(days: 1)),
currency: 'EUR',
transactionId: 'txn_1002',
items: const [
ReceiptItem(
id: '4',
name: 'Chicken breast',
category: 'Chicken breast',
quantity: 1,
unitPrice: 8.90,
),
ReceiptItem(
id: '5',
name: 'Greek yogurt',
category: 'Yogurt',
quantity: 2,
unitPrice: 2.40,
),
ReceiptItem(
id: '6',
name: 'Bananas',
category: 'Bananas',
quantity: 1,
unitPrice: 2.10,
),
ReceiptItem(
id: '7',
name: 'Pasta',
category: 'Pasta',
quantity: 2,
unitPrice: 1.90,
),
ReceiptItem(
id: '8',
name: 'Tomatoes',
category: 'Tomatoes',
quantity: 1,
unitPrice: 3.20,
),
],
),
Receipt(
id: '3',
merchant: 'Jumbo',
date: DateTime.now().subtract(const Duration(days: 2)),
currency: 'EUR',
transactionId: 'txn_1003',
items: const [
ReceiptItem(
id: '9',
name: 'Coffee beans',
category: 'Coffee for home',
quantity: 1,
unitPrice: 8.50,
),
ReceiptItem(
id: '10',
name: 'Milk',
category: 'Milk',
quantity: 2,
unitPrice: 1.65,
),
ReceiptItem(
id: '11',
name: 'Bread',
category: 'Bread',
quantity: 1,
unitPrice: 2.80,
),
ReceiptItem(
id: '12',
name: 'Eggs',
category: 'Eggs',
quantity: 1,
unitPrice: 3.50,
),
],
),
Receipt(
id: '4',
merchant: 'Uber Eats',
date: DateTime.now().subtract(const Duration(days: 4)),
currency: 'EUR',
transactionId: 'txn_1004',
items: const [
ReceiptItem(
id: '13',
name: 'Pizza margherita',
category: 'Pizza',
quantity: 1,
unitPrice: 14.90,
),
ReceiptItem(
id: '14',
name: 'Soft drink',
category: 'Soft drinks',
quantity: 2,
unitPrice: 2.70,
),
ReceiptItem(
id: '15',
name: 'Delivery fee',
category: 'Prepared meals',
quantity: 1,
unitPrice: 3.20,
),
],
),
];

final List<PersonalGoal> _personalGoals = [
PersonalGoal(
id: 'goal_1',
amountToSave: 250,
currency: 'EUR',
targetDate: DateTime.now().add(const Duration(days: 30)),
createdAt: DateTime.now().subtract(const Duration(days: 2)),
),
];

List<Receipt> get receipts {
final sorted = [..._receipts];
sorted.sort((a, b) => b.date.compareTo(a.date));
return sorted;
}

List<PersonalGoal> get personalGoals {
final sorted = [..._personalGoals];
sorted.sort((a, b) => a.targetDate.compareTo(b.targetDate));
return sorted;
}

void addReceipt(Receipt receipt) {
_receipts.insert(0, receipt);
notifyListeners();
}

void addPersonalGoal({
required double amountToSave,
required DateTime targetDate,
String currency = 'EUR',
}) {
final goal = PersonalGoal(
id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
amountToSave: amountToSave,
currency: currency,
targetDate: targetDate,
createdAt: DateTime.now(),
);

_personalGoals.insert(0, goal);
notifyListeners();

}

Receipt? getReceiptById(String id) {
for (final receipt in _receipts) {
if (receipt.id == id) return receipt;
}

return null;

}

SpendingAnalytics getAnalytics() {
final categoryTotals = <String, double>{};
final categoryCounts = <String, int>{};

double totalSpending = 0;

for (final receipt in _receipts) {
  totalSpending += receipt.totalAmount;

  for (final item in receipt.items) {
    final category = categoryDisplayName(item.category);

    categoryTotals[category] =
        (categoryTotals[category] ?? 0) + item.totalPrice;

    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
  }
}

final topCategories = categoryTotals.entries.map((entry) {
  return ItemCategorySpending(
    itemCategory: entry.key,
    amount: entry.value,
    transactionCount: categoryCounts[entry.key] ?? 0,
    percentile: percentileForCategory(entry.key, entry.value),
  );
}).toList();

topCategories.sort((a, b) => b.amount.compareTo(a.amount));

return SpendingAnalytics(
  totalSpending: totalSpending,
  transactionCount: _receipts.length,
  topItemCategories: topCategories,
  receipts: receipts,
  personalGoals: personalGoals,
  aiAdvice: buildAiAdvice(topCategories),
);

}

double percentileForCategory(String category, double amount) {
final name = category.toLowerCase();

double benchmark;

if (name.contains('coffee')) {
  benchmark = 18;
} else if (name.contains('meat') || name.contains('poultry')) {
  benchmark = 35;
} else if (name.contains('dairy')) {
  benchmark = 22;
} else if (name.contains('ready meals')) {
  benchmark = 25;
} else if (name.contains('snacks')) {
  benchmark = 16;
} else if (name.contains('drinks')) {
  benchmark = 14;
} else if (name.contains('household')) {
  benchmark = 20;
} else if (name.contains('personal care')) {
  benchmark = 18;
} else if (name.contains('pets')) {
  benchmark = 24;
} else {
  benchmark = 28;
}

final ratio = amount / benchmark;
final percentile = 50 + (ratio * 18);

if (percentile > 99.9) return 99.9;
if (percentile < 10) return 10;

return percentile;

}

String buildAiAdvice(List<ItemCategorySpending> categories) {
if (categories.isEmpty) {
return 'Scan a receipt first. Once we know your categories, AI advice can suggest where to save.';
}

final top = categories.first;
final goal = personalGoals.isEmpty ? null : personalGoals.first;

if (goal == null) {
  return 'Your biggest spending signal is ${top.itemCategory}. Add a savings goal to get specific AI advice.';
}

final suggestedCut = top.amount * 0.20;

return 'To reach your €${goal.amountToSave.toStringAsFixed(0)} goal, start with ${top.itemCategory}. Cutting it by 20% could save about €${suggestedCut.toStringAsFixed(0)}.';

}
}