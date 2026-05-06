import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'osrm_service.dart';

/// Quartiers de Maroua utilisés pour sélection dans le formulaire
const List<Map<String, dynamic>> maroaQuartiers = [
  {"id": 0, "name": "Domayo", "lat": 10.59918, "lon": 14.2970},
  {"id": 1, "name": "Marché Central", "lat": 10.5920, "lon": 14.3050},
  {"id": 2, "name": "Fada", "lat": 10.5846, "lon": 14.3049},
  {"id": 3, "name": "Pitoaré", "lat": 10.6050, "lon": 14.3100},
  {"id": 4, "name": "Kakataré", "lat": 10.5950, "lon": 14.3150},
  {"id": 5, "name": "Dougoy", "lat": 10.6100, "lon": 14.2900},
  {"id": 6, "name": "Zokok", "lat": 10.5880, "lon": 14.2800},
  {"id": 7, "name": "Kongola", "lat": 10.6200, "lon": 14.3200},
  {"id": 8, "name": "Ngassa", "lat": 10.5750, "lon": 14.2950},
  {"id": 9, "name": "Lopéré", "lat": 10.6050, "lon": 14.3350},
];

/// Scénario réaliste : trajet Domayo → Kongola
/// Le transporteur passe par 4 quartiers pour livrer 4 colis
/// Ordre géographique cohérent : Domayo → Zokok → Fada → Marché Central → Kakataré → Pitoaré → Kongola
const List<Map<String, dynamic>> tripCheckpoints = [
  {
    "id": "cp_0",
    "name": "Domayo",
    "lat": 10.59918,
    "lon": 14.2970,
    "type": "depart",
    "order": 0,
  },
  {
    "id": "cp_1",
    "name": "Zokok",
    "lat": 10.5880,
    "lon": 14.2800,
    "type": "pickup",
    "order": 1,
    "parcel": {
      "id": "COLIS-001",
      "description": "Sac de riz (50 kg)",
      "weight": "50 kg",
      "client_name": "Moussa Bello",
      "client_phone": "+237 677 112 233",
      "price": 3500,
    },
  },
  {
    "id": "cp_2",
    "name": "Fada",
    "lat": 10.5846,
    "lon": 14.3049,
    "type": "dropoff",
    "order": 2,
    "parcel": {
      "id": "COLIS-001",
      "description": "Sac de riz (50 kg)",
      "weight": "50 kg",
      "client_name": "Moussa Bello",
      "client_phone": "+237 677 112 233",
      "price": 3500,
    },
  },
  {
    "id": "cp_3",
    "name": "Marché Central",
    "lat": 10.5920,
    "lon": 14.3050,
    "type": "pickup",
    "order": 3,
    "parcel": {
      "id": "COLIS-002",
      "description": "Cartons d'huile alimentaire",
      "weight": "30 kg",
      "client_name": "Aïssatou Maï",
      "client_phone": "+237 699 445 566",
      "price": 2000,
    },
  },
  {
    "id": "cp_4",
    "name": "Kakataré",
    "lat": 10.5950,
    "lon": 14.3150,
    "type": "dropoff",
    "order": 4,
    "parcel": {
      "id": "COLIS-002",
      "description": "Cartons d'huile alimentaire",
      "weight": "30 kg",
      "client_name": "Aïssatou Maï",
      "client_phone": "+237 699 445 566",
      "price": 2000,
    },
  },
  {
    "id": "cp_5",
    "name": "Pitoaré",
    "lat": 10.6050,
    "lon": 14.3100,
    "type": "pickup",
    "order": 5,
    "parcel": {
      "id": "COLIS-003",
      "description": "Matériaux de construction (sacs de ciment)",
      "weight": "100 kg",
      "client_name": "Ibrahim Djidda",
      "client_phone": "+237 655 778 899",
      "price": 5000,
    },
  },
  {
    "id": "cp_6",
    "name": "Dougoy",
    "lat": 10.6100,
    "lon": 14.2900,
    "type": "dropoff",
    "order": 6,
    "parcel": {
      "id": "COLIS-003",
      "description": "Matériaux de construction (sacs de ciment)",
      "weight": "100 kg",
      "client_name": "Ibrahim Djidda",
      "client_phone": "+237 655 778 899",
      "price": 5000,
    },
  },
  {
    "id": "cp_7",
    "name": "Lopéré",
    "lat": 10.6050,
    "lon": 14.3350,
    "type": "pickup_dropoff",
    "order": 7,
    "parcel": {
      "id": "COLIS-004",
      "description": "Électroménager (ventilateurs)",
      "weight": "15 kg",
      "client_name": "Fatimé Oumar",
      "client_phone": "+237 622 334 455",
      "price": 1500,
    },
  },
  {
    "id": "cp_8",
    "name": "Kongola",
    "lat": 10.6200,
    "lon": 14.3200,
    "type": "arrivee",
    "order": 8,
  },
];

class LocalDataService {
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  List<dynamic>? _users;
  final OsrmService _osrmService = OsrmService();

  Future<void> init() async {
    _users ??= [
      {
        "id": 99,
        "name": "Alim",
        "phone": "656496419",
        "role": "transporter",
        "is_verified": true,
        "location": 0
      },
      {
        "id": 0,
        "name": "Moussa Bello",
        "phone": "677112233",
        "role": "client",
        "is_verified": true,
        "location": 1
      },
      {
        "id": 1,
        "name": "Aïssatou Maï",
        "phone": "699445566",
        "role": "client",
        "is_verified": true,
        "location": 3
      },
      {
        "id": 2,
        "name": "Ibrahim Djidda",
        "phone": "655778899",
        "role": "transporter",
        "is_verified": false,
        "location": 5
      },
      {
        "id": 3,
        "name": "Fatimé Oumar",
        "phone": "622334455",
        "role": "client",
        "is_verified": true,
        "location": 7
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    await init();
    return List<Map<String, dynamic>>.from(_users ?? []);
  }

  Future<bool> registerUser(Map<String, dynamic> user) async {
    await init();
    _users?.add(user);
    return true;
  }

  /// Retourne les checkpoints du trajet principal
  List<Map<String, dynamic>> getCheckpoints() {
    return List<Map<String, dynamic>>.from(tripCheckpoints);
  }

  /// Route principale du trajet (tous les checkpoints dans l'ordre)
  List<LatLng> getTripRouteCoords() {
    return tripCheckpoints
        .map((cp) => LatLng((cp['lat'] as num).toDouble(), (cp['lon'] as num).toDouble()))
        .toList();
  }

  /// Zones de risque dérivées de zones périphériques simulées
  List<Map<String, dynamic>> getRiskZones() {
    return [
      {"lat": 10.575, "lon": 14.270, "radius": 1200, "level": "high"},
      {"lat": 10.630, "lon": 14.340, "radius": 900, "level": "medium"},
      {"lat": 10.585, "lon": 14.330, "radius": 700, "level": "medium"},
    ];
  }

  /// Zones prédictives de demande (heatmap)
  List<Map<String, dynamic>> getDemandHeatZones() {
    return [
      {"lat": 10.5920, "lon": 14.3050, "intensity": 1.0, "label": "Marché Central"},
      {"lat": 10.5950, "lon": 14.3150, "intensity": 0.85, "label": "Kakataré"},
      {"lat": 10.5846, "lon": 14.3049, "intensity": 0.7, "label": "Fada"},
      {"lat": 10.6050, "lon": 14.3100, "intensity": 0.65, "label": "Pitoaré"},
      {"lat": 10.5880, "lon": 14.2800, "intensity": 0.5, "label": "Zokok"},
      {"lat": 10.6100, "lon": 14.2900, "intensity": 0.4, "label": "Dougoy"},
    ];
  }

  Future<List<LatLng>> getRealRoute(LatLng start, LatLng end) async {
    return await _osrmService.getRoute(start, end);
  }

  /// Route OSRM suivant tous les checkpoints dans l'ordre
  Future<List<LatLng>> getFullTripRoute() async {
    final coords = getTripRouteCoords();
    if (coords.length < 2) return coords;

    List<LatLng> fullRoute = [];
    for (int i = 0; i < coords.length - 1; i++) {
      final segment = await _osrmService.getRoute(coords[i], coords[i + 1]);
      if (fullRoute.isNotEmpty && segment.isNotEmpty) {
        fullRoute.addAll(segment.skip(1));
      } else {
        fullRoute.addAll(segment);
      }
    }
    return fullRoute;
  }

  /// Commandes simulées qui peuvent matcher avec le trajet
  Future<List<Map<String, dynamic>>> findMatchingOrders(
      LatLng currentPos, List<LatLng> route) async {
    // Les commandes correspondent aux colis définis dans les checkpoints
    return [
      {
        "id": "COLIS-001",
        "client_name": "Moussa Bello",
        "client_phone": "+237 677 112 233",
        "pickup_lat": 10.5880,
        "pickup_lon": 14.2800,
        "pickup_name": "Zokok",
        "delivery_lat": 10.5846,
        "delivery_lon": 14.3049,
        "delivery_name": "Fada",
        "description": "Sac de riz (50 kg)",
        "weight": "50 kg",
        "price": 3500,
      },
      {
        "id": "COLIS-002",
        "client_name": "Aïssatou Maï",
        "client_phone": "+237 699 445 566",
        "pickup_lat": 10.5920,
        "pickup_lon": 14.3050,
        "pickup_name": "Marché Central",
        "delivery_lat": 10.5950,
        "delivery_lon": 14.3150,
        "delivery_name": "Kakataré",
        "description": "Cartons d'huile alimentaire",
        "weight": "30 kg",
        "price": 2000,
      },
      {
        "id": "COLIS-003",
        "client_name": "Ibrahim Djidda",
        "client_phone": "+237 655 778 899",
        "pickup_lat": 10.6050,
        "pickup_lon": 14.3100,
        "pickup_name": "Pitoaré",
        "delivery_lat": 10.6100,
        "delivery_lon": 14.2900,
        "delivery_name": "Dougoy",
        "description": "Sacs de ciment",
        "weight": "100 kg",
        "price": 5000,
      },
      {
        "id": "COLIS-004",
        "client_name": "Fatimé Oumar",
        "client_phone": "+237 622 334 455",
        "pickup_lat": 10.6050,
        "pickup_lon": 14.3350,
        "pickup_name": "Lopéré",
        "delivery_lat": 10.6050,
        "delivery_lon": 14.3350,
        "delivery_name": "Lopéré",
        "description": "Électroménager (ventilateurs)",
        "weight": "15 kg",
        "price": 1500,
      },
    ];
  }
}