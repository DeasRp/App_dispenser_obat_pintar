import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

// Widget ringkas untuk status stok obat.
// Jangan gunakan Spacer/Expanded di sini karena card dapat berada di dalam
// SingleChildScrollView yang memberi constraint tinggi tidak terbatas.
class StockStatusCard extends StatelessWidget {
  final bool isLoading;
  final int stockPercentage;

  const StockStatusCard({
    super.key,
    required this.isLoading,
    required this.stockPercentage,
  });

  Color _getIndicatorColor(int percentage) {
    if (percentage < 20) return AppColors.error;
    if (percentage <= 50) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safePercentage = stockPercentage.clamp(0, 100);
    final indicatorColor = _getIndicatorColor(safePercentage);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stok Obat',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              _buildLoadingState()
            else
              _buildContent(context, safePercentage, indicatorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 28, width: 80, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 8, width: double.infinity, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    int percentage,
    Color indicatorColor,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$percentage%',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: indicatorColor,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: indicatorColor.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          minHeight: 6,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ],
    );
  }
}
