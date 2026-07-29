import 'package:flutter/material.dart';

import '../data/demo_metrics.dart';
import '../widgets/counter_panel.dart';
import '../widgets/metric_card.dart';

/// La pantalla con el bug.
///
/// Es un `StatefulWidget` a propósito: el contador demuestra que el hot reload
/// preserva el estado.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _count = 0;

  void _increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CounterPanel(count: _count, onIncrement: _increment),
            const SizedBox(height: 24),
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // El Row culpable: cuatro tarjetas de 180pt sin Expanded, sin
            // Flexible y sin scroll. En un iPhone de ~390pt esto desborda.
            Row(
              children: <Widget>[
                for (final DemoMetric metric in demoMetrics)
                  MetricCard(
                    icon: metric.icon,
                    label: metric.label,
                    value: metric.value,
                    color: metric.color,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
