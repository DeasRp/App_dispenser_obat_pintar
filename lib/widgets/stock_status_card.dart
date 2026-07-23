
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Widget untuk card "Stok Obat"
class StockStatusCard extends StatelessWidget {
  final bool isLoading;
  final int stockPercentage;

  const StockStatusCard({
    super.key,
    required this.isLoading,
    required this.stockPercentage,
  });

  Color _getIndicatorColor(int percentage) {
    if (percentage < 20) return Colors.red;
    if (percentage <= 50) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = _getIndicatorColor(stockPercentage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stok Obat", style: theme.textTheme.titleMedium),
            const Spacer(),
            if (isLoading)
              _buildLoadingState(context)
            else
              _buildContent(context, indicatorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
       baseColor: Colors.grey[300]!,
       highlightColor: Colors.grey[100]!,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Container(height: 28, width: 80, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 8, width: double.infinity, color: Colors.white),
         ],
       ),
    );
  }
  
  Widget _buildContent(BuildContext context, Color indicatorColor) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "$stockPercentage%",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: indicatorColor,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: stockPercentage / 100,
          backgroundColor: indicatorColor.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

