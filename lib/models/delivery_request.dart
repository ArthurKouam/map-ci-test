import 'package:latlong2/latlong.dart';

class DeliveryRequest {
  final String id;
  final LatLng pickup;
  final LatLng delivery;
  final double volume;
  final String customerName;
  final String customerPhone;
  final String description;

  const DeliveryRequest({
    required this.id,
    required this.pickup,
    required this.delivery,
    required this.volume,
    required this.customerName,
    required this.customerPhone,
    required this.description,
  });
}
