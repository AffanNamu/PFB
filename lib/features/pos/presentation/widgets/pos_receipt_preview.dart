import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/models/receipt_model.dart';
import 'package:intl/intl.dart';

class PosReceiptPreview extends StatelessWidget {
  final ReceiptModel receipt;

  const PosReceiptPreview({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────
          _buildHeader(colors),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Receipt Meta ──────────────────────────────────
                _buildMeta(colors),
                const SizedBox(height: 16),

                // ── Divider ───────────────────────────────────────
                _dashedDivider(colors),
                const SizedBox(height: 12),

                // ── Column Headers ────────────────────────────────
                _buildTableHeader(colors),
                const SizedBox(height: 8),

                // ── Items ─────────────────────────────────────────
                ...receipt.items.map((item) => _buildItemRow(item, colors)),
                const SizedBox(height: 12),

                // ── Divider ───────────────────────────────────────
                _dashedDivider(colors),
                const SizedBox(height: 12),

                // ── Totals ────────────────────────────────────────
                _buildTotals(colors),
                const SizedBox(height: 16),

                // ── Divider ───────────────────────────────────────
                _dashedDivider(colors),
                const SizedBox(height: 12),

                // ── Payment ───────────────────────────────────────
                _buildPaymentSection(colors),
                const SizedBox(height: 16),

                // ── Footer ────────────────────────────────────────
                _buildFooter(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppGradients.goldVertical,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.black, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'SAKASH COLLECTION',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            receipt.branchName,
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'SALES RECEIPT',
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(AppThemeColors colors) {
    final dateFormatter = DateFormat('dd MMM yyyy  HH:mm');
    return Column(
      children: [
        _metaRow('Receipt ID', receipt.receiptId, colors, isBold: true),
        const SizedBox(height: 4),
        _metaRow(
          'Date',
          dateFormatter.format(receipt.issuedAt),
          colors,
        ),
        _metaRow('Cashier', receipt.cashierName, colors),
        if (receipt.customerName.isNotEmpty)
          _metaRow('Customer', receipt.customerName, colors),
        if (receipt.customerPhone.isNotEmpty)
          _metaRow('Phone', receipt.customerPhone, colors),
      ],
    );
  }

  Widget _metaRow(String label, String value, AppThemeColors colors,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: isBold ? colors.brandPrimary : colors.textPrimary,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppThemeColors colors) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text('ITEM',
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
        Expanded(
          child: Text('QTY',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
        Expanded(
          flex: 2,
          child: Text('UNIT',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
        Expanded(
          flex: 2,
          child: Text('TOTAL',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, AppThemeColors colors) {
    final name = (item['productName'] ?? '').toString();
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final yards = (item['yardQuantity'] as num?)?.toDouble() ?? 1.0;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
              ),
              Expanded(
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colors.textPrimary, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '₦${unitPrice.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: colors.textPrimary, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '₦${lineTotal.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${yards.toStringAsFixed(1)} yards',
            style: TextStyle(color: colors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(AppThemeColors colors) {
    return Column(
      children: [
        _totalRow('Subtotal', receipt.subtotal, colors),
        if (receipt.discountValue > 0) ...[
          const SizedBox(height: 4),
          _totalRow(
            'Discount${receipt.discountType == PosDiscountType.percentage ? ' (${receipt.discountValue.toStringAsFixed(0)}%)' : ''}',
            -receipt.discountValue,
            colors,
            isDiscount: true,
          ),
          if (receipt.discountReason.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Reason: ${receipt.discountReason}',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 10),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            Text(
              '₦${receipt.finalTotal.toStringAsFixed(2)}',
              style: TextStyle(
                color: colors.brandPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _totalRow(String label, double amount, AppThemeColors colors,
      {bool isDiscount = false}) {
    final displayAmount = isDiscount ? amount.abs() : amount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(
          isDiscount
              ? '-₦${displayAmount.toStringAsFixed(2)}'
              : '₦${displayAmount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isDiscount ? colors.success : colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYMENT',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        _metaRow('Method', receipt.paymentMethod.label, colors),
        if (receipt.paymentMethod == PosPaymentMethod.mixed &&
            receipt.mixedPayment != null) ...[
          if (receipt.mixedPayment!.cashAmount > 0)
            _metaRow('  Cash',
                '₦${receipt.mixedPayment!.cashAmount.toStringAsFixed(2)}',
                colors),
          if (receipt.mixedPayment!.transferAmount > 0)
            _metaRow(
                '  Transfer',
                '₦${receipt.mixedPayment!.transferAmount.toStringAsFixed(2)}',
                colors),
          if (receipt.mixedPayment!.posAmount > 0)
            _metaRow('  POS Terminal',
                '₦${receipt.mixedPayment!.posAmount.toStringAsFixed(2)}',
                colors),
        ],
        if (receipt.paymentMethod == PosPaymentMethod.cash &&
            receipt.amountTendered > 0) ...[
          _metaRow('Tendered',
              '₦${receipt.amountTendered.toStringAsFixed(2)}', colors),
          _metaRow(
              'Change', '₦${receipt.changeGiven.toStringAsFixed(2)}', colors),
        ],
      ],
    );
  }

  Widget _buildFooter(AppThemeColors colors) {
    return Column(
      children: [
        GoldDivider(opacity: 0.4),
        const SizedBox(height: 12),
        Text(
          'Thank you for shopping at Sakash Collection!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quality Assured • Thank You',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.brandPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _dashedDivider(AppThemeColors colors) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            dashCount,
            (_) => Padding(
              padding: EdgeInsets.only(right: dashSpace),
              child: Container(
                width: dashWidth,
                height: 1,
                color: colors.borderSoft,
              ),
            ),
          ),
        );
      },
    );
  }
}