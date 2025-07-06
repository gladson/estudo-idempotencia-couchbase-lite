import 'package:flutter/material.dart';

/// A reusable widget that displays previous and next buttons for pagination.
///
/// It takes boolean flags to enable/disable the buttons and callbacks for press events.
class PaginationControls extends StatelessWidget {
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const PaginationControls({
    super.key,
    required this.hasPreviousPage,
    required this.hasNextPage,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: hasPreviousPage ? onPreviousPage : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Anterior'),
        ),
        ElevatedButton.icon(
          onPressed: hasNextPage ? onNextPage : null,
          label: const Text('Próxima'),
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}