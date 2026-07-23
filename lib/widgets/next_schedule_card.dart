
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/schedule_model.dart';

// Widget untuk card "Jadwal Berikutnya"
class NextScheduleCard extends StatelessWidget {
  final bool isLoading;
  final NextSchedule? schedule;

  const NextScheduleCard({
    super.key,
    required this.isLoading,
    this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jadwal Berikutnya",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState(context)
            else if (schedule == null)
              _buildEmptyState(context)
            else
              _buildContent(context, schedule!),
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
            color: Colors.white,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text("Tidak ada jadwal berikutnya."),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NextSchedule schedule) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bagian Kiri: Jam
        Text(
          schedule.jam,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 24),
        // Bagian Kanan: Nama Obat dan Jumlah
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.namaObat,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                schedule.jumlah,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
