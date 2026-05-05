import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MapPage(
        departure: RouteStop(
          label: 'Point de départ',
          position: LatLng(10.5956, 14.3247),
        ),
        arrival: RouteStop(
          label: 'Point d’arrivée',
          position: LatLng(10.6308, 14.3489),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RouteStop {
  final String label;
  final LatLng position;

  const RouteStop({required this.label, required this.position});
}

enum MapPointType { risk, forecast }

class MapPoint {
  final String title;
  final String description;
  final LatLng position;
  final MapPointType type;

  const MapPoint({
    required this.title,
    required this.description,
    required this.position,
    required this.type,
  });
}

class MapPage extends StatelessWidget {
  final RouteStop departure;
  final RouteStop arrival;

  const MapPage({super.key, required this.departure, required this.arrival});

  List<LatLng> get _routePoints => [
    departure.position,
    LatLng(10.6048, 14.3295),
    LatLng(10.6127, 14.3354),
    LatLng(10.6219, 14.3421),
    arrival.position,
  ];

  List<MapPoint> get _mapPoints => const [
    MapPoint(
      title: 'Chaussée dégradée',
      description:
          'Zone à risque signalée sur cet axe. Réduire la vitesse et éviter les arrêts prolongés.',
      position: LatLng(10.6062, 14.3311),
      type: MapPointType.risk,
    ),
    MapPoint(
      title: 'Contrôle fréquent',
      description:
          'Présence régulière de contrôles. Préparer les documents de transport avant d’arriver.',
      position: LatLng(10.6184, 14.3398),
      type: MapPointType.risk,
    ),
    MapPoint(
      title: 'Commande bientôt disponible',
      description:
          'Prévision de commande dans cette zone. Restez disponible à proximité.',
      position: LatLng(10.6121, 14.3367),
      type: MapPointType.forecast,
    ),
    MapPoint(
      title: 'Forte demande prévue',
      description:
          'Une commande devrait bientôt être passée ici. Cette zone peut devenir prioritaire.',
      position: LatLng(10.6262, 14.3462),
      type: MapPointType.forecast,
    ),
  ];

  List<LatLng> get _visibleCoordinates => [
    ..._routePoints,
    ..._mapPoints.map((mapPoint) => mapPoint.position),
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
              MarkerLayer(
                markers: [
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
                  ..._mapPoints.map(
                    (mapPoint) => _buildMapPointMarker(
                      context: context,
                      mapPoint: mapPoint,
                    ),
                  ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _RouteSummaryCard(
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
            child: _MapLegend(
              riskCount: _mapPoints
                  .where((mapPoint) => mapPoint.type == MapPointType.risk)
                  .length,
              forecastCount: _mapPoints
                  .where((mapPoint) => mapPoint.type == MapPointType.forecast)
                  .length,
            ),
          ),
        ],
      ),
    );
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
        child: _PinMarker(color: color, icon: icon),
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
        child: _PinMarker(color: color, icon: icon),
      ),
    );
  }

  void _showStopDetails(BuildContext context, RouteStop stop) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _DetailsSheet(
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
      builder: (context) => _DetailsSheet(
        icon: isRisk ? Icons.warning_rounded : Icons.bolt,
        iconColor: isRisk ? const Color(0xFFFF9800) : const Color(0xFF7B1FA2),
        title: mapPoint.title,
        description: mapPoint.description,
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  final RouteStop departure;
  final RouteStop arrival;
  final double distanceKm;

  const _RouteSummaryCard({
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

class _MapLegend extends StatelessWidget {
  final int riskCount;
  final int forecastCount;

  const _MapLegend({required this.riskCount, required this.forecastCount});

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

class _PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _PinMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 24)),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _DetailsSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
