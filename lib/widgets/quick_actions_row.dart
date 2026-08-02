import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onDispensePressed;
  final VoidCallback onRefreshPressed;
  final bool isRefreshing;

  const QuickActionsRow({
    super.key,
    required this.onDispensePressed,
    required this.onRefreshPressed,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            icon: const Icon(Icons.medication_liquid),
            label: const Text('Keluarkan Obat Manual'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onDispensePressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isRefreshing ? null : onRefreshPressed,
            child: isRefreshing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}
