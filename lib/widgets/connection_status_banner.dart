
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

// Widget untuk menampilkan status koneksi device
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
    final theme = Theme.of(context);

    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      );
    }
    
    final Color bannerColor = isOnline
        ? const Color(0xFFEAF7EE) // Sangat lembut hijau
        : const Color(0xFFFFF0F0); // Sangat lembut merah
    final Color contentColor =
        isOnline ? AppColors.success : AppColors.error;
    final IconData icon = isOnline ? Icons.check_circle_outline : Icons.error_outline;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: bannerColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: contentColor.withValues(alpha: 0.12), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: contentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
