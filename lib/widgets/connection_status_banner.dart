
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    
    final Color bannerColor = isOnline
        ? Colors.green.shade100
        : theme.colorScheme.errorContainer;
    final Color contentColor =
        isOnline ? Colors.green.shade900 : theme.colorScheme.onErrorContainer;
    final IconData icon = isOnline ? Icons.check_circle : Icons.wifi_off;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: bannerColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: contentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
