import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_theme.dart';

/// Indikator ringkas status koneksi dispenser.
///
/// Detail koneksi tetap diterima melalui [statusText] dan ditampilkan sebagai
/// tooltip, sedangkan dashboard hanya menampilkan status Online / Offline.
class ConnectionStatusBanner extends StatelessWidget {
  final bool isLoading;
  final bool isOnline;
  final String statusText;

  const ConnectionStatusBanner({
    super.key,
    required this.isLoading,
    required this.isOnline,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 92,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    final color = isOnline ? AppColors.success : AppColors.error;
    final backgroundColor = color.withValues(alpha: 0.10);
    final label = isOnline ? 'Online' : 'Offline';

    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: statusText,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
