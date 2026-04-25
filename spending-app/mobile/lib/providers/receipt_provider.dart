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
      } catch (_) {
        // Transaction sync can fail in sandbox edge cases; receipt/goal sync should still proceed.
      }

      final receiptRows = await _backendApi.getReceipts();
      final fetchedReceipts = <Receipt>[];

      for (final row in receiptRows) {
        final receiptId = int.tryParse(row['id'].toString());
        if (receiptId == null) {
          continue;
        }

        final parsed = await _backendApi.getParsedReceipt(receiptId);
        fetchedReceipts.add(_receiptFromParsedResponse(parsed));
      }

      final goalRows = await _backendApi.getGoals();
      final fetchedGoals = goalRows.map(_goalFromRow).toList();

      _receipts
        ..clear()
        ..addAll(fetchedReceipts);

      _personalGoals
        ..clear()
        ..addAll(fetchedGoals);
    } catch (e) {
      _syncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> uploadReceiptFromImage(XFile image) async {
    _isUploadingReceipt = true;
    _syncError = null;
    notifyListeners();

    try {
      final parsed = await _backendApi.uploadReceiptAndParse(image);
      final receipt = _receiptFromParsedResponse(parsed);

      _receipts.insert(0, receipt);
      _aiAdviceSummary = null;
      _aiPotentialSavings = null;
    } catch (e) {
      _syncError = e.toString();
      rethrow;
    } finally {
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
        throw Exception('Manual receipt response did not include an id');
      }

      final parsed = await _backendApi.getParsedReceipt(receiptId);
      final receipt = _receiptFromParsedResponse(parsed);
      _receipts.insert(0, receipt);
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
    await _backendApi.createGoal(
      amountToSave: amountToSave,
      targetDate: targetDate,
      currency: currency,
    );

    final goalRows = await _backendApi.getGoals();
    _personalGoals
      ..clear()
      ..addAll(goalRows.map(_goalFromRow));

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
    } catch (e) {
      _syncError = e.toString();
      rethrow;
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
    final receiptId = (parsed['receipt_id'] ?? DateTime.now().microsecondsSinceEpoch).toString();
    final merchant = (parsed['merchant'] ?? 'Unknown merchant').toString();
    final currency = (parsed['currency'] ?? 'EUR').toString();

    DateTime parsedDate = DateTime.now();
    final rawTimestamp = parsed['timestamp']?.toString();
    if (rawTimestamp != null && rawTimestamp.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawTimestamp)?.toLocal() ?? DateTime.now();
    }

    final categoryTotalsRaw = parsed['category_totals'];
    final categoryQuantitiesRaw = parsed['category_quantities'];

    final categoryTotals = <String, dynamic>{};
    final categoryQuantities = <String, dynamic>{};

    if (categoryTotalsRaw is Map) {
      categoryTotals.addAll(Map<String, dynamic>.from(categoryTotalsRaw));
    }

    if (categoryQuantitiesRaw is Map) {
      categoryQuantities.addAll(Map<String, dynamic>.from(categoryQuantitiesRaw));
    }

    final items = <ReceiptItem>[];
    int index = 0;

    for (final entry in categoryTotals.entries) {
      final total = double.tryParse(entry.value.toString()) ?? 0;
      if (total <= 0) {
        continue;
      }

      final quantity = double.tryParse((categoryQuantities[entry.key] ?? 1).toString()) ?? 1;
      final safeQuantity = quantity > 0 ? quantity : 1;
      final unitPrice = total / safeQuantity;

      items.add(
        ReceiptItem(
          id: '$receiptId-item-$index',
          name: entry.key,
          category: entry.key,
          quantity: safeQuantity,
          unitPrice: unitPrice,
        ),
      );
      index += 1;
    }

    return Receipt(
      id: receiptId,
      merchant: merchant,
      date: parsedDate,
      currency: currency,
      items: items,
      transactionId: parsed['transaction_id']?.toString(),
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
}
