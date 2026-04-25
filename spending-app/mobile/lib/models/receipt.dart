import 'package:flutter/material.dart';

class Receipt {
final String id;
final String merchant;
final DateTime date;
final String currency;
final List<ReceiptItem> items;
final String? transactionId;

const Receipt({
required this.id,
required this.merchant,
required this.date,
required this.currency,
required this.items,
this.transactionId,
});

double get totalAmount {
return items.fold<double>(
0,
(sum, item) => sum + item.totalPrice,
);
}

int get itemCount {
return items.fold<int>(
0,
(sum, item) => sum + item.quantity.round(),
);
}

String get formattedDate {
final now = DateTime.now();
final days = now.difference(date).inDays;

if (days == 0) return 'Today';
if (days == 1) return 'Yesterday';

return '$days days ago';

}

String get mainCategory {
if (items.isEmpty) return 'Other';

final totals = <String, double>{};

for (final item in items) {
  final category = categoryDisplayName(item.category);
  totals[category] = (totals[category] ?? 0) + item.totalPrice;
}

final sorted = totals.entries.toList()
  ..sort((a, b) => b.value.compareTo(a.value));

return sorted.first.key;

}
}

class ReceiptItem {
final String id;
final String name;
final String category;
final double quantity;
final double unitPrice;

const ReceiptItem({
required this.id,
required this.name,
required this.category,
required this.quantity,
required this.unitPrice,
});

double get totalPrice {
return quantity * unitPrice;
}
}

class PersonalGoal {
final String id;
final double amountToSave;
final String currency;
final DateTime targetDate;
final DateTime createdAt;

const PersonalGoal({
required this.id,
required this.amountToSave,
required this.currency,
required this.targetDate,
required this.createdAt,
});

int get daysLeft {
final days = targetDate.difference(DateTime.now()).inDays;

if (days < 0) return 0;

return days;

}
}

class ItemCategorySpending {
final String itemCategory;
final double amount;
final int transactionCount;
final double percentile;

const ItemCategorySpending({
required this.itemCategory,
required this.amount,
required this.transactionCount,
required this.percentile,
});

String get percentileText {
return 'More than ${percentile.toStringAsFixed(1)}% of users';
}
}

class SpendingAnalytics {
final double totalSpending;
final int transactionCount;
final List<ItemCategorySpending> topItemCategories;
final List<Receipt> receipts;
final List<PersonalGoal> personalGoals;
final String aiAdvice;

const SpendingAnalytics({
required this.totalSpending,
required this.transactionCount,
required this.topItemCategories,
required this.receipts,
required this.personalGoals,
required this.aiAdvice,
});

PersonalGoal? get activeGoal {
if (personalGoals.isEmpty) return null;

final sorted = [...personalGoals]
  ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

return sorted.first;

}
}

String categoryDisplayName(String category) {
final name = category.toLowerCase().trim();

if (containsAny(name, [
'prepared coffee',
'coffee',
'latte',
'cappuccino',
'espresso',
'americano',
'mocha',
])) {
return 'Coffee';
}

if (containsAny(name, ['tea', 'chai', 'matcha'])) {
return 'Tea';
}

if (containsAny(name, [
'beef',
'pork',
'lamb',
'bacon',
'sausage',
'deli meat',
'ham',
'meat',
])) {
return 'Meat';
}

if (containsAny(name, ['chicken', 'turkey', 'poultry'])) {
return 'Poultry';
}

if (containsAny(name, ['fish', 'seafood', 'salmon', 'tuna', 'shrimp'])) {
return 'Fish & seafood';
}

if (containsAny(name, [
'milk',
'plant-based milk',
'cheese',
'yogurt',
'butter',
'cream',
'dairy',
])) {
return 'Dairy';
}

if (containsAny(name, [
'bread',
'pastries',
'pastry',
'cake',
'cakes',
'bakery',
'croissant',
])) {
return 'Bakery';
}

if (containsAny(name, [
'rice',
'pasta',
'noodle',
'noodles',
'flour',
'oats',
'cereal',
'granola',
'grains',
])) {
return 'Grains';
}

if (containsAny(name, [
'apple',
'apples',
'banana',
'bananas',
'orange',
'oranges',
'fruit',
'berries',
'grapes',
'melon',
'avocado',
])) {
return 'Fruit';
}

if (containsAny(name, [
'vegetable',
'vegetables',
'potato',
'potatoes',
'onion',
'onions',
'garlic',
'carrot',
'carrots',
'tomato',
'tomatoes',
'lettuce',
'spinach',
'broccoli',
'cauliflower',
'pepper',
'peppers',
'mushroom',
'mushrooms',
'zucchini',
'eggplant',
'cabbage',
'leeks',
'asparagus',
'herbs',
])) {
return 'Vegetables';
}

if (containsAny(name, [
'chocolate',
'candy',
'snack',
'snacks',
'packaged snacks',
'dessert',
'desserts',
'ice cream',
'gum',
'mints',
])) {
return 'Snacks';
}

if (containsAny(name, [
'water',
'sparkling water',
'juice',
'smoothie',
'smoothies',
'soft drink',
'soft drinks',
'energy drink',
'sports drink',
'drink',
'drinks',
])) {
return 'Drinks';
}

if (containsAny(name, [
'beer',
'wine',
'cider',
'spirits',
'alcohol',
'sparkling wine',
])) {
return 'Alcohol';
}

if (containsAny(name, [
'shampoo',
'conditioner',
'body wash',
'soap',
'toothpaste',
'toothbrush',
'deodorant',
'skincare',
'razor',
'shaving',
'feminine care',
'personal care',
])) {
return 'Personal care';
}

if (containsAny(name, [
'toilet paper',
'paper towels',
'tissues',
'laundry detergent',
'fabric softener',
'dish soap',
'dishwasher',
'surface cleaner',
'bathroom cleaner',
'trash bags',
'foil',
'food wrap',
'storage bags',
'batteries',
'light bulbs',
'household',
])) {
return 'Household';
}

if (containsAny(name, ['pet', 'dog', 'cat', 'animal'])) {
return 'Pets';
}

if (containsAny(name, [
'medicine',
'vitamins',
'first aid',
'pharmacy',
'health',
])) {
return 'Health';
}

if (containsAny(name, [
'prepared meals',
'prepared meal',
'pizza',
'sandwich',
'sandwiches',
'salad',
'salads',
'soup',
'ready meal',
'ready meals',
])) {
return 'Ready meals';
}

if (containsAny(name, [
'cigarettes',
'tobacco',
'vapes',
'nicotine',
'smoking',
])) {
return 'Nicotine';
}

if (containsAny(name, [
'baby',
'condoms',
'over-the-counter',
])) {
return 'Health';
}

if (category.trim().isEmpty) return 'Other';

return category.trim();
}

IconData categoryIcon(String category) {
final name = category.toLowerCase();

if (name.contains('coffee')) return Icons.local_cafe_outlined;
if (name.contains('tea')) return Icons.emoji_food_beverage_outlined;
if (name.contains('meat')) return Icons.dinner_dining_outlined;
if (name.contains('poultry')) return Icons.lunch_dining_outlined;
if (name.contains('fish')) return Icons.set_meal_outlined;
if (name.contains('dairy')) return Icons.icecream_outlined;
if (name.contains('bakery')) return Icons.bakery_dining_outlined;
if (name.contains('grains')) return Icons.ramen_dining_outlined;
if (name.contains('fruit')) return Icons.eco_outlined;
if (name.contains('vegetables')) return Icons.eco_outlined;
if (name.contains('snacks')) return Icons.cookie_outlined;
if (name.contains('drinks')) return Icons.local_drink_outlined;
if (name.contains('alcohol')) return Icons.wine_bar_outlined;
if (name.contains('personal care')) return Icons.spa_outlined;
if (name.contains('household')) return Icons.home_outlined;
if (name.contains('pets')) return Icons.pets_outlined;
if (name.contains('health')) return Icons.local_pharmacy_outlined;
if (name.contains('ready meals')) return Icons.restaurant_outlined;
if (name.contains('nicotine')) return Icons.smoking_rooms_outlined;

return Icons.category_outlined;
}

bool containsAny(String text, List<String> words) {
for (final word in words) {
if (text.contains(word)) {
return true;
}
}

return false;
}