
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/schedule_model.dart';

// Widget untuk card "Status Gelas"
class GlassStatusCard extends StatelessWidget {
  final bool isLoading;
  final GlassStatus status;

  const GlassStatusCard({
    super.key,
    required this.isLoading,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status Gelas", style: theme.textTheme.titleMedium),
            const Spacer(),
            if (isLoading)
              _buildLoadingState(context)
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Container(height: 24, width: 80, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isFilled = status == GlassStatus.terisi;
    final icon = isFilled ? Icons.local_cafe : Icons.local_cafe_outlined;
    final label = isFilled ? "Terisi" : "Kosong";
    final color =
        isFilled ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 36,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )
        ],
      ),
    );
  }
}
