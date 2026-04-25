import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../theme/app_colors.dart';
import 'analytics_screen.dart';
import 'receipt_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ReceiptProvider>().syncWithBackend();
    });
  }

  Widget buildCurrentPage() {
    if (selectedIndex == 0) {
      return HomeView(onAddReceipt: () => showAddReceiptOptions(context));
    }

    if (selectedIndex == 1) {
      return const AnalyticsScreen();
    }

    return const ReceiptListScreen();
  }

  void showAddReceiptOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withOpacity(0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.faint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                SheetAction(
                  icon: Icons.document_scanner_outlined,
                  title: 'Scan receipt',
                  subtitle: 'Use camera',
                  color: AppColors.aqua,
                  onTap: () {
                    Navigator.pop(context);
                    showMessage(context, 'Camera scanning coming soon.');
                  },
                ),
                const SizedBox(height: 10),
                SheetAction(
                  icon: Icons.image_outlined,
                  title: 'Upload photo',
                  subtitle: 'Choose from gallery',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    showMessage(context, 'Photo upload coming soon.');
                  },
                ),
                const SizedBox(height: 10),
                SheetAction(
                  icon: Icons.edit_note_outlined,
                  title: 'Manual entry',
                  subtitle: 'Add purchase manually',
                  color: AppColors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    showMessage(context, 'Manual entry coming soon.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: buildCurrentPage()),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.text,
          unselectedItemColor: AppColors.faint,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Receipts',
            ),
          ],
        ),
      ),
      floatingActionButton: selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => showAddReceiptOptions(context),
              backgroundColor: AppColors.aqua,
              foregroundColor: AppColors.bg,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

class HomeView extends StatelessWidget {
  final VoidCallback onAddReceipt;

  const HomeView({super.key, required this.onAddReceipt});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        final analytics = provider.getAnalytics();
        final topItems = analytics.topItemCategories.take(4).toList();
        final topItem = topItems.isNotEmpty ? topItems.first : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TopBar(),
                    const SizedBox(height: 24),
                    if (topItem == null)
                      EmptyHeroCard(onAddReceipt: onAddReceipt)
                    else
                      HeroCard(category: topItem, onAddReceipt: onAddReceipt),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: 'Spent',
                            value:
                                '€${analytics.totalSpending.toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet_outlined,
                            accent: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'Receipts',
                            value: '${analytics.transactionCount}',
                            icon: Icons.receipt_long_outlined,
                            accent: AppColors.aqua,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const SectionHeader(
                      title: 'Top categories',
                      subtitle: 'Your strongest spending signals',
                    ),
                    const SizedBox(height: 16),
                    if (topItems.isEmpty)
                      const EmptyText('No category data yet.')
                    else
                      ...topItems.map((item) => CategoryRow(category: item)),
                    const SizedBox(height: 32),
                    const SectionHeader(
                      title: 'Insights',
                      subtitle: 'Simple actions, clear impact',
                    ),
                    const SizedBox(height: 16),
                    ...buildInsights(analytics),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> buildInsights(SpendingAnalytics analytics) {
    if (analytics.topItemCategories.isEmpty) {
      return const [
        InsightCard(
          icon: Icons.document_scanner_outlined,
          title: 'Start with one receipt',
          text: 'Scan a receipt to unlock rankings and suggestions.',
          color: AppColors.primary,
        ),
      ];
    }

    final top = analytics.topItemCategories.first;
    final high = analytics.topItemCategories
        .where((item) => item.percentile >= 80)
        .toList();

    final topVisual = dashboardCategoryVisual(top.itemCategory, top.percentile);

    final cards = <Widget>[
      InsightCard(
        icon: topVisual.icon,
        title: 'Highest rank',
        text: '${top.itemCategory} is your strongest category.',
        color: topVisual.color,
      ),
    ];

    if (high.isNotEmpty) {
      cards.add(const SizedBox(height: 12));
      cards.add(
        InsightCard(
          icon: Icons.trending_up_rounded,
          title: 'High-spend signal',
          text: high.map((c) => c.itemCategory).join(', '),
          color: AppColors.rose,
        ),
      );
    }

    cards.add(const SizedBox(height: 12));
    cards.add(
      const InsightCard(
        icon: Icons.savings_outlined,
        title: 'Saving move',
        text: 'Reduce your highest-ranked category by 20%.',
        color: AppColors.green,
      ),
    );

    return cards;
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: AppColors.logoGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: AppColors.bg),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ranceipt',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Scan. Compare. Save.',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HeroCard extends StatelessWidget {
  final ItemCategorySpending category;
  final VoidCallback onAddReceipt;

  const HeroCard({
    super.key,
    required this.category,
    required this.onAddReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final visual = dashboardCategoryVisual(
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
            'Top percentile',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MiniRing(
                value: category.percentile / 100,
                color: visual.color,
                icon: visual.icon,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.itemCategory,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'More than ${category.percentile.toStringAsFixed(1)}% of users',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onAddReceipt,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add receipt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aqua,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniRing extends StatelessWidget {
  final double value;
  final Color color;
  final IconData icon;

  const MiniRing({
    super.key,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: animated,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withOpacity(0.10),
                color: color,
              ),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.bg.withOpacity(0.34),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 27),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIconBadge(icon: icon, color: accent),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRow extends StatelessWidget {
  final ItemCategorySpending category;

  const CategoryRow({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final visual = dashboardCategoryVisual(
      category.itemCategory,
      category.percentile,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          CategoryIconBadge(icon: visual.icon, color: visual.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.itemCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: category.percentile / 100),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceSoft,
                        color: visual.color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${category.percentile.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '€${category.amount.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const CategoryIconBadge({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIconBadge(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyHeroCard extends StatelessWidget {
  final VoidCallback onAddReceipt;

  const EmptyHeroCard({super.key, required this.onAddReceipt});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CategoryIconBadge(
            icon: Icons.document_scanner_outlined,
            color: AppColors.aqua,
          ),
          const SizedBox(height: 20),
          const Text(
            'No rankings yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan receipts to build your spending profile.',
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onAddReceipt,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add receipt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aqua,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeader({super.key, required this.title, required this.subtitle});

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

class EmptyText extends StatelessWidget {
  final String text;

  const EmptyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.muted, fontSize: 16),
    );
  }
}

class SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const SheetAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: AppColors.surfaceSoft,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        onTap: onTap,
      ),
    );
  }
}

class DashboardCategoryVisual {
  final IconData icon;
  final Color color;

  const DashboardCategoryVisual({required this.icon, required this.color});
}

DashboardCategoryVisual dashboardCategoryVisual(
  String category,
  double percentile,
) {
  final name = category.toLowerCase();

  if (name.contains('coffee') ||
      name.contains('latte') ||
      name.contains('cappuccino')) {
    return const DashboardCategoryVisual(
      icon: Icons.local_cafe_outlined,
      color: AppColors.amber,
    );
  }

  if (name.contains('pet') || name.contains('dog') || name.contains('cat')) {
    return const DashboardCategoryVisual(
      icon: Icons.pets_outlined,
      color: AppColors.green,
    );
  }

  if (name.contains('beef') ||
      name.contains('meat') ||
      name.contains('steak')) {
    return const DashboardCategoryVisual(
      icon: Icons.dinner_dining_outlined,
      color: AppColors.rose,
    );
  }

  if (name.contains('chicken')) {
    return const DashboardCategoryVisual(
      icon: Icons.lunch_dining_outlined,
      color: AppColors.amber,
    );
  }

  if (name.contains('pasta') || name.contains('noodle')) {
    return const DashboardCategoryVisual(
      icon: Icons.ramen_dining_outlined,
      color: AppColors.primary,
    );
  }

  if (name.contains('grocery') ||
      name.contains('groceries') ||
      name.contains('supermarket')) {
    return const DashboardCategoryVisual(
      icon: Icons.shopping_basket_outlined,
      color: AppColors.green,
    );
  }

  if (name.contains('restaurant') ||
      name.contains('food') ||
      name.contains('dinner')) {
    return const DashboardCategoryVisual(
      icon: Icons.restaurant_outlined,
      color: AppColors.rose,
    );
  }

  if (name.contains('transport') ||
      name.contains('train') ||
      name.contains('uber') ||
      name.contains('taxi')) {
    return const DashboardCategoryVisual(
      icon: Icons.directions_transit_outlined,
      color: AppColors.primary,
    );
  }

  if (name.contains('subscription') ||
      name.contains('phone') ||
      name.contains('app')) {
    return const DashboardCategoryVisual(
      icon: Icons.phone_iphone_outlined,
      color: AppColors.aqua,
    );
  }

  return DashboardCategoryVisual(
    icon: Icons.category_outlined,
    color: rankColor(percentile),
  );
}

Color rankColor(double percentile) {
  if (percentile >= 90) return AppColors.rose;
  if (percentile >= 70) return AppColors.amber;
  return AppColors.green;
}
