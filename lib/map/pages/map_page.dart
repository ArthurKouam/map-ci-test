import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../data/demo_map_data.dart';
import '../models/map_point.dart';
import '../models/route_stop.dart';
import '../widgets/details_sheet.dart';
import '../widgets/pin_marker.dart';
import '../widgets/route_summary_card.dart';

class MapPage extends StatelessWidget {
  final RouteStop departure;
  final RouteStop arrival;
  final List<LatLng> routeIntermediatePoints;
  final List<MapPoint> mapPoints;
  final List<LatLng>? customPolyline;
  final List<dynamic>? riskZones;
  final LatLng? truckPosition;
  final bool showSummary;
  final bool interactive;

  const MapPage({
    super.key,
    required this.departure,
    required this.arrival,
    this.routeIntermediatePoints = demoRouteIntermediatePoints,
    this.mapPoints = demoMapPoints,
    this.customPolyline,
    this.riskZones,
    this.truckPosition,
    this.showSummary = true,
    this.interactive = true,
  });

  List<LatLng> get _routePoints => customPolyline ?? [
    departure.position,
    ...routeIntermediatePoints,
    arrival.position,
  ];

  List<LatLng> get _visibleCoordinates => [
    ..._routePoints,
    ...mapPoints.map((mapPoint) => mapPoint.position),
    if (riskZones != null)
      ...riskZones!.map((z) => LatLng(z['lat'], z['lon'])),
  ];

  List<LatLng> get _safeCoordinates {
    final uniqueCoords = <LatLng>{};
    for (var coord in _visibleCoordinates) {
      uniqueCoords.add(coord);
    }
    if (uniqueCoords.length > 1) {
      return uniqueCoords.toList();
    }
    return [
      departure.position,
      LatLng(departure.position.latitude + 0.01, departure.position.longitude + 0.01)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: departure.position,
            initialZoom: 13,
            initialCameraFit: CameraFit.coordinates(
              coordinates: _safeCoordinates,
              padding: const EdgeInsets.fromLTRB(48, 140, 48, 190),
              maxZoom: 18,
            ),
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.tril.app',
              maxZoom: 19,
              maxNativeZoom: 19,
            ),
            // Optimized Route Polyline
            PolylineLayer(
              polylines: [
                // Glow effect for the route
                Polyline(
                  points: _routePoints,
                  strokeWidth: 12,
                  color: AppColors.success.withOpacity(0.2),
                  strokeCap: StrokeCap.round,
                ),
                Polyline(
                  points: _routePoints,
                  strokeWidth: 4,
                  color: AppColors.success,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
            // Risk Zones (Circles from VRP Data)
            if (riskZones != null)
              CircleLayer(
                circles: riskZones!.map((zone) {
                  final color = zone['level'] == 'high' ? AppColors.danger : AppColors.warning;
                  return CircleMarker(
                    point: LatLng(zone['lat'], zone['lon']),
                    radius: (zone['radius'] as num).toDouble() / 100, // Scale for visibility
                    useRadiusInMeter: true,
                    color: color.withOpacity(0.15),
                    borderColor: color.withOpacity(0.4),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),
            MarkerLayer(markers: _buildMarkers(context)),
          ],
        ),
        if (showSummary)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RouteSummaryCard(
                  departure: departure,
                  arrival: arrival,
                  distanceKm: _routeDistanceKm,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    return [
      _buildStopMarker(
        context: context,
        stop: departure,
        color: AppColors.success,
        icon: Icons.trip_origin_rounded,
      ),
      _buildStopMarker(
        context: context,
        stop: arrival,
        color: AppColors.danger,
        icon: Icons.location_on_rounded,
      ),
      if (truckPosition != null)
        Marker(
          point: truckPosition!,
          width: 50,
          height: 50,
          child: const PinMarker(
            color: AppColors.accent,
            icon: Icons.local_shipping_rounded,
            isLarge: true,
          ),
        ),
      ...mapPoints.map(
        (mapPoint) =>
            _buildMapPointMarker(context: context, mapPoint: mapPoint),
      ),
    ];
  }

  double get _routeDistanceKm {
    const distance = Distance();
    double totalDistance = 0;

    for (var index = 0; index < _routePoints.length - 1; index++) {
      totalDistance += distance.as(
        LengthUnit.Kilometer,
        _routePoints[index],
        _routePoints[index + 1],
      );
    }

    return totalDistance;
  }

  Marker _buildStopMarker({
    required BuildContext context,
    required RouteStop stop,
    required Color color,
    required IconData icon,
  }) {
    return Marker(
      point: stop.position,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _showStopDetails(context, stop),
        child: PinMarker(color: color, icon: icon, isLarge: true),
      ),
    );
  }

  Marker _buildMapPointMarker({
    required BuildContext context,
    required MapPoint mapPoint,
  }) {
    final color = mapPoint.id == 'pickup' 
        ? AppColors.accent 
        : mapPoint.id == 'dropoff' 
            ? AppColors.danger 
            : mapPoint.type == MapPointType.risk
                ? AppColors.warning
                : AppColors.accent;

    final icon = mapPoint.id == 'pickup'
        ? Icons.add_business_rounded
        : mapPoint.id == 'dropoff'
            ? Icons.archive_rounded
            : mapPoint.type == MapPointType.risk
                ? Icons.warning_rounded
                : Icons.bolt_rounded;

    return Marker(
      point: mapPoint.position,
      width: 50,
      height: 50,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _showMapPointDetails(context, mapPoint),
        child: PinMarker(color: color, icon: icon),
      ),
    );
  }

  void _showStopDetails(BuildContext context, RouteStop stop) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailsSheet(
        icon: Icons.location_on_rounded,
        iconColor: AppColors.accent,
        title: stop.label,
        description:
            'Point clé de votre trajet. Assurez-vous de vérifier les documents de chargement à cet endroit.',
      ),
    );
  }

  void _showMapPointDetails(BuildContext context, MapPoint mapPoint) {
    final isRisk = mapPoint.type == MapPointType.risk;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailsSheet(
        icon: isRisk ? Icons.warning_rounded : Icons.bolt_rounded,
        iconColor: isRisk ? AppColors.warning : AppColors.accent,
        title: mapPoint.title,
        description: mapPoint.description,
      ),
    );
  }
}
