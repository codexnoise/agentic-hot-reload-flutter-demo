import 'package:flutter/material.dart';

/// Panel con un contador y un botón `+`.
///
/// El estado vive en el `DashboardScreen`: durante la grabación se incrementa a
/// un valor visible antes de lanzar el prompt, y debe seguir intacto después
/// del hot reload. Es la prueba en pantalla de que fue reload y no restart.
class CounterPanel extends StatelessWidget {
  const CounterPanel({
    super.key,
    required this.count,
    required this.onIncrement,
  });

  final int count;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF1F3F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Session counter',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onIncrement,
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 56),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
