import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../theme/app_colors.dart';

class ReceiptListScreen extends StatelessWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        final receipts = provider.receipts;

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
                      ReceiptActionPanel(
                        onScan: () async {
                          await _pickAndUploadReceipt(context, ImageSource.camera);
                        },
                        onUpload: () async {
                          await _pickAndUploadReceipt(context, ImageSource.gallery);
                        },
                      ),
                      const SizedBox(height: 32),
                      const ReceiptSectionHeader(
                        title: 'Receipt history',
                        subtitle: 'Stored receipts you can open later',
                      ),
                      const SizedBox(height: 16),
                      if (receipts.isEmpty)
                        const EmptyReceiptHistory()
                      else
                        ...receipts.map(
                          (receipt) => ReceiptRow(
                            receipt: receipt,
                            onTap: () {
                              showReceiptDetails(context, receipt);
                            },
                          ),
                        ),
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



  void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickAndUploadReceipt(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final provider = Provider.of<ReceiptProvider>(context, listen: false);

    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null || !context.mounted) {
      return;
    }

    try {
      await provider.uploadReceiptFromImage(image);
      if (!context.mounted) {
        return;
      }
      showMessage(context, 'Receipt uploaded and parsed with AI.');
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showMessage(context, 'Receipt upload failed: $e');
    }
  }

  void showReceiptDetails(BuildContext context, Receipt receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withOpacity(0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ReceiptDetailSheet(receipt: receipt);
      },
    );
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
          'Scan, store and revisit purchases.',
          style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.35),
        ),
      ],
    );
  }
}

class ReceiptActionPanel extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onUpload;

  const ReceiptActionPanel({
    super.key,
    required this.onScan,
    required this.onUpload,
  });

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
          const ReceiptIconBadge(
            icon: Icons.document_scanner_outlined,
            color: AppColors.aqua,
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
            'Extract items and save the receipt to history.',
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
  final Receipt receipt;
  final VoidCallback onTap;

  const ReceiptRow({super.key, required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mainCategory = receipt.mainCategory;
    final color = receiptCategoryColor(mainCategory);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ReceiptIconBadge(
                  icon: categoryIcon(mainCategory),
                  color: color,
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
                        '$mainCategory · ${receipt.itemCount} items · ${receipt.formattedDate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${receipt.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.faint,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReceiptDetailSheet extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailSheet({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final mainCategory = receipt.mainCategory;
    final color = receiptCategoryColor(mainCategory);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.86,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
              Row(
                children: [
                  ReceiptIconBadge(
                    icon: categoryIcon(mainCategory),
                    color: color,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      receipt.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${receipt.formattedDate} · ${receipt.itemCount} items',
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ReceiptSummaryCard(receipt: receipt),
              const SizedBox(height: 28),
              const ReceiptSectionHeader(
                title: 'Extracted items',
                subtitle: 'Products saved from this receipt',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: receipt.items.map((item) {
                    return ReceiptItemRow(item: item);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptSummaryCard extends StatelessWidget {
  final Receipt receipt;

  const ReceiptSummaryCard({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final mainCategory = receipt.mainCategory;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReceiptSummaryValue(
              label: 'Total',
              value: '€${receipt.totalAmount.toStringAsFixed(2)}',
              icon: Icons.payments_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ReceiptSummaryValue(
              label: 'Category',
              value: mainCategory,
              icon: categoryIcon(mainCategory),
              color: receiptCategoryColor(mainCategory),
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptSummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const ReceiptSummaryValue({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptIconBadge(icon: icon, color: color),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ReceiptItemRow extends StatelessWidget {
  final ReceiptItem item;

  const ReceiptItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final displayCategory = categoryDisplayName(item.category);
    final color = receiptCategoryColor(displayCategory);
    final quantityText = item.quantity % 1 == 0
        ? item.quantity.toStringAsFixed(0)
        : item.quantity.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          ReceiptIconBadge(icon: categoryIcon(displayCategory), color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$displayCategory · $quantityText × €${item.unitPrice.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '€${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const ReceiptIconBadge({super.key, required this.icon, required this.color});

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

class EmptyReceiptHistory extends StatelessWidget {
  const EmptyReceiptHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          ReceiptIconBadge(
            icon: Icons.receipt_long_outlined,
            color: AppColors.aqua,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'No receipts yet. Scan one to start your history.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color receiptCategoryColor(String category) {
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
