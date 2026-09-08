import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/monitoring_model.dart';

class TodayIntakeSummaryCard extends StatelessWidget {
  final bool isLoading;
  final RingkasanHariIniModel? ringkasan;

  const TodayIntakeSummaryCard({
    super.key,
    required this.isLoading,
    required this.ringkasan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ringkasan ?? const RingkasanHariIniModel(diambil: 0, terlewat: 0);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Status Hari Ini',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (data.total == 0)
              Text(
                'Belum ada aktivitas pengambilan obat hari ini.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _StatusItem(
                      icon: Icons.check_circle_outline,
                      value: data.diambil,
                      label: 'Diambil',
                      color: AppColors.success,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: AppColors.hairline,
                  ),
                  Expanded(
                    child: _StatusItem(
                      icon: Icons.error_outline,
                      value: data.terlewat,
                      label: 'Terlewat',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 7),
        Text(
          '$value $label',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
