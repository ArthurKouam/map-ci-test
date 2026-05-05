import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/demo_map_data.dart';
import '../models/map_point.dart';
import '../models/route_stop.dart';
import '../widgets/details_sheet.dart';
import '../widgets/map_legend.dart';
import '../widgets/pin_marker.dart';
import '../widgets/route_summary_card.dart';

class MapPage extends StatelessWidget {
  final RouteStop departure;
  final RouteStop arrival;
  final List<LatLng> routeIntermediatePoints;
  final List<MapPoint> mapPoints;

  const MapPage({
    super.key,
    required this.departure,
    required this.arrival,
    this.routeIntermediatePoints = demoRouteIntermediatePoints,
    this.mapPoints = demoMapPoints,
  });

  List<LatLng> get _routePoints => [
    departure.position,
    ...routeIntermediatePoints,
    arrival.position,
  ];

  List<LatLng> get _visibleCoordinates => [
    ..._routePoints,
    ...mapPoints.map((mapPoint) => mapPoint.position),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: departure.position,
              initialZoom: 13,
              initialCameraFit: CameraFit.coordinates(
                coordinates: _visibleCoordinates,
                padding: const EdgeInsets.fromLTRB(48, 140, 48, 190),
                maxZoom: 15,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jsdprojet.commando',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 7,
                    color: const Color(0xFF1565C0),
                    borderStrokeWidth: 3,
                    borderColor: Colors.white,
                  ),
                ],
              ),
              MarkerLayer(markers: _buildMarkers(context)),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RouteSummaryCard(
                departure: departure,
                arrival: arrival,
                distanceKm: _routeDistanceKm,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: MapLegend(
              riskCount: mapPoints
                  .where((mapPoint) => mapPoint.type == MapPointType.risk)
                  .length,
              forecastCount: mapPoints
                  .where((mapPoint) => mapPoint.type == MapPointType.forecast)
                  .length,
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    return [
      _buildStopMarker(
        context: context,
        stop: departure,
        color: const Color(0xFF2E7D32),
        icon: Icons.trip_origin,
      ),
      _buildStopMarker(
        context: context,
        stop: arrival,
        color: const Color(0xFFC62828),
        icon: Icons.flag,
      ),
      ...mapPoints.map(
        (mapPoint) => _buildMapPointMarker(
          context: context,
          mapPoint: mapPoint,
        ),
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
      width: 54,
      height: 54,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showStopDetails(context, stop),
        child: PinMarker(color: color, icon: icon),
      ),
    );
  }

  Marker _buildMapPointMarker({
    required BuildContext context,
    required MapPoint mapPoint,
  }) {
    final color = mapPoint.type == MapPointType.risk
        ? const Color(0xFFFF9800)
        : const Color(0xFF7B1FA2);
    final icon = mapPoint.type == MapPointType.risk
        ? Icons.warning_rounded
        : Icons.bolt;

    return Marker(
      point: mapPoint.position,
      width: 48,
      height: 48,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showMapPointDetails(context, mapPoint),
        child: PinMarker(color: color, icon: icon),
      ),
    );
  }

  void _showStopDetails(BuildContext context, RouteStop stop) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => DetailsSheet(
        icon: Icons.location_on,
        iconColor: const Color(0xFF1565C0),
        title: stop.label,
        description:
            'Position choisie depuis l’écran précédent pour calculer et afficher l’itinéraire du transporteur.',
      ),
    );
  }

  void _showMapPointDetails(BuildContext context, MapPoint mapPoint) {
    final isRisk = mapPoint.type == MapPointType.risk;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => DetailsSheet(
        icon: isRisk ? Icons.warning_rounded : Icons.bolt,
        iconColor: isRisk ? const Color(0xFFFF9800) : const Color(0xFF7B1FA2),
        title: mapPoint.title,
        description: mapPoint.description,
      ),
    );
  }
}
