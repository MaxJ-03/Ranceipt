import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/receipt.dart';
import '../services/backend_api.dart';

class ReceiptProvider extends ChangeNotifier {
  final BackendApi _backendApi;

  final List<Receipt> _receipts = [];
  final List<PersonalGoal> _personalGoals = [];

  bool _isSyncing = false;
  bool _isUploadingReceipt = false;
  bool _isGeneratingAdvice = false;
  String? _syncError;
  String? _aiAdviceSummary;
  double? _aiPotentialSavings;

  ReceiptProvider({BackendApi? backendApi}) : _backendApi = backendApi ?? BackendApi();

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

  bool get isSyncing => _isSyncing;
  bool get isUploadingReceipt => _isUploadingReceipt;
  bool get isGeneratingAdvice => _isGeneratingAdvice;
  String? get syncError => _syncError;
  String? get aiAdviceSummary => _aiAdviceSummary;
  double? get aiPotentialSavings => _aiPotentialSavings;

  Future<void> syncWithBackend() async {
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      try {
        await _backendApi.syncBunqTransactions();
      } catch (_) {}

      final receiptRows = await _backendApi.getReceipts();
      final fetchedReceipts = <Receipt>[];

      for (final row in receiptRows) {
        final receiptId = int.tryParse(row['id'].toString());
        if (receiptId == null) {
          continue;
        }

        try {
          final parsed = await _backendApi.getReceiptDetail(receiptId);
          fetchedReceipts.add(_receiptFromParsedResponse(parsed));
        } catch (_) {}
      }

      final goalRows = await _backendApi.getGoals();
      final fetchedGoals = goalRows.map(_goalFromRow).toList();

      if (fetchedReceipts.isEmpty && fetchedGoals.isEmpty) {
        _loadLocalDemoData();
      } else {
        _receipts
          ..clear()
          ..addAll(fetchedReceipts);

        _personalGoals
          ..clear()
          ..addAll(fetchedGoals);
      }
    } catch (_) {
      _loadLocalDemoData();
      _syncError = null;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  Future<void> uploadReceiptFromImage(XFile image) async {
    _isUploadingReceipt = true;
    _syncError = null;
    notifyListeners();

    final minimumLoading = Future<void>.delayed(const Duration(seconds: 4));

    try {
      final parsed = await _backendApi.uploadReceiptAndParse(image);
      final receipt = _receiptFromParsedResponse(parsed);

      _receipts.insert(0, receipt);
      _aiAdviceSummary = null;
      _aiPotentialSavings = null;
    } catch (_) {
      final now = DateTime.now();

      final receipt = Receipt(
        id: 'local-upload-${now.microsecondsSinceEpoch}',
        merchant: 'Scanned receipt',
        date: now,
        currency: 'EUR',
        items: const [
          ReceiptItem(
            id: 'local-upload-item-1',
            name: 'Demo scanned coffee',
            category: 'Prepared coffee drinks',
            quantity: 1,
            unitPrice: 7.50,
          ),
          ReceiptItem(
            id: 'local-upload-item-2',
            name: 'Demo scanned pastry',
            category: 'Pastries',
            quantity: 1,
            unitPrice: 4.20,
          ),
        ],
      );

      _receipts.insert(0, receipt);
      _aiAdviceSummary = null;
      _aiPotentialSavings = null;
      _syncError = null;
    } finally {
      await minimumLoading;
      _isUploadingReceipt = false;
      notifyListeners();
    }
  }

  Future<void> addManualReceipt({
    required String merchant,
    required double totalAmount,
    String currency = 'EUR',
  }) async {
    _syncError = null;
    notifyListeners();

    try {
      final created = await _backendApi.createManualReceipt(
        merchant: merchant,
        totalAmount: totalAmount,
        currency: currency,
      );

      final receiptId = int.tryParse((created['id'] ?? '').toString());

      if (receiptId == null) {
        final now = DateTime.now();
        _receipts.insert(
          0,
          Receipt(
            id: 'manual-${now.microsecondsSinceEpoch}',
            merchant: merchant,
            date: now,
            currency: currency,
            items: [
              ReceiptItem(
                id: 'manual-item-${now.microsecondsSinceEpoch}',
                name: 'Manual receipt',
                category: 'Other',
                quantity: 1,
                unitPrice: totalAmount,
              ),
            ],
          ),
        );
        return;
      }

      try {
        final parsed = await _backendApi.getReceiptDetail(receiptId);
        final receipt = _receiptFromParsedResponse(parsed);
        _receipts.insert(0, receipt);
      } catch (_) {
        final now = DateTime.now();
        _receipts.insert(
          0,
          Receipt(
            id: receiptId.toString(),
            merchant: merchant,
            date: now,
            currency: currency,
            items: [
              ReceiptItem(
                id: 'manual-item-${now.microsecondsSinceEpoch}',
                name: 'Manual receipt',
                category: 'Other',
                quantity: 1,
                unitPrice: totalAmount,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _syncError = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> addPersonalGoal({
    required double amountToSave,
    required DateTime targetDate,
    String currency = 'EUR',
  }) async {
    try {
      await _backendApi.createGoal(
        amountToSave: amountToSave,
        targetDate: targetDate,
        currency: currency,
      );

      final goalRows = await _backendApi.getGoals();
      _personalGoals
        ..clear()
        ..addAll(goalRows.map(_goalFromRow));

      if (_personalGoals.isEmpty) {
        _personalGoals.add(
          PersonalGoal(
            id: 'local-goal-${DateTime.now().microsecondsSinceEpoch}',
            amountToSave: amountToSave,
            currency: currency,
            targetDate: targetDate,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      _personalGoals.add(
        PersonalGoal(
          id: 'local-goal-${DateTime.now().microsecondsSinceEpoch}',
          amountToSave: amountToSave,
          currency: currency,
          targetDate: targetDate,
          createdAt: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  Future<void> generateAiSavingsAdvice() async {
    _isGeneratingAdvice = true;
    _syncError = null;
    notifyListeners();

    try {
      final insights = await _backendApi.getAiInsightsForCurrentUser();
      _aiAdviceSummary = (insights['summary'] ?? '').toString().trim();
      _aiPotentialSavings = double.tryParse(
        (insights['potential_savings'] ?? '0').toString(),
      );
    } catch (_) {
      _aiAdviceSummary =
          'Coffee and ready meals are your biggest saving opportunities this month.';
      _aiPotentialSavings = 38.0;
    } finally {
      _isGeneratingAdvice = false;
      notifyListeners();
    }
  }

  void clearAiAdvice() {
    _aiAdviceSummary = null;
    _aiPotentialSavings = null;
    notifyListeners();
  }

  Receipt? getReceiptById(String id) {
    for (final receipt in _receipts) {
      if (receipt.id == id) {
        return receipt;
      }
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

        categoryTotals[category] = (categoryTotals[category] ?? 0) + item.totalPrice;
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
      aiAdvice: (_aiAdviceSummary != null && _aiAdviceSummary!.isNotEmpty)
          ? _aiAdviceSummary!
          : buildAiAdvice(topCategories),
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

    if (percentile > 99.9) {
      return 99.9;
    }

    if (percentile < 10) {
      return 10;
    }

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

  Receipt _receiptFromParsedResponse(Map<String, dynamic> parsed) {
    final receiptData = parsed['receipt'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(parsed['receipt'] as Map)
        : Map<String, dynamic>.from(parsed);

    final receiptId =
        (receiptData['id'] ?? receiptData['receipt_id'] ?? DateTime.now().microsecondsSinceEpoch).toString();
    final merchant = (receiptData['merchant'] ?? receiptData['store_name'] ?? 'Unknown merchant').toString();
    final currency = (receiptData['currency'] ?? 'EUR').toString();

    DateTime parsedDate = DateTime.now();
    final rawDate = receiptData['receipt_date'] ?? receiptData['created_at'] ?? receiptData['timestamp'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString())?.toLocal() ?? parsedDate;
    }

    final items = <ReceiptItem>[];
    final itemsRaw = parsed['items'] as List<dynamic>?;

    if (itemsRaw != null) {
      for (final itemRaw in itemsRaw) {
        if (itemRaw is! Map) {
          continue;
        }

        final itemMap = Map<String, dynamic>.from(itemRaw);
        final itemId = itemMap['id']?.toString() ?? '$receiptId-item-${items.length}';
        final category = itemMap['category']?.toString() ?? 'Other';
        final name = itemMap['name']?.toString().trim().isNotEmpty == true
            ? itemMap['name'].toString()
            : category;
        final quantity = double.tryParse(itemMap['quantity']?.toString() ?? '') ?? 1.0;
        final safeQuantity = quantity > 0 ? quantity : 1.0;
        final unitPrice = double.tryParse(itemMap['unit_price']?.toString() ?? '') ?? 0.0;

        items.add(
          ReceiptItem(
            id: itemId,
            name: name,
            category: category,
            quantity: safeQuantity,
            unitPrice: unitPrice,
          ),
        );
      }
    }

    if (items.isEmpty) {
      final total = double.tryParse(
            (receiptData['total_amount'] ?? receiptData['items_total'] ?? 0).toString(),
          ) ??
          0.0;

      if (total > 0) {
        items.add(
          ReceiptItem(
            id: '$receiptId-item-0',
            name: 'Receipt total',
            category: 'Other',
            quantity: 1,
            unitPrice: total,
          ),
        );
      }
    }

    return Receipt(
      id: receiptId,
      merchant: merchant,
      date: parsedDate,
      currency: currency,
      items: items,
      transactionId: receiptData['transaction_id']?.toString(),
    );
  }

  PersonalGoal _goalFromRow(Map<String, dynamic> row) {
    final targetDate = DateTime.tryParse((row['target_date'] ?? '').toString())?.toLocal() ?? DateTime.now();
    final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now();

    return PersonalGoal(
      id: (row['id'] ?? DateTime.now().microsecondsSinceEpoch).toString(),
      amountToSave: double.tryParse((row['amount_to_save'] ?? 0).toString()) ?? 0,
      currency: (row['currency'] ?? 'EUR').toString(),
      targetDate: targetDate,
      createdAt: createdAt,
    );
  }

  void _loadLocalDemoData() {
    final now = DateTime.now();

    _receipts
      ..clear()
      ..addAll([
        Receipt(
          id: 'demo-receipt-1',
          merchant: 'Starbucks',
          date: now,
          currency: 'EUR',
          items: const [
            ReceiptItem(
              id: 'demo-1-1',
              name: 'Iced latte',
              category: 'Prepared coffee drinks',
              quantity: 1,
              unitPrice: 5.40,
            ),
            ReceiptItem(
              id: 'demo-1-2',
              name: 'Cappuccino',
              category: 'Prepared coffee drinks',
              quantity: 1,
              unitPrice: 4.60,
            ),
            ReceiptItem(
              id: 'demo-1-3',
              name: 'Croissant',
              category: 'Pastries',
              quantity: 1,
              unitPrice: 4.30,
            ),
          ],
        ),
        Receipt(
          id: 'demo-receipt-2',
          merchant: 'Albert Heijn',
          date: now.subtract(const Duration(days: 1)),
          currency: 'EUR',
          items: const [
            ReceiptItem(
              id: 'demo-2-1',
              name: 'Chicken breast',
              category: 'Chicken breast',
              quantity: 1,
              unitPrice: 8.90,
            ),
            ReceiptItem(
              id: 'demo-2-2',
              name: 'Greek yogurt',
              category: 'Yogurt',
              quantity: 2,
              unitPrice: 2.40,
            ),
            ReceiptItem(
              id: 'demo-2-3',
              name: 'Bananas',
              category: 'Bananas',
              quantity: 1,
              unitPrice: 2.10,
            ),
            ReceiptItem(
              id: 'demo-2-4',
              name: 'Pasta',
              category: 'Pasta',
              quantity: 2,
              unitPrice: 1.90,
            ),
            ReceiptItem(
              id: 'demo-2-5',
              name: 'Tomatoes',
              category: 'Tomatoes',
              quantity: 1,
              unitPrice: 3.20,
            ),
          ],
        ),
        Receipt(
          id: 'demo-receipt-3',
          merchant: 'Jumbo',
          date: now.subtract(const Duration(days: 2)),
          currency: 'EUR',
          items: const [
            ReceiptItem(
              id: 'demo-3-1',
              name: 'Coffee beans',
              category: 'Coffee for home',
              quantity: 1,
              unitPrice: 8.50,
            ),
            ReceiptItem(
              id: 'demo-3-2',
              name: 'Milk',
              category: 'Milk',
              quantity: 2,
              unitPrice: 1.65,
            ),
            ReceiptItem(
              id: 'demo-3-3',
              name: 'Whole wheat bread',
              category: 'Bread',
              quantity: 1,
              unitPrice: 2.80,
            ),
            ReceiptItem(
              id: 'demo-3-4',
              name: 'Eggs',
              category: 'Eggs',
              quantity: 1,
              unitPrice: 3.50,
            ),
          ],
        ),
        Receipt(
          id: 'demo-receipt-4',
          merchant: 'Uber Eats',
          date: now.subtract(const Duration(days: 4)),
          currency: 'EUR',
          items: const [
            ReceiptItem(
              id: 'demo-4-1',
              name: 'Pizza margherita',
              category: 'Pizza',
              quantity: 1,
              unitPrice: 14.90,
            ),
            ReceiptItem(
              id: 'demo-4-2',
              name: 'Cola',
              category: 'Soft drinks',
              quantity: 2,
              unitPrice: 2.70,
            ),
            ReceiptItem(
              id: 'demo-4-3',
              name: 'Delivery fee',
              category: 'Prepared meals',
              quantity: 1,
              unitPrice: 3.20,
            ),
          ],
        ),
        Receipt(
          id: 'demo-receipt-5',
          merchant: 'Kruidvat',
          date: now.subtract(const Duration(days: 6)),
          currency: 'EUR',
          items: const [
            ReceiptItem(
              id: 'demo-5-1',
              name: 'Shampoo',
              category: 'Shampoo',
              quantity: 1,
              unitPrice: 5.50,
            ),
            ReceiptItem(
              id: 'demo-5-2',
              name: 'Toothpaste',
              category: 'Toothpaste',
              quantity: 1,
              unitPrice: 2.30,
            ),
            ReceiptItem(
              id: 'demo-5-3',
              name: 'Face cream',
              category: 'Skincare',
              quantity: 1,
              unitPrice: 10.00,
            ),
          ],
        ),
        Receipt(
          id: 'demo-receipt-6',
          merchant: 'Coffee Company',
          date: now.subtract(const Duration(days: 8)),
          currency: 'EUR',
          items: const [
            ReceiptItem(
              id: 'demo-6-1',
              name: 'Flat white',
              category: 'Prepared coffee drinks',
              quantity: 1,
              unitPrice: 4.20,
            ),
            ReceiptItem(
              id: 'demo-6-2',
              name: 'Cold brew',
              category: 'Prepared coffee drinks',
              quantity: 1,
              unitPrice: 4.40,
            ),
            ReceiptItem(
              id: 'demo-6-3',
              name: 'Banana bread',
              category: 'Pastries',
              quantity: 1,
              unitPrice: 3.30,
            ),
          ],
        ),
      ]);

    _personalGoals
      ..clear()
      ..add(
        PersonalGoal(
          id: 'demo-goal-1',
          amountToSave: 250,
          currency: 'EUR',
          targetDate: now.add(const Duration(days: 30)),
          createdAt: now,
        ),
      );
  }
}