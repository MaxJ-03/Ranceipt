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
        final otherCategories = categories.skip(1).toList();

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
                        title: 'All rankings',
                        subtitle: 'Every category found in your receipts',
                      ),
                      const SizedBox(height: 16),
                      if (categories.isEmpty)
                        const AnalyticsEmptyText('No ranking data yet.')
                      else ...[
                        if (otherCategories.isEmpty)
                          AnalyticsSingleCategoryCard(category: topCategory!)
                        else
                          ...otherCategories.map(
                            (category) => PercentileCard(category: category),
                          ),
                      ],
                      const SizedBox(height: 32),
                      const AnalyticsSectionHeader(
                        title: 'Spend mix',
                        subtitle: 'Share of your tracked spending',
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
          'Percentiles and spending patterns.',
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
    final color = analyticsCategoryColor(category.itemCategory);
    final icon = categoryIcon(category.itemCategory);

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
            'Highest percentile',
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
                color: color,
                icon: icon,
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
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '€${category.amount.toStringAsFixed(2)} tracked',
                      style: const TextStyle(
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

class AnalyticsSingleCategoryCard extends StatelessWidget {
  final ItemCategorySpending category;

  const AnalyticsSingleCategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Only one category found so far. Scan more receipts to compare more topics.',
        style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
      ),
    );
  }
}

class PercentileCard extends StatelessWidget {
  final ItemCategorySpending category;

  const PercentileCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = analyticsCategoryColor(category.itemCategory);
    final icon = categoryIcon(category.itemCategory);

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
              AnalyticsIconBadge(icon: icon, color: color),
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
                  color: color,
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
                  color: color,
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

class SpendMix extends StatelessWidget {
  final SpendingAnalytics analytics;

  const SpendMix({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final categories = analytics.topItemCategories;
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
          final color = analyticsCategoryColor(category.itemCategory);
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
                AnalyticsIconBadge(
                  icon: categoryIcon(category.itemCategory),
                  color: color,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
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
                      color: color,
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

Color analyticsCategoryColor(String category) {
  final name = category.toLowerCase();

  if (name.contains('coffee') ||
      name.contains('tea') ||
      name.contains('bakery') ||
      name.contains('grains')) {
    return AppColors.amber;
  }

  if (name.contains('fruit') ||
      name.contains('vegetable') ||
      name.contains('pets') ||
      name.contains('health')) {
    return AppColors.green;
  }

  if (name.contains('meat') ||
      name.contains('poultry') ||
      name.contains('ready meals') ||
      name.contains('snacks') ||
      name.contains('alcohol') ||
      name.contains('nicotine')) {
    return AppColors.rose;
  }

  if (name.contains('fish') ||
      name.contains('dairy') ||
      name.contains('drinks') ||
      name.contains('household') ||
      name.contains('personal care')) {
    return AppColors.aqua;
  }

  return AppColors.primary;
}

String analyticsRankLabel(double percentile) {
  if (percentile >= 95) return 'Top spender';
  if (percentile >= 80) return 'High';
  if (percentile >= 50) return 'Above average';

  return 'Low';
}
