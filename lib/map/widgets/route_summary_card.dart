import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Itinéraire optimisé',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.dmSans(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RouteLineItem(
            icon: Icons.trip_origin_rounded,
            color: AppColors.success,
            label: departure.label,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.5, top: 4, bottom: 4),
            child: Container(
              width: 1.5,
              height: 12,
              color: AppColors.divider,
            ),
          ),
          _RouteLineItem(
            icon: Icons.location_on_rounded,
            color: AppColors.danger,
            label: arrival.label,
          ),
        ],
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
