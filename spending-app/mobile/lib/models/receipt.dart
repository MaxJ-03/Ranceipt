class Receipt {
  final String id;
  final String storeName;
  final DateTime date;
  final double total;
  final List<ReceiptLineItem> lineItems;
  final String? imagePath;
  final bool isProcessed;

  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.total,
    required this.lineItems,
    this.imagePath,
    this.isProcessed = false,
  });
}

class ReceiptLineItem {
  final String id;
  final String name;
  final String? detailedCategory; // e.g., "Milk", "Eggs", "Bread"
  final double price;
  final int quantity;
  final bool isCategorized;

  ReceiptLineItem({
    required this.id,
    required this.name,
    this.detailedCategory,
    required this.price,
    required this.quantity,
    this.isCategorized = false,
  });

  double get subtotal => price * quantity;
}

class ItemCategorySpending {
  final String itemCategory; // e.g., "Milk", "Eggs"
  final double amount;
  final int transactionCount;
  final double percentile; // 0-100
  final String percentileText;
  final double percentileRank; // How much user spends more than others

  ItemCategorySpending({
    required this.itemCategory,
    required this.amount,
    required this.transactionCount,
    required this.percentile,
    required this.percentileText,
    required this.percentileRank,
  });
}

class SpendingAnalytics {
  final double totalSpending;
  final double averageTransaction;
  final int transactionCount;
  final Map<String, double> itemCategoryBreakdown; // Detailed items
  final List<ItemCategorySpending> topItemCategories;
  final List<DailySpending> dailyTrend;
  final Map<String, int> categoryFrequency; // How often items are bought

  SpendingAnalytics({
    required this.totalSpending,
    required this.averageTransaction,
    required this.transactionCount,
    required this.itemCategoryBreakdown,
    required this.topItemCategories,
    required this.dailyTrend,
    required this.categoryFrequency,
  });
}

class DailySpending {
  final DateTime date;
  final double amount;

  DailySpending({required this.date, required this.amount});
}

// Global category list for reference
const List<String> DETAILED_ITEM_CATEGORIES = [
  // Bread & Baked Goods
  'Bread', 'Pastries', 'Cakes',
  // Dairy & Alternatives
  'Eggs',
  'Milk',
  'Plant-based milk',
  'Butter',
  'Cheese',
  'Soft cheese and spreads',
  'Yogurt',
  'Cream',
  // Meat & Protein
  'Chicken breast',
  'Chicken thighs',
  'Beef',
  'Pork',
  'Lamb',
  'Turkey',
  'Deli meat',
  'Sausages',
  'Bacon',
  'Fish',
  'Seafood',
  // Grains & Carbs
  'Rice', 'Pasta', 'Noodles', 'Flour', 'Sugar', 'Oats', 'Cereal', 'Granola',
  // Legumes & Nuts
  'Beans', 'Lentils', 'Chickpeas', 'Nuts', 'Seeds', 'Dried fruit',
  // Fresh Fruit
  'Apples',
  'Bananas',
  'Oranges',
  'Lemons and limes',
  'Grapes',
  'Berries',
  'Melons',
  'Stone fruit',
  'Tropical fruit',
  'Avocados',
  // Fresh Vegetables
  'Potatoes',
  'Sweet potatoes',
  'Onions',
  'Garlic',
  'Carrots',
  'Tomatoes',
  'Cucumbers',
  'Lettuce',
  'Spinach',
  'Broccoli',
  'Cauliflower',
  'Peppers',
  'Mushrooms',
  'Zucchini',
  'Eggplant',
  'Cabbage',
  'Leeks',
  'Asparagus',
  'Fresh herbs',
  // Frozen & Canned
  'Frozen vegetables',
  'Frozen fruit',
  'Canned vegetables',
  'Canned fruit',
  'Canned fish',
  'Canned meat',
  // Prepared Foods
  'Soup', 'Pizza', 'Prepared meals', 'Sandwiches', 'Salads',
  // Condiments & Cooking
  'Sauces',
  'Condiments',
  'Cooking oil',
  'Vinegar',
  'Salt',
  'Spices',
  'Stock',
  'Baking ingredients',
  // Sweets & Snacks
  'Chocolate',
  'Candy',
  'Packaged snacks',
  'Ice cream',
  'Desserts',
  'Gum and mints',
  // Beverages
  'Coffee for home',
  'Prepared coffee drinks',
  'Tea',
  'Bottled water',
  'Sparkling water',
  'Juice',
  'Smoothies',
  'Soft drinks',
  'Energy drinks',
  'Sports drinks',
  // Alcohol
  'Beer',
  'Wine',
  'Sparkling wine',
  'Cider',
  'Spirits',
  'Ready-to-drink alcoholic drinks',
  'Non-alcoholic beer and wine',
  // Tobacco
  'Cigarettes',
  'Rolling tobacco',
  'Vapes',
  'Nicotine pouches',
  'Smoking accessories',
  // Personal Care
  'Shampoo',
  'Conditioner',
  'Body wash',
  'Soap',
  'Toothpaste',
  'Toothbrushes',
  'Deodorant',
  'Skincare',
  'Hair styling products',
  'Razors',
  'Shaving products',
  'Feminine care',
  'Condoms',
  // Household & Cleaning
  'Toilet paper',
  'Paper towels',
  'Tissues',
  'Laundry detergent',
  'Fabric softener',
  'Dish soap',
  'Dishwasher products',
  'Surface cleaner',
  'Bathroom cleaner',
  'Trash bags',
  'Foil and food wrap',
  'Food storage bags',
  // Other
  'Batteries',
  'Light bulbs',
  'Baby products',
  'Pet food',
  'Pet products',
  'Over-the-counter medicine',
  'Vitamins',
  'First aid products',
];
