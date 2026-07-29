import 'package:flutter/material.dart';

/// Datos estáticos de las tarjetas del dashboard.
///
/// Nada dinámico: existen sólo para que el `Row` de [DashboardScreen] tenga
/// suficientes hijos como para desbordar el viewport.
class DemoMetric {
  const DemoMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

const List<DemoMetric> demoMetrics = <DemoMetric>[
  DemoMetric(
    icon: Icons.trending_up,
    label: 'Revenue',
    value: '\$48.2K',
    color: Color(0xFF2E7D32),
  ),
  DemoMetric(
    icon: Icons.people_outline,
    label: 'Users',
    value: '12,480',
    color: Color(0xFF1565C0),
  ),
  DemoMetric(
    icon: Icons.shopping_cart_outlined,
    label: 'Orders',
    value: '3,912',
    color: Color(0xFFEF6C00),
  ),
  DemoMetric(
    icon: Icons.percent,
    label: 'Conversion',
    value: '4.7%',
    color: Color(0xFF6A1B9A),
  ),
];
