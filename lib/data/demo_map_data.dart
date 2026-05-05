import 'package:latlong2/latlong.dart';

import '../models/map_point.dart';
import '../models/route_stop.dart';

const demoDeparture = RouteStop(
  label: 'Point de départ',
  position: LatLng(10.5956, 14.3247),
);

const demoArrival = RouteStop(
  label: 'Point d’arrivée',
  position: LatLng(10.6308, 14.3489),
);

const demoRouteIntermediatePoints = [
  LatLng(10.6048, 14.3295),
  LatLng(10.6127, 14.3354),
  LatLng(10.6219, 14.3421),
];

const demoMapPoints = [
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
