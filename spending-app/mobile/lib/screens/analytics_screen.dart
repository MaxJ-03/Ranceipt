import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../theme/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        final analytics = provider.getAnalytics();
        final categories = analytics.topItemCategories;
        final topCategory = categories.isNotEmpty ? categories.first : null;

        return Container(
          color: AppColors.bg,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AnalyticsHeader(),
                      const SizedBox(height: 24),
                      if (topCategory == null)
                        const EmptyAnalyticsCard()
                      else
                        RankingHero(category: topCategory),
                      const SizedBox(height: 32),
                      const AnalyticsSectionHeader(
                        title: 'Percentiles',
                        subtitle: 'How your categories compare',
                      ),
                      const SizedBox(height: 16),
                      if (categories.isEmpty)
                        const AnalyticsEmptyText('No percentile data yet.')
                      else
                        ...categories.map(
                          (category) => PercentileCard(category: category),
                        ),
                      const SizedBox(height: 32),
                      const AnalyticsSectionHeader(
                        title: 'Spend mix',
                        subtitle: 'Share of tracked spending',
                      ),
                      const SizedBox(height: 16),
                      if (categories.isEmpty)
                        const AnalyticsEmptyText('No spending mix yet.')
                      else
                        SpendMix(analytics: analytics),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnalyticsHeader extends StatelessWidget {
  const AnalyticsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stats',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Your spending, ranked clearly.',
          style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.35),
        ),
      ],
    );
  }
}

class RankingHero extends StatelessWidget {
  final ItemCategorySpending category;

  const RankingHero({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final visual = analyticsCategoryVisual(
      category.itemCategory,
      category.percentile,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Highest rank',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.itemCategory,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              BigRankRing(
                value: category.percentile / 100,
                color: visual.color,
                icon: visual.icon,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${category.percentile.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.4,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analyticsRankLabel(category.percentile),
                      style: TextStyle(
                        color: visual.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Compared with other users.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigRankRing extends StatelessWidget {
  final double value;
  final Color color;
  final IconData icon;

  const BigRankRing({
    super.key,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return SizedBox(
          height: 112,
          width: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: animated,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withOpacity(0.10),
                color: color,
              ),
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.bg.withOpacity(0.34),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PercentileCard extends StatelessWidget {
  final ItemCategorySpending category;

  const PercentileCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final visual = analyticsCategoryVisual(
      category.itemCategory,
      category.percentile,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnalyticsIconBadge(icon: visual.icon, color: visual.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.itemCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${category.percentile.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: category.percentile / 100),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: AppColors.surfaceSoft,
                  color: visual.color,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                analyticsRankLabel(category.percentile),
                style: TextStyle(
                  color: visual.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '€${category.amount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnalyticsIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const AnalyticsIconBadge({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class SpendMix extends StatelessWidget {
  final SpendingAnalytics analytics;

  const SpendMix({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final categories = analytics.topItemCategories.take(5).toList();
    final total = analytics.totalSpending <= 0 ? 1.0 : analytics.totalSpending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: categories.map((category) {
          final visual = analyticsCategoryVisual(
            category.itemCategory,
            category.percentile,
          );

          final share = category.amount / total;
          final safeShare = share < 0
              ? 0.0
              : share > 1
              ? 1.0
              : share;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                AnalyticsIconBadge(icon: visual.icon, color: visual.color),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Text(
                    category.itemCategory,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: safeShare,
                      minHeight: 9,
                      backgroundColor: AppColors.surfaceSoft,
                      color: visual.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(share * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AnalyticsSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AnalyticsSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      ],
    );
  }
}

class EmptyAnalyticsCard extends StatelessWidget {
  const EmptyAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsIconBadge(
            icon: Icons.insights_outlined,
            color: AppColors.aqua,
          ),
          SizedBox(height: 20),
          Text(
            'No stats yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Scan receipts to generate your ranking analytics.',
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class AnalyticsEmptyText extends StatelessWidget {
  final String text;

  const AnalyticsEmptyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.muted, fontSize: 16),
    );
  }
}

class AnalyticsCategoryVisual {
  final IconData icon;
  final Color color;

  const AnalyticsCategoryVisual({required this.icon, required this.color});
}

AnalyticsCategoryVisual analyticsCategoryVisual(
  String category,
  double percentile,
) {
  final name = category.toLowerCase().trim();

  if (hasAny(name, [
    'coffee',
    'latte',
    'cappuccino',
    'espresso',
    'americano',
    'mocha',
    'macchiato',
    'prepared coffee',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.local_cafe_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, ['tea', 'chai', 'matcha', 'iced tea'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.emoji_food_beverage_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'water',
    'juice',
    'soda',
    'drink',
    'beverage',
    'cola',
    'smoothie',
    'energy drink',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.local_drink_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, ['beer', 'wine', 'alcohol', 'cocktail'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.wine_bar_outlined,
      color: AppColors.rose,
    );
  }

  if (hasAny(name, [
    'pet',
    'dog',
    'cat',
    'animal',
    'pet food',
    'cat food',
    'dog food',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.pets_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'beef',
    'steak',
    'meat',
    'minced meat',
    'pork',
    'bacon',
    'sausage',
    'ham',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.dinner_dining_outlined,
      color: AppColors.rose,
    );
  }

  if (hasAny(name, ['chicken', 'chicken breast', 'turkey', 'poultry'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.lunch_dining_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, ['fish', 'salmon', 'tuna', 'seafood', 'shrimp', 'prawn'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.set_meal_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, ['egg', 'eggs'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.egg_alt_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, ['milk', 'yogurt', 'cheese', 'dairy', 'cream', 'butter'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.icecream_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, [
    'bread',
    'bakery',
    'croissant',
    'bagel',
    'bun',
    'toast',
    'pastry',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.bakery_dining_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, [
    'pasta',
    'spaghetti',
    'noodle',
    'ramen',
    'rice',
    'grain',
    'cereal',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.ramen_dining_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, [
    'fruit',
    'apple',
    'banana',
    'orange',
    'berries',
    'grape',
    'mango',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.apple_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'vegetable',
    'vegetables',
    'salad',
    'lettuce',
    'tomato',
    'cucumber',
    'carrot',
    'greens',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.eco_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'snack',
    'chips',
    'crisps',
    'candy',
    'chocolate',
    'cookie',
    'cookies',
    'sweets',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.cookie_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, ['frozen', 'ice cream', 'frozen food'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.ac_unit_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, [
    'grocery',
    'groceries',
    'supermarket',
    'market',
    'food shopping',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.shopping_basket_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'restaurant',
    'dinner',
    'lunch',
    'takeout',
    'delivery',
    'fast food',
    'meal',
    'food',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.restaurant_outlined,
      color: AppColors.rose,
    );
  }

  if (hasAny(name, [
    'transport',
    'train',
    'bus',
    'metro',
    'tram',
    'uber',
    'taxi',
    'ride',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.directions_transit_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, [
    'fuel',
    'gas',
    'petrol',
    'diesel',
    'parking',
    'car wash',
    'car',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.local_gas_station_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, ['bike', 'bicycle', 'scooter'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.pedal_bike_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, [
    'subscription',
    'phone',
    'mobile',
    'app',
    'software',
    'cloud',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.phone_iphone_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, ['music', 'spotify', 'audio', 'playlist'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.music_note_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'movie',
    'netflix',
    'cinema',
    'entertainment',
    'streaming',
    'youtube',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.movie_outlined,
      color: AppColors.rose,
    );
  }

  if (hasAny(name, ['game', 'gaming', 'playstation', 'xbox', 'nintendo'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.sports_esports_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, ['book', 'books', 'reading', 'magazine', 'education'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.menu_book_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, [
    'health',
    'pharmacy',
    'medicine',
    'medical',
    'doctor',
    'care',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.local_pharmacy_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, ['gym', 'sport', 'fitness', 'workout', 'training'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.fitness_center_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, [
    'clothes',
    'clothing',
    'fashion',
    'shoes',
    'shirt',
    'jacket',
    'pants',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.checkroom_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, [
    'beauty',
    'cosmetic',
    'makeup',
    'skincare',
    'hair',
    'perfume',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.spa_outlined,
      color: AppColors.rose,
    );
  }

  if (hasAny(name, [
    'home',
    'furniture',
    'cleaning',
    'kitchen',
    'household',
    'decor',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.home_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, ['gift', 'present', 'birthday'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.card_giftcard_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, [
    'travel',
    'hotel',
    'flight',
    'airport',
    'holiday',
    'vacation',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.flight_takeoff_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, [
    'electronics',
    'tech',
    'laptop',
    'computer',
    'headphones',
    'charger',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.devices_outlined,
      color: AppColors.aqua,
    );
  }

  if (hasAny(name, ['rent', 'mortgage', 'housing'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.apartment_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, [
    'bill',
    'utilities',
    'electricity',
    'water bill',
    'internet',
    'wifi',
  ])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.receipt_outlined,
      color: AppColors.amber,
    );
  }

  if (hasAny(name, ['insurance', 'bank', 'fee', 'finance', 'payment'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.account_balance_outlined,
      color: AppColors.primary,
    );
  }

  if (hasAny(name, ['baby', 'kids', 'children', 'toys'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.toys_outlined,
      color: AppColors.green,
    );
  }

  if (hasAny(name, ['office', 'work', 'stationery', 'paper', 'pen'])) {
    return const AnalyticsCategoryVisual(
      icon: Icons.work_outline,
      color: AppColors.aqua,
    );
  }

  return fallbackCategoryVisual(name, percentile);
}

bool hasAny(String text, List<String> words) {
  for (final word in words) {
    if (text.contains(word)) {
      return true;
    }
  }
  return false;
}

AnalyticsCategoryVisual fallbackCategoryVisual(
  String category,
  double percentile,
) {
  final fallbackIcons = [
    Icons.shopping_bag_outlined,
    Icons.sell_outlined,
    Icons.inventory_2_outlined,
    Icons.widgets_outlined,
    Icons.local_offer_outlined,
    Icons.category_outlined,
    Icons.star_border_rounded,
    Icons.bubble_chart_outlined,
    Icons.pie_chart_outline_rounded,
    Icons.auto_graph_outlined,
  ];

  final fallbackColors = [
    AppColors.primary,
    AppColors.aqua,
    AppColors.amber,
    AppColors.green,
    AppColors.rose,
  ];

  final hash = category.codeUnits.fold<int>(0, (sum, code) => sum + code);

  return AnalyticsCategoryVisual(
    icon: fallbackIcons[hash % fallbackIcons.length],
    color: fallbackColors[hash % fallbackColors.length],
  );
}

Color analyticsRankColor(double percentile) {
  if (percentile >= 90) return AppColors.rose;
  if (percentile >= 70) return AppColors.amber;
  return AppColors.green;
}

String analyticsRankLabel(double percentile) {
  if (percentile >= 95) return 'Top spender';
  if (percentile >= 80) return 'High';
  if (percentile >= 50) return 'Above average';
  return 'Low';
}
