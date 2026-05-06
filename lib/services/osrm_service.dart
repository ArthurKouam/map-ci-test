import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          return coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
        }
      }
    } catch (e) {
      print('OSRM error: $e');
    }
    // Fallback to straight line
    return [start, end];
  }
}
