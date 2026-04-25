import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ReceiptListScreen extends StatelessWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final receipts = [
      const ReceiptData(
        merchant: 'Starbucks',
        category: 'Coffee',
        amount: 14.30,
        date: 'Today',
        itemCount: 3,
        icon: Icons.local_cafe_outlined,
      ),
      const ReceiptData(
        merchant: 'Albert Heijn',
        category: 'Groceries',
        amount: 42.80,
        date: 'Yesterday',
        itemCount: 8,
        icon: Icons.shopping_basket_outlined,
      ),
      const ReceiptData(
        merchant: 'Uber Eats',
        category: 'Restaurants',
        amount: 27.50,
        date: '2 days ago',
        itemCount: 4,
        icon: Icons.restaurant_outlined,
      ),
      const ReceiptData(
        merchant: 'NS',
        category: 'Transport',
        amount: 18.20,
        date: '3 days ago',
        itemCount: 1,
        icon: Icons.train_outlined,
      ),
    ];

    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ReceiptHeader(),
                  const SizedBox(height: 24),
                  ActionPanel(
                    onScan: () =>
                        showMessage(context, 'Camera scanning coming soon.'),
                    onUpload: () => showMessage(context, 'Upload coming soon.'),
                  ),
                  const SizedBox(height: 32),
                  const ReceiptSectionHeader(
                    title: 'Recent',
                    subtitle: 'Latest scanned receipts',
                  ),
                  const SizedBox(height: 16),
                  ...receipts.map((receipt) => ReceiptRow(receipt: receipt)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class ReceiptHeader extends StatelessWidget {
  const ReceiptHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipts',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Scan purchases into insights.',
          style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.35),
        ),
      ],
    );
  }
}

class ActionPanel extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onUpload;

  const ActionPanel({super.key, required this.onScan, required this.onUpload});

  @override
  Widget build(BuildContext context) {
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
          const Icon(
            Icons.document_scanner_outlined,
            color: AppColors.aqua,
            size: 36,
          ),
          const SizedBox(height: 20),
          const Text(
            'Add receipt',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Extract items and update your ranking.',
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text(
                'Scan receipt',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.image_outlined),
              label: const Text(
                'Upload photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.32),
                  width: 1.2,
                ),
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

class ReceiptRow extends StatelessWidget {
  final ReceiptData receipt;

  const ReceiptRow({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(receipt.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(receipt.icon, color: color, size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${receipt.category} · ${receipt.itemCount} items · ${receipt.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '€${receipt.amount.toStringAsFixed(2)}',
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

class ReceiptSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ReceiptSectionHeader({
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

class ReceiptData {
  final String merchant;
  final String category;
  final double amount;
  final String date;
  final int itemCount;
  final IconData icon;

  const ReceiptData({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    required this.itemCount,
    required this.icon,
  });
}

Color categoryColor(String category) {
  if (category.toLowerCase() == 'coffee') {
    return AppColors.amber;
  }

  if (category.toLowerCase() == 'groceries') {
    return AppColors.green;
  }

  if (category.toLowerCase() == 'restaurants') {
    return AppColors.rose;
  }

  if (category.toLowerCase() == 'transport') {
    return AppColors.primary;
  }

  return AppColors.aqua;
}
