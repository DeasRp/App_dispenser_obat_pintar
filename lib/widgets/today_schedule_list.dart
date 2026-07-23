
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/device_status.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Jadwal Hari Ini", style: theme.textTheme.titleMedium),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text("Tidak ada jadwal untuk hari ini."),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    // Menggunakan ListView.separated untuk menambahkan Divider secara otomatis
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(), // Agar tidak ada scroll di dalam list
      shrinkWrap: true,
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _ScheduleListItem(schedule: schedule);
      },
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).dividerColor.withAlpha(128),
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
    final textColor = _getStatusColor(schedule.status, theme);
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
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  "Pukul ${schedule.jam}",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: textColor?.withAlpha(204)),
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
        return Icon(Icons.check_circle, color: Colors.green);
      case JadwalStatus.menunggu:
        return Icon(Icons.access_time_filled, color: theme.colorScheme.primary);
      case JadwalStatus.terjadwal:
        return Icon(Icons.access_time, color: theme.disabledColor);
    }
  }

  Color? _getStatusColor(JadwalStatus status, ThemeData theme) {
    switch (status) {
      case JadwalStatus.sudahDiambil:
      case JadwalStatus.terjadwal:
        return theme.textTheme.bodyMedium?.color?.withAlpha(153);
      case JadwalStatus.menunggu:
        return theme.textTheme.bodyLarge?.color;
    }
  }
}
