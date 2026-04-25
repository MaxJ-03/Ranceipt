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
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  Widget buildCurrentPage() {
    if (selectedIndex == 0) {
      return DashboardHome(
        onAddReceipt: () => showAddReceiptOptions(context),
        onAddGoal: () => showGoalSheet(context),
      );
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
                DashboardSheetAction(
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
                DashboardSheetAction(
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
                DashboardSheetAction(
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

  void showGoalSheet(BuildContext context) {
    final provider = Provider.of<ReceiptProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withOpacity(0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DashboardAddGoalSheet(provider: provider);
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

class DashboardHome extends StatefulWidget {
  final VoidCallback onAddReceipt;
  final VoidCallback onAddGoal;

  const DashboardHome({
    super.key,
    required this.onAddReceipt,
    required this.onAddGoal,
  });

  @override
  State<DashboardHome> createState() => DashboardHomeState();
}

class DashboardHomeState extends State<DashboardHome> {
  bool showAdvice = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        final analytics = provider.getAnalytics();
        final categories = analytics.topItemCategories;
        final topCategory = categories.isNotEmpty ? categories.first : null;
        final topSpendingCategories = categories.take(4).toList();
        final goal = analytics.activeGoal;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardTopBar(),
                    const SizedBox(height: 24),
                    DashboardMainActionCard(
                      topCategory: topCategory,
                      goal: goal,
                      showAdvice: showAdvice,
                      onAddReceipt: widget.onAddReceipt,
                      onGenerateAdvice: () {
                        setState(() {
                          showAdvice = true;
                        });
                      },
                      onResetAdvice: () {
                        setState(() {
                          showAdvice = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardMetricCard(
                            label: 'Spent',
                            value:
                                '€${analytics.totalSpending.toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet_outlined,
                            accent: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardMetricCard(
                            label: 'Receipts',
                            value: '${analytics.transactionCount}',
                            icon: Icons.receipt_long_outlined,
                            accent: AppColors.aqua,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    DashboardGoalPreview(
                      goal: goal,
                      onAddGoal: widget.onAddGoal,
                    ),
                    const SizedBox(height: 32),
                    const DashboardSectionHeader(
                      title: 'Top spending',
                      subtitle: 'Grouped from receipt items',
                    ),
                    const SizedBox(height: 16),
                    if (topSpendingCategories.isEmpty)
                      const DashboardEmptyText('No category data yet.')
                    else
                      ...topSpendingCategories.map(
                        (item) => DashboardCategoryRow(
                          category: item,
                          totalSpending: analytics.totalSpending,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key});

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

class DashboardMainActionCard extends StatelessWidget {
  final ItemCategorySpending? topCategory;
  final PersonalGoal? goal;
  final bool showAdvice;
  final VoidCallback onAddReceipt;
  final VoidCallback onGenerateAdvice;
  final VoidCallback onResetAdvice;

  const DashboardMainActionCard({
    super.key,
    required this.topCategory,
    required this.goal,
    required this.showAdvice,
    required this.onAddReceipt,
    required this.onGenerateAdvice,
    required this.onResetAdvice,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = topCategory != null;
    final hasGoal = goal != null;

    final categoryName = topCategory?.itemCategory ?? 'your spending';
    final categoryAmount = topCategory?.amount ?? 0;
    final suggestedCut = categoryAmount * 0.20;

    double progress = 0;
    if (hasGoal && goal!.amountToSave > 0) {
      progress = suggestedCut / goal!.amountToSave;
      if (progress > 1) progress = 1;
      if (progress < 0) progress = 0;
    }

    final color = hasData
        ? dashboardCategoryColor(categoryName)
        : AppColors.aqua;

    final icon = hasData
        ? categoryIcon(categoryName)
        : Icons.document_scanner_outlined;

    String adviceText;

    if (!hasData) {
      adviceText =
          'Add a receipt first. Then AI advice can estimate where saving has the biggest impact.';
    } else if (!hasGoal) {
      adviceText =
          'Your biggest category is $categoryName. Set a savings goal to turn this into a concrete plan.';
    } else {
      adviceText =
          'Saving €${suggestedCut.toStringAsFixed(0)} from $categoryName would get you ${(progress * 100).toStringAsFixed(0)}% closer to your €${goal!.amountToSave.toStringAsFixed(0)} goal.';
    }

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
          DashboardIconBadge(icon: icon, color: color),
          const SizedBox(height: 20),
          const Text(
            'Capture and improve',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add receipts to build your spending history. Generate advice when you want a saving move.',
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onAddReceipt,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Receipt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: showAdvice ? onResetAdvice : onGenerateAdvice,
                    icon: Icon(
                      showAdvice
                          ? Icons.refresh_rounded
                          : Icons.auto_awesome_outlined,
                    ),
                    label: Text(
                      showAdvice ? 'Reset' : 'Advice',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: showAdvice
                          ? AppColors.surfaceSoft
                          : AppColors.primary,
                      foregroundColor: AppColors.text,
                      side: showAdvice
                          ? const BorderSide(color: AppColors.border)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showAdvice) const SizedBox(height: 18),
          if (showAdvice)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bg.withOpacity(0.36),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DashboardIconBadge(
                        icon: hasData
                            ? categoryIcon(categoryName)
                            : Icons.auto_awesome_outlined,
                        color: hasData ? color : AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          hasData ? categoryName : 'Advice preview',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    adviceText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (hasData && hasGoal) const SizedBox(height: 16),
                  if (hasData && hasGoal)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        color: color,
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

class DashboardMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const DashboardMetricCard({
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
          DashboardIconBadge(icon: icon, color: accent),
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

class DashboardGoalPreview extends StatelessWidget {
  final PersonalGoal? goal;
  final VoidCallback onAddGoal;

  const DashboardGoalPreview({
    super.key,
    required this.goal,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          DashboardIconBadge(
            icon: hasGoal ? Icons.flag_outlined : Icons.add_task_outlined,
            color: hasGoal ? AppColors.green : AppColors.aqua,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasGoal
                      ? '€${goal!.amountToSave.toStringAsFixed(0)} goal'
                      : 'No goal set',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasGoal
                      ? '${goal!.daysLeft} days left'
                      : 'Add a saving target',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: onAddGoal,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aqua,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                hasGoal ? 'Edit' : 'Add',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCategoryRow extends StatelessWidget {
  final ItemCategorySpending category;
  final double totalSpending;

  const DashboardCategoryRow({
    super.key,
    required this.category,
    required this.totalSpending,
  });

  @override
  Widget build(BuildContext context) {
    final color = dashboardCategoryColor(category.itemCategory);
    final icon = categoryIcon(category.itemCategory);

    double share = 0;
    if (totalSpending > 0) {
      share = category.amount / totalSpending;
      if (share > 1) share = 1;
      if (share < 0) share = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          DashboardIconBadge(icon: icon, color: color),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceSoft,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '€${category.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const DashboardIconBadge({
    super.key,
    required this.icon,
    required this.color,
  });

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

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const DashboardSectionHeader({
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

class DashboardEmptyText extends StatelessWidget {
  final String text;

  const DashboardEmptyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.muted, fontSize: 16),
    );
  }
}

class DashboardSheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const DashboardSheetAction({
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

class DashboardAddGoalSheet extends StatefulWidget {
  final ReceiptProvider provider;

  const DashboardAddGoalSheet({super.key, required this.provider});

  @override
  State<DashboardAddGoalSheet> createState() => DashboardAddGoalSheetState();
}

class DashboardAddGoalSheetState extends State<DashboardAddGoalSheet> {
  final TextEditingController amountController = TextEditingController();
  int selectedDays = 30;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void saveGoal() {
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }

    widget.provider.addPersonalGoal(
      amountToSave: amount,
      targetDate: DateTime.now().add(Duration(days: selectedDays)),
    );

    Navigator.pop(context);
  }

  void setDays(int days) {
    setState(() {
      selectedDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.faint,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const Row(
              children: [
                DashboardIconBadge(
                  icon: Icons.flag_outlined,
                  color: AppColors.green,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Savings goal',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceSoft,
                prefixText: '€ ',
                prefixStyle: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '250',
                hintStyle: const TextStyle(color: AppColors.faint),
                labelText: 'Amount to save',
                labelStyle: const TextStyle(color: AppColors.muted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.aqua),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Time period',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$selectedDays days',
                  style: const TextStyle(
                    color: AppColors.aqua,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DashboardGoalDayButton(
                  label: '30',
                  selected: selectedDays == 30,
                  onTap: () {
                    setDays(30);
                  },
                ),
                const SizedBox(width: 10),
                DashboardGoalDayButton(
                  label: '60',
                  selected: selectedDays == 60,
                  onTap: () {
                    setDays(60);
                  },
                ),
                const SizedBox(width: 10),
                DashboardGoalDayButton(
                  label: '90',
                  selected: selectedDays == 90,
                  onTap: () {
                    setDays(90);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.aqua,
                inactiveTrackColor: AppColors.surfaceSoft,
                thumbColor: AppColors.aqua,
                overlayColor: AppColors.aqua.withOpacity(0.14),
                valueIndicatorColor: AppColors.surfaceSoft,
                valueIndicatorTextStyle: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: selectedDays.toDouble(),
                min: 30,
                max: 360,
                divisions: 330,
                label: '$selectedDays days',
                onChanged: (value) {
                  setState(() {
                    selectedDays = value.round();
                  });
                },
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '30 days',
                  style: TextStyle(color: AppColors.faint, fontSize: 13),
                ),
                Text(
                  '360 days',
                  style: TextStyle(color: AppColors.faint, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: saveGoal,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Save goal',
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
      ),
    );
  }
}

class DashboardGoalDayButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DashboardGoalDayButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? AppColors.aqua : AppColors.surfaceSoft,
            foregroundColor: selected ? AppColors.bg : AppColors.text,
            side: BorderSide(
              color: selected ? AppColors.aqua : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

Color dashboardCategoryColor(String category) {
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
