
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

// Widget untuk card "Jadwal Berikutnya"
class NextScheduleCard extends StatelessWidget {
  final bool isLoading;
  final String nextScheduleTime;
  final String nextScheduleObat;
  final String nextScheduleJumlah;

  const NextScheduleCard({
    super.key,
    required this.isLoading,
    required this.nextScheduleTime,
    required this.nextScheduleObat,
    required this.nextScheduleJumlah,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Lebih lega ala Airbnb
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jadwal Berikutnya",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState(context)
            else if (nextScheduleTime == '--:--')
              _buildEmptyState(context)
            else
              _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 16,
                  color: Colors.white,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "Tidak ada jadwal berikutnya.",
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bagian Kiri: Jam (rating-display style - large & bold)
        Text(
          nextScheduleTime,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(width: 24),
        // Bagian Kanan: Nama Obat dan Jumlah
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nextScheduleObat,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                nextScheduleJumlah,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
