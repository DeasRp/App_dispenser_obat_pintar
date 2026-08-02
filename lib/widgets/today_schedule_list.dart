
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/device_status.dart';
import '../core/theme/app_theme.dart';

// Widget untuk menampilkan daftar jadwal hari ini
class TodayScheduleList extends StatelessWidget {
  final bool isLoading;
  final List<JadwalItem> schedules;

  const TodayScheduleList({
    super.key,
    required this.isLoading,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jadwal Hari Ini",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState(context)
            else if (schedules.isEmpty)
              _buildEmptyState(context)
            else
              _buildList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: List.generate(3, (index) => _buildLoadingListItem()),
    );
  }

  Widget _buildLoadingListItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(width: 24, height: 24, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 200, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(height: 14, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "Tidak ada jadwal untuk hari ini.",
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(), // Agar tidak ada scroll di dalam list
      shrinkWrap: true,
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _ScheduleListItem(schedule: schedule);
      },
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.hairlineSoft,
      ),
    );
  }
}

// Widget untuk satu item dalam daftar jadwal
class _ScheduleListItem extends StatelessWidget {
  final JadwalItem schedule;

  const _ScheduleListItem({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getStatusIcon(schedule.status, theme);
    final isTaken = schedule.status == JadwalStatus.sudahDiambil;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.namaObat,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isTaken ? AppColors.muted : AppColors.ink,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Pukul ${schedule.jam}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(JadwalStatus status, ThemeData theme) {
    switch (status) {
      case JadwalStatus.sudahDiambil:
        return const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22);
      case JadwalStatus.menunggu:
        return const Icon(Icons.access_time_filled, color: AppColors.primary, size: 22);
      case JadwalStatus.terjadwal:
        return const Icon(Icons.access_time, color: AppColors.mutedSoft, size: 22);
    }
  }
}
