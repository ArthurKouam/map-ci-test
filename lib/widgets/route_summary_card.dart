import 'package:flutter/material.dart';

import '../models/route_stop.dart';

class RouteSummaryCard extends StatelessWidget {
  final RouteStop departure;
  final RouteStop arrival;
  final double distanceKm;

  const RouteSummaryCard({
    super.key,
    required this.departure,
    required this.arrival,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Color(0xFF1565C0)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Itinéraire transporteur',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF1565C0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RouteLineItem(
              icon: Icons.radio_button_checked,
              color: const Color(0xFF2E7D32),
              label: departure.label,
            ),
            const SizedBox(height: 8),
            _RouteLineItem(
              icon: Icons.flag,
              color: const Color(0xFFC62828),
              label: arrival.label,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLineItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RouteLineItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
