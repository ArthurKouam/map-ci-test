import 'package:latlong2/latlong.dart';

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
