import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt.dart';

class ReceiptProvider extends ChangeNotifier {
  List<Receipt> _receipts = [];

  List<Receipt> get receipts => _receipts;

  // Percentile data for each item category (simulated global comparison)
  final Map<String, double> _categoryPercentiles = {
    'Milk': 72.5,
    'Plant-based milk': 68.0,
    'Bread': 45.0,
    'Cheese': 61.5,
    'Eggs': 55.2,
    'Butter': 48.3,
    'Yogurt': 52.1,
    'Coffee for home': 78.9,
    'Prepared coffee drinks': 82.3,
    'Tea': 38.5,
    'Chicken breast': 58.7,
    'Beef': 64.2,
    'Fish': 55.8,
    'Rice': 42.1,
    'Pasta': 48.5,
    'Apples': 35.2,
    'Bananas': 38.9,
    'Carrots': 40.1,
    'Broccoli': 42.5,
    'Spinach': 44.3,
    'Tomatoes': 41.2,
    'Potatoes': 36.5,
    'Peppers': 39.8,
    'Onions': 37.2,
    'Lettuce': 35.8,
    'Frozen vegetables': 46.2,
    'Canned vegetables': 33.1,
    'Nuts': 58.5,
    'Seeds': 49.2,
    'Beans': 39.5,
    'Lentils': 38.2,
    'Chocolate': 65.3,
    'Candy': 62.1,
    'Ice cream': 67.8,
    'Packaged snacks': 71.5,
    'Pizza': 68.9,
    'Prepared meals': 72.3,
    'Beer': 55.2,
    'Wine': 58.9,
    'Spirits': 52.1,
    'Soft drinks': 61.5,
    'Juice': 45.8,
    'Bottled water': 48.2,
    'Shampoo': 43.2,
    'Toothpaste': 40.1,
    'Soap': 38.5,
    'Deodorant': 45.3,
    'Toilet paper': 42.1,
    'Laundry detergent': 44.8,
    'Dish soap': 41.5,
    'Pet food': 51.2,
    'Pet products': 44.1,
    'Baby products': 49.8,
    'Cooking oil': 55.4,
    'Sparkling water': 46.8,
  };

  ReceiptProvider() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();
    const uuid = Uuid();

    _receipts = [
      // Receipt 1: Whole Foods - Dairy focused
      Receipt(
        id: uuid.v4(),
        storeName: 'Whole Foods Market',
        date: now.subtract(const Duration(days: 15)),
        total: 42.30,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Organic Milk 1L',
            detailedCategory: 'Milk',
            price: 5.99,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Greek Yogurt',
            detailedCategory: 'Yogurt',
            price: 6.49,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Cheddar Cheese',
            detailedCategory: 'Cheese',
            price: 8.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Organic Bread',
            detailedCategory: 'Bread',
            price: 4.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Free Range Eggs',
            detailedCategory: 'Eggs',
            price: 9.85,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 2: Fresh Market - Produce focused
      Receipt(
        id: uuid.v4(),
        storeName: 'Fresh Market',
        date: now.subtract(const Duration(days: 13)),
        total: 38.75,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Organic Spinach',
            detailedCategory: 'Spinach',
            price: 4.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Broccoli Crown',
            detailedCategory: 'Broccoli',
            price: 3.49,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Carrots 1kg',
            detailedCategory: 'Carrots',
            price: 2.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Bell Peppers',
            detailedCategory: 'Peppers',
            price: 5.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Tomatoes',
            detailedCategory: 'Tomatoes',
            price: 4.99,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Apples 1kg',
            detailedCategory: 'Apples',
            price: 5.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Bananas',
            detailedCategory: 'Bananas',
            price: 1.99,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 3: Costco - Bulk shopping
      Receipt(
        id: uuid.v4(),
        storeName: 'Costco',
        date: now.subtract(const Duration(days: 11)),
        total: 87.50,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Chicken Breast Pack',
            detailedCategory: 'Chicken breast',
            price: 19.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Ground Beef 2kg',
            detailedCategory: 'Beef',
            price: 24.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Rice 5kg',
            detailedCategory: 'Rice',
            price: 14.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Pasta Multi-pack',
            detailedCategory: 'Pasta',
            price: 9.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Nuts & Seeds Mix',
            detailedCategory: 'Nuts',
            price: 17.55,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 4: Coffee Shop
      Receipt(
        id: uuid.v4(),
        storeName: 'Brew Haven Coffee',
        date: now.subtract(const Duration(days: 9)),
        total: 28.50,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Cappuccino',
            detailedCategory: 'Prepared coffee drinks',
            price: 5.50,
            quantity: 3,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Espresso Shot',
            detailedCategory: 'Prepared coffee drinks',
            price: 3.50,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Oat Milk Latte',
            detailedCategory: 'Prepared coffee drinks',
            price: 6.50,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 5: Supermarket - Mixed
      Receipt(
        id: uuid.v4(),
        storeName: 'SuperMart',
        date: now.subtract(const Duration(days: 7)),
        total: 56.80,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Fish Fillets',
            detailedCategory: 'Fish',
            price: 14.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Whole Grain Bread',
            detailedCategory: 'Bread',
            price: 4.49,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Canned Beans',
            detailedCategory: 'Beans',
            price: 1.99,
            quantity: 3,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Beer 6-pack',
            detailedCategory: 'Beer',
            price: 9.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Red Wine',
            detailedCategory: 'Wine',
            price: 14.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Dark Chocolate',
            detailedCategory: 'Chocolate',
            price: 5.99,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 6: Health Store
      Receipt(
        id: uuid.v4(),
        storeName: 'Health & Wellness',
        date: now.subtract(const Duration(days: 5)),
        total: 34.20,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Plant-based Milk',
            detailedCategory: 'Plant-based milk',
            price: 4.99,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Shampoo Organic',
            detailedCategory: 'Shampoo',
            price: 9.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Toothpaste Natural',
            detailedCategory: 'Toothpaste',
            price: 5.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Tea Selection',
            detailedCategory: 'Tea',
            price: 8.99,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 7: Specialty Grocery
      Receipt(
        id: uuid.v4(),
        storeName: 'Gourmet Market',
        date: now.subtract(const Duration(days: 3)),
        total: 45.60,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Butter Premium',
            detailedCategory: 'Butter',
            price: 7.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Olive Oil',
            detailedCategory: 'Cooking oil',
            price: 12.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Artisan Pasta',
            detailedCategory: 'Pasta',
            price: 4.99,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Premium Chocolate',
            detailedCategory: 'Chocolate',
            price: 6.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Sparkling Water',
            detailedCategory: 'Sparkling water',
            price: 5.99,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 8: Frozen Foods
      Receipt(
        id: uuid.v4(),
        storeName: 'Frozen Foods Plus',
        date: now.subtract(const Duration(days: 2)),
        total: 31.45,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Frozen Vegetables Mix',
            detailedCategory: 'Frozen vegetables',
            price: 8.99,
            quantity: 2,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Frozen Fruit',
            detailedCategory: 'Frozen fruit',
            price: 6.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Ice Cream',
            detailedCategory: 'Ice cream',
            price: 7.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Ready Meals Pack',
            detailedCategory: 'Prepared meals',
            price: 9.99,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),

      // Receipt 9: Pet Store
      Receipt(
        id: uuid.v4(),
        storeName: 'Pet Paradise',
        date: now.subtract(const Duration(days: 1)),
        total: 28.90,
        lineItems: [
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Dog Food Premium',
            detailedCategory: 'Pet food',
            price: 24.99,
            quantity: 1,
            isCategorized: true,
          ),
          ReceiptLineItem(
            id: uuid.v4(),
            name: 'Pet Shampoo',
            detailedCategory: 'Pet products',
            price: 3.91,
            quantity: 1,
            isCategorized: true,
          ),
        ],
        isProcessed: true,
      ),
    ];
  }

  void addReceipt(Receipt receipt) {
    _receipts.add(receipt);
    notifyListeners();
  }

  void deleteReceipt(String id) {
    _receipts.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void updateLineItem(String receiptId, String itemId, String newCategory) {
    for (var receipt in _receipts) {
      if (receipt.id == receiptId) {
        final itemIndex = receipt.lineItems.indexWhere((i) => i.id == itemId);
        if (itemIndex != -1) {
          final oldItem = receipt.lineItems[itemIndex];
          receipt.lineItems[itemIndex] = ReceiptLineItem(
            id: oldItem.id,
            name: oldItem.name,
            detailedCategory: newCategory,
            price: oldItem.price,
            quantity: oldItem.quantity,
            isCategorized: true,
          );
        }
      }
    }
    notifyListeners();
  }

  SpendingAnalytics getAnalytics({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredReceipts = _receipts
        .where((r) => r.date.isAfter(cutoffDate))
        .toList();

    if (filteredReceipts.isEmpty) {
      return SpendingAnalytics(
        totalSpending: 0,
        averageTransaction: 0,
        transactionCount: 0,
        itemCategoryBreakdown: {},
        topItemCategories: [],
        dailyTrend: [],
        categoryFrequency: {},
      );
    }

    // Calculate totals
    final totalSpending = filteredReceipts.fold<double>(
      0,
      (sum, r) => sum + r.total,
    );
    final transactionCount = filteredReceipts.length;
    final averageTransaction = totalSpending / transactionCount;

    // Item category breakdown
    final itemCategoryMap = <String, double>{};
    final itemCategoryCountMap = <String, int>{};

    for (var receipt in filteredReceipts) {
      for (var item in receipt.lineItems) {
        final category = item.detailedCategory ?? 'Uncategorized';
        itemCategoryMap[category] =
            (itemCategoryMap[category] ?? 0) + item.subtotal;
        itemCategoryCountMap[category] =
            (itemCategoryCountMap[category] ?? 0) + 1;
      }
    }

    // Create top item categories list with percentiles
    final topItemCategories = itemCategoryMap.entries.map((e) {
      final percentile = _categoryPercentiles[e.key] ?? 50.0;
      final percentileText = _getPercentileDescription(percentile);
      return ItemCategorySpending(
        itemCategory: e.key,
        amount: e.value,
        transactionCount: itemCategoryCountMap[e.key] ?? 0,
        percentile: percentile,
        percentileText: percentileText,
        percentileRank: percentile,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Daily trend
    final dailyMap = <DateTime, double>{};
    for (var receipt in filteredReceipts) {
      final date = DateTime(
        receipt.date.year,
        receipt.date.month,
        receipt.date.day,
      );
      dailyMap[date] = (dailyMap[date] ?? 0) + receipt.total;
    }

    final dailyTrend =
        dailyMap.entries
            .map((e) => DailySpending(date: e.key, amount: e.value))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return SpendingAnalytics(
      totalSpending: totalSpending,
      averageTransaction: averageTransaction,
      transactionCount: transactionCount,
      itemCategoryBreakdown: itemCategoryMap,
      topItemCategories: topItemCategories,
      dailyTrend: dailyTrend,
      categoryFrequency: itemCategoryCountMap,
    );
  }

  String _getPercentileDescription(double percentile) {
    if (percentile >= 90) {
      return 'Top 10% - Way above average';
    } else if (percentile >= 75) {
      return 'Top 25% - Above average';
    } else if (percentile >= 60) {
      return 'Top 40% - Slightly above average';
    } else if (percentile >= 50) {
      return 'Average';
    } else if (percentile >= 40) {
      return 'Slightly below average';
    } else if (percentile >= 25) {
      return 'Below average';
    } else {
      return 'Bottom 25% - Way below average';
    }
  }

  double getCategoryPercentile(String category) {
    return _categoryPercentiles[category] ?? 50.0;
  }
}
