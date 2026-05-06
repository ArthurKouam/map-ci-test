import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/local_data_service.dart';

// ─────────────────────────────────────────
// Modèle colis / commande acceptée
// ─────────────────────────────────────────
class AcceptedOrder {
  final String id;
  final String clientName;
  final String clientPhone;
  final String description;
  final String weight;
  final double price;
  final String pickupName;
  final LatLng pickup;
  final String deliveryName;
  final LatLng delivery;
  bool isDelivered;

  AcceptedOrder({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.description,
    required this.weight,
    required this.price,
    required this.pickupName,
    required this.pickup,
    required this.deliveryName,
    required this.delivery,
    this.isDelivered = false,
  });

  factory AcceptedOrder.fromMap(Map<String, dynamic> m) => AcceptedOrder(
        id: m['id'],
        clientName: m['client_name'],
        clientPhone: m['client_phone'],
        description: m['description'],
        weight: m['weight'],
        price: (m['price'] as num).toDouble(),
        pickupName: m['pickup_name'],
        pickup: LatLng(m['pickup_lat'], m['pickup_lon']),
        deliveryName: m['delivery_name'],
        delivery: LatLng(m['delivery_lat'], m['delivery_lon']),
      );
}

// ─────────────────────────────────────────
// Écran principal
// ─────────────────────────────────────────
class SuiviLivraisonScreen extends StatefulWidget {
  final Map<String, dynamic>? originQuartier;
  final Map<String, dynamic>? destinationQuartier;

  const SuiviLivraisonScreen({
    super.key,
    this.originQuartier,
    this.destinationQuartier,
  });

  @override
  State<SuiviLivraisonScreen> createState() => _SuiviLivraisonScreenState();
}

class _SuiviLivraisonScreenState extends State<SuiviLivraisonScreen>
    with TickerProviderStateMixin {
  final _localData = LocalDataService();
  final MapController _mapController = MapController();

  // Données du trajet
  List<Map<String, dynamic>> _checkpoints = [];
  List<LatLng> _routePolyline = [];
  List<dynamic> _riskZones = [];

  // Position "transporteur" simulée = dernier checkpoint validé
  int _currentCheckpointIndex = 0; // index dans _checkpoints

  // Commandes
  List<Map<String, dynamic>> _pendingMatches = [];
  List<AcceptedOrder> _acceptedOrders = [];
  bool _tripLaunched = false;
  bool _isLoading = true;

  // Animation de déplacement du marqueur
  late AnimationController _moveController;
  late Animation<double> _moveAnim;
  LatLng _displayedTruckPos = const LatLng(10.59918, 14.297);
  LatLng _truckTarget = const LatLng(10.59918, 14.297);
  LatLng _truckFrom = const LatLng(10.59918, 14.297);

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _showModal = true;
  bool _hasNotification = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _moveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _moveAnim = CurvedAnimation(parent: _moveController, curve: Curves.easeInOut);
    _moveAnim.addListener(_updateTruckPos);

    _loadData();
  }

  Future<void> _loadData() async {
    await _localData.init();
    final checkpoints = _localData.getCheckpoints();
    final zones = _localData.getRiskZones();

    // Route OSRM sur tous les checkpoints
    final coords = _localData.getTripRouteCoords();
    List<LatLng> polyline = [];
    for (int i = 0; i < coords.length - 1; i++) {
      final seg = await _localData.getRealRoute(coords[i], coords[i + 1]);
      if (polyline.isNotEmpty && seg.isNotEmpty) {
        polyline.addAll(seg.skip(1));
      } else {
        polyline.addAll(seg);
      }
    }

    // Position initiale du camion = 1er checkpoint (départ)
    final startCp = checkpoints.first;
    final startPos = LatLng(startCp['lat'], startCp['lon']);

    // Charger les matches potentiels (simulés après 4s)
    Timer(const Duration(seconds: 4), _loadMatches);

    if (mounted) {
      setState(() {
        _checkpoints = checkpoints;
        _routePolyline = polyline.isEmpty ? coords : polyline;
        _riskZones = zones;
        _displayedTruckPos = startPos;
        _truckFrom = startPos;
        _truckTarget = startPos;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMatches() async {
    final matches = await _localData.findMatchingOrders(
        _displayedTruckPos, _routePolyline);
    if (mounted) {
      setState(() {
        _pendingMatches = matches;
        _hasNotification = matches.isNotEmpty;
      });
    }
  }

  void _updateTruckPos() {
    if (!mounted) return;
    final t = _moveAnim.value;
    setState(() {
      _displayedTruckPos = LatLng(
        _truckFrom.latitude + (_truckTarget.latitude - _truckFrom.latitude) * t,
        _truckFrom.longitude +
            (_truckTarget.longitude - _truckFrom.longitude) * t,
      );
    });
  }

  void _animateTruckTo(LatLng target) {
    _truckFrom = _displayedTruckPos;
    _truckTarget = target;
    _moveController.forward(from: 0);
  }

  void _advanceCheckpoint() {
    if (_currentCheckpointIndex >= _checkpoints.length - 1) return;
    final nextIdx = _currentCheckpointIndex + 1;
    final nextCp = _checkpoints[nextIdx];
    final nextPos = LatLng(nextCp['lat'], nextCp['lon']);
    _animateTruckTo(nextPos);
    setState(() => _currentCheckpointIndex = nextIdx);
    _mapController.move(nextPos, 14);
  }

  void _centerOnTruck() {
    _mapController.move(_displayedTruckPos, 14);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  // ─── Match Card Accept/Reject ───
  void _acceptMatch(Map<String, dynamic> match) {
    final order = AcceptedOrder.fromMap(match);
    setState(() {
      _acceptedOrders.add(order);
      _pendingMatches.remove(match);
      _hasNotification = _pendingMatches.isNotEmpty;
      _showModal = true;
    });
    _showSuccessSnack('${order.id} accepté · ${order.clientName}');
  }

  void _rejectMatch(Map<String, dynamic> match) {
    setState(() {
      _pendingMatches.remove(match);
      _hasNotification = _pendingMatches.isNotEmpty;
    });
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── Detail sheet pour un checkpoint ───
  void _showCheckpointDetail(Map<String, dynamic> cp) {
    final parcel = cp['parcel'] as Map<String, dynamic>?;
    final type = cp['type'] as String;
    final isDone = (cp['order'] as int) <= _currentCheckpointIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CheckpointDetailSheet(
        cp: cp,
        parcel: parcel,
        isDone: isDone,
        onCall: parcel != null
            ? () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Appel vers ${parcel['client_phone']}',
                      style: GoogleFonts.dmSans()),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            : null,
        onValidate: (!isDone && type != 'depart' && type != 'arrivee')
            ? () {
                Navigator.pop(ctx);
                _advanceCheckpoint();
              }
            : null,
      ),
    );
  }

  // ─── Detail sheet pour un colis accepté ───
  void _showOrderDetail(AcceptedOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _OrderDetailSheet(
        order: order,
        onDelivered: order.isDelivered
            ? null
            : () {
                Navigator.pop(ctx);
                setState(() => order.isDelivered = true);
                _showSuccessSnack('${order.id} livré avec succès !');
              },
        onCall: () {
          HapticFeedback.lightImpact();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // ── Map ──
          _buildMap(),

          // ── Header ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _CircleBtn(
                    icon: Icons.my_location_rounded,
                    onTap: _centerOnTruck,
                  ),
                  const SizedBox(width: 8),
                  if (_hasNotification)
                    Stack(
                      children: [
                        _CircleBtn(
                          icon: Icons.notifications_rounded,
                          onTap: _showNotificationsPanel,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.danger, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  _CircleBtn(
                    icon: _showModal ? Icons.map_outlined : Icons.list_alt_rounded,
                    onTap: () => setState(() => _showModal = !_showModal),
                  ),
                ],
              ),
            ),
          ),

          // ── Match cards en attente (sur la carte, au-dessus) ──
          if (!_tripLaunched && _pendingMatches.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Column(
                  children: _pendingMatches
                      .take(1)
                      .map((m) => _MatchCard(
                            match: m,
                            onAccept: () => _acceptMatch(m),
                            onReject: () => _rejectMatch(m),
                          ))
                      .toList(),
                ),
              ),
            ),

          // ── Modal bas ──
          if (_showModal)
            Align(
              alignment: Alignment.bottomCenter,
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : _buildBottomModal(),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoading) {
      return Container(
        color: AppColors.black,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    // Markers des checkpoints acceptés sur la carte
    final cpMarkers = <Marker>[];
    for (final cp in _checkpoints) {
      final type = cp['type'] as String;
      if (type == 'depart' || type == 'arrivee') continue;
      // Seulement afficher les checkpoints des commandes acceptées
      final parcel = cp['parcel'] as Map<String, dynamic>?;
      if (parcel == null) continue;
      final isAccepted =
          _acceptedOrders.any((o) => o.id == parcel['id']) || !_tripLaunched;
      if (!_tripLaunched && !isAccepted) continue;

      final pos = LatLng(cp['lat'], cp['lon']);
      final isPickup = type == 'pickup' || type == 'pickup_dropoff';
      final isDone = (cp['order'] as int) <= _currentCheckpointIndex;

      cpMarkers.add(Marker(
        point: pos,
        width: 46,
        height: 46,
        child: GestureDetector(
          onTap: () => _showCheckpointDetail(cp),
          child: _buildCpPin(isPickup, isDone),
        ),
      ));
    }

    // Heatmap demande
    final heatCircles = _localData.getDemandHeatZones().map((z) {
      final intensity = (z['intensity'] as num).toDouble();
      final color = Color.lerp(
          Colors.yellow.withOpacity(0.04),
          Colors.deepOrange.withOpacity(0.22),
          intensity)!;
      return CircleMarker(
        point: LatLng(z['lat'], z['lon']),
        radius: 350 + intensity * 250,
        useRadiusInMeter: true,
        color: color,
        borderColor: color.withOpacity(0.5),
        borderStrokeWidth: 1,
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _displayedTruckPos,
        initialZoom: 13.5,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.tril.app',
          maxZoom: 19,
        ),
        // Heatmap zones de demande
        CircleLayer(circles: heatCircles),
        // Zones de risque
        CircleLayer(
          circles: _riskZones.map((zone) {
            final color = zone['level'] == 'high' ? AppColors.danger : AppColors.warning;
            return CircleMarker(
              point: LatLng(zone['lat'], zone['lon']),
              radius: (zone['radius'] as num).toDouble(),
              useRadiusInMeter: true,
              color: color.withOpacity(0.12),
              borderColor: color.withOpacity(0.35),
              borderStrokeWidth: 1.5,
            );
          }).toList(),
        ),
        // Route polyline
        if (_routePolyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePolyline,
                strokeWidth: 10,
                color: AppColors.success.withOpacity(0.15),
                strokeCap: StrokeCap.round,
              ),
              Polyline(
                points: _routePolyline,
                strokeWidth: 3.5,
                color: AppColors.success,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),
        // Checkpoints markers
        MarkerLayer(markers: cpMarkers),
        // Marqueur départ
        if (_checkpoints.isNotEmpty)
          MarkerLayer(markers: [
            Marker(
              point: LatLng(
                  _checkpoints.first['lat'], _checkpoints.first['lon']),
              width: 48,
              height: 48,
              child: _buildSpecialPin(Colors.white, Icons.trip_origin_rounded),
            ),
            // Marqueur arrivée
            Marker(
              point: LatLng(_checkpoints.last['lat'], _checkpoints.last['lon']),
              width: 48,
              height: 48,
              child: _buildSpecialPin(AppColors.danger, Icons.flag_rounded),
            ),
          ]),
        // Camion animé
        MarkerLayer(markers: [
          Marker(
            point: _displayedTruckPos,
            width: 54,
            height: 54,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: _buildTruckMarker(),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildTruckMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.local_shipping_rounded,
              color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildCpPin(bool isPickup, bool isDone) {
    final color = isDone
        ? AppColors.success
        : isPickup
            ? AppColors.accent
            : AppColors.warning;
    final icon = isDone
        ? Icons.check_rounded
        : isPickup
            ? Icons.add_business_rounded
            : Icons.archive_rounded;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: color.withOpacity(0.2), shape: BoxShape.circle),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ],
    );
  }

  Widget _buildSpecialPin(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle)),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ],
    );
  }

  // ─── Modal bas ───────────────────────────────────────────
  Widget _buildBottomModal() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tripLaunched ? 'Trajet en cours' : 'Trajet préparé',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            '${_acceptedOrders.length} colis · ${_checkpoints.length - 2} arrêts',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _tripLaunched
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _tripLaunched ? 'En route' : 'Prêt',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tripLaunched
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Timeline des checkpoints
                _buildTimeline(),

                const SizedBox(height: 16),

                // Colis acceptés
                if (_acceptedOrders.isNotEmpty) ...[
                  Text(
                    'Colis acceptés',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _acceptedOrders.length,
                      itemBuilder: (_, i) =>
                          _OrderChip(order: _acceptedOrders[i], onTap: () => _showOrderDetail(_acceptedOrders[i])),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bouton lancer / continuer
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _tripLaunched
                        ? (_currentCheckpointIndex < _checkpoints.length - 1
                            ? _advanceCheckpoint
                            : null)
                        : (_acceptedOrders.isNotEmpty
                            ? _launchTrip
                            : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tripLaunched
                          ? AppColors.success
                          : AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _tripLaunched
                              ? Icons.skip_next_rounded
                              : Icons.play_arrow_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _tripLaunched
                              ? (_currentCheckpointIndex >= _checkpoints.length - 1
                                  ? 'Trajet terminé ✓'
                                  : 'Étape suivante → ${_checkpoints[_currentCheckpointIndex + 1]['name']}')
                              : 'Lancer le trajet',
                          style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchTrip() {
    setState(() => _tripLaunched = true);
    // Animer vers le 1er vrai checkpoint
    if (_checkpoints.length > 1) {
      final next = _checkpoints[1];
      _animateTruckTo(LatLng(next['lat'], next['lon']));
    }
  }

  // ─── Timeline scrollable ───
  Widget _buildTimeline() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _checkpoints.length,
        separatorBuilder: (_, __) => Container(
          width: 24,
          alignment: Alignment.center,
          child: Container(
            height: 1.5,
            width: 20,
            color: AppColors.divider,
          ),
        ),
        itemBuilder: (_, i) {
          final cp = _checkpoints[i];
          final type = cp['type'] as String;
          final isDone = i <= _currentCheckpointIndex;
          final isActive = i == _currentCheckpointIndex;

          Color dotColor;
          IconData dotIcon;
          if (type == 'depart') {
            dotColor = Colors.white;
            dotIcon = Icons.trip_origin_rounded;
          } else if (type == 'arrivee') {
            dotColor = AppColors.danger;
            dotIcon = Icons.flag_rounded;
          } else if (type == 'pickup') {
            dotColor = isDone ? AppColors.success : AppColors.accent;
            dotIcon = isDone ? Icons.check : Icons.add_business_rounded;
          } else if (type == 'dropoff') {
            dotColor = isDone ? AppColors.success : AppColors.warning;
            dotIcon = isDone ? Icons.check : Icons.archive_rounded;
          } else {
            dotColor = isDone ? AppColors.success : AppColors.accent;
            dotIcon = isDone ? Icons.check : Icons.swap_horiz_rounded;
          }

          return GestureDetector(
            onTap: () => _showCheckpointDetail(cp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 36 : 30,
                  height: isActive ? 36 : 30,
                  decoration: BoxDecoration(
                    color: isDone ? dotColor : AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? dotColor : AppColors.divider,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: dotColor.withOpacity(0.4),
                                blurRadius: 8)
                          ]
                        : null,
                  ),
                  child: Icon(dotIcon,
                      size: isActive ? 16 : 13,
                      color: isDone ? Colors.white : dotColor),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 52,
                  child: Text(
                    cp['name'],
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationsPanel() {
    setState(() => _hasNotification = false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demandes sur votre trajet',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            if (_pendingMatches.isEmpty)
              Text('Aucune nouvelle demande.',
                  style:
                      GoogleFonts.dmSans(color: AppColors.textSecondary))
            else
              ..._pendingMatches.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MatchCard(
                      match: m,
                      onAccept: () {
                        Navigator.pop(ctx);
                        _acceptMatch(m);
                      },
                      onReject: () {
                        Navigator.pop(ctx);
                        _rejectMatch(m);
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Match Card (Swipeable)
// ─────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _MatchCard(
      {required this.match, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(match['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 28),
      ),
      onDismissed: (_) => onReject(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match['client_name'],
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 14),
                      ),
                      Text(
                        '${match['pickup_name']} → ${match['delivery_name']}',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${match['price']} FCFA',
                    style: GoogleFonts.dmSans(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${match['description']} · ${match['weight']}',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Ignorer',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Accepter',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Order Chip (horizontal list)
// ─────────────────────────────────────────
class _OrderChip extends StatelessWidget {
  final AcceptedOrder order;
  final VoidCallback onTap;

  const _OrderChip({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.isDelivered
                ? AppColors.success.withOpacity(0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  order.isDelivered
                      ? Icons.check_circle_rounded
                      : Icons.inventory_2_rounded,
                  size: 16,
                  color: order.isDelivered ? AppColors.success : AppColors.accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.id,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.clientName,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${order.price.toInt()} FCFA',
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Checkpoint Detail Sheet
// ─────────────────────────────────────────
class _CheckpointDetailSheet extends StatelessWidget {
  final Map<String, dynamic> cp;
  final Map<String, dynamic>? parcel;
  final bool isDone;
  final VoidCallback? onCall;
  final VoidCallback? onValidate;

  const _CheckpointDetailSheet({
    required this.cp,
    this.parcel,
    required this.isDone,
    this.onCall,
    this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final type = cp['type'] as String;
    final typeLabel = type == 'pickup'
        ? 'Enlèvement'
        : type == 'dropoff'
            ? 'Livraison'
            : type == 'pickup_dropoff'
                ? 'Enlèvement & Livraison'
                : type == 'depart'
                    ? 'Point de départ'
                    : 'Destination finale';
    final color = isDone
        ? AppColors.success
        : type == 'pickup' || type == 'pickup_dropoff'
            ? AppColors.accent
            : AppColors.warning;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'pickup'
                        ? Icons.add_business_rounded
                        : type == 'dropoff'
                            ? Icons.archive_rounded
                            : Icons.swap_horiz_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cp['name'],
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(typeLabel,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: color)),
                    ],
                  ),
                ),
                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Validé',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ),
              ],
            ),
            if (parcel != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Colis',
                        value: parcel!['id']),
                    _DetailRow(
                        icon: Icons.description_outlined,
                        label: 'Contenu',
                        value: parcel!['description']),
                    _DetailRow(
                        icon: Icons.scale_outlined,
                        label: 'Poids',
                        value: parcel!['weight']),
                    _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Client',
                        value: parcel!['client_name']),
                    _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: parcel!['client_phone']),
                    _DetailRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Tarif',
                        value: '${parcel!['price']} FCFA'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Boutons contact
              Row(
                children: [
                  _ActionBtn(
                    icon: Icons.phone_rounded,
                    label: 'Appeler',
                    color: AppColors.success,
                    onTap: onCall ?? () {},
                  ),
                  const SizedBox(width: 10),
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Message',
                    color: AppColors.accent,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _ActionBtn(
                    icon: Icons.map_outlined,
                    label: 'Itinéraire',
                    color: AppColors.warning,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
            if (onValidate != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onValidate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text('Valider cette étape',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text('$label :',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Order Detail Sheet
// ─────────────────────────────────────────
class _OrderDetailSheet extends StatelessWidget {
  final AcceptedOrder order;
  final VoidCallback? onDelivered;
  final VoidCallback onCall;

  const _OrderDetailSheet(
      {required this.order, this.onDelivered, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.id,
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(order.description,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (order.isDelivered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Livré',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Client',
                      value: order.clientName),
                  _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: order.clientPhone),
                  _DetailRow(
                      icon: Icons.scale_outlined,
                      label: 'Poids',
                      value: order.weight),
                  _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Enlèvement',
                      value: order.pickupName),
                  _DetailRow(
                      icon: Icons.flag_outlined,
                      label: 'Livraison',
                      value: order.deliveryName),
                  _DetailRow(
                      icon: Icons.attach_money_rounded,
                      label: 'Tarif',
                      value: '${order.price.toInt()} FCFA'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.phone_rounded,
                  label: 'Appeler',
                  color: AppColors.success,
                  onTap: onCall,
                ),
                const SizedBox(width: 10),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  color: AppColors.accent,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            if (onDelivered != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onDelivered,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text('Confirmer la livraison',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Bouton circulaire ───
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}