import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  final int riskCount;
  final int forecastCount;

  const MapLegend({
    super.key,
    required this.riskCount,
    required this.forecastCount,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _LegendItem(
                color: const Color(0xFFFF9800),
                icon: Icons.warning_rounded,
                label: '$riskCount risques',
              ),
            ),
            Expanded(
              child: _LegendItem(
                color: const Color(0xFF7B1FA2),
                icon: Icons.bolt,
                label: '$forecastCount prévisions',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
