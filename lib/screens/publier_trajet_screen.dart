import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import 'suivi_livraison_screen.dart';
import '../services/local_data_service.dart';

class PublierTrajetScreen extends StatefulWidget {
  const PublierTrajetScreen({super.key});

  @override
  State<PublierTrajetScreen> createState() => _PublierTrajetScreenState();
}

class _PublierTrajetScreenState extends State<PublierTrajetScreen> {
  // Sélection quartiers
  Map<String, dynamic>? _selectedOrigin;
  Map<String, dynamic>? _selectedDestination;

  String _selectedVehicle = 'Mon véhicule';
  String _selectedVolume = '';
  bool _isPublishing = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Défaut : Domayo comme origine
    _selectedOrigin = maroaQuartiers.first;
  }

  void _centerMap() {
    if (_selectedOrigin != null) {
      _mapController.move(
        LatLng(_selectedOrigin!['lat'], _selectedOrigin!['lon']),
        14,
      );
    }
  }

  LatLng get _mapCenter {
    if (_selectedOrigin != null && _selectedDestination != null) {
      return LatLng(
        (_selectedOrigin!['lat'] + _selectedDestination!['lat']) / 2,
        (_selectedOrigin!['lon'] + _selectedDestination!['lon']) / 2,
      );
    }
    if (_selectedOrigin != null) {
      return LatLng(_selectedOrigin!['lat'], _selectedOrigin!['lon']);
    }
    return const LatLng(10.59918, 14.297);
  }

  void _publishTrajet() async {
    if (_selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner une origine et une destination.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isPublishing = false);
      _showConfirmation();
    }
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Trajet publié !',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre trajet ${_selectedOrigin!['name']} → ${_selectedDestination!['name']} est visible. Vous recevrez une notification dès qu\'une demande arrive.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuiviLivraisonScreen(
                          originQuartier: _selectedOrigin!,
                          destinationQuartier: _selectedDestination!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.buttonText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'Suivre le trajet',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Map interactive UNIQUEMENT (pas de MapPage statique)
          _buildLiveMap(),

          // Bouton centrer
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 70, right: 16),
                child: _CircleIconButton(
                  icon: Icons.my_location_rounded,
                  onTap: _centerMap,
                ),
              ),
            ),
          ),

          // AppBar transparent
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Publier un trajet',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Formulaire draggable en bas
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.58,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chips véhicule + volume
                          Row(
                            children: [
                              _DropdownChip(
                                icon: Icons.local_shipping_outlined,
                                label: _selectedVehicle,
                                onTap: _showVehiclePicker,
                              ),
                              const SizedBox(width: 12),
                              _DropdownChip(
                                icon: Icons.inventory_2_outlined,
                                label: _selectedVolume.isEmpty ? 'Volume' : _selectedVolume,
                                onTap: _showVolumePicker,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Configuration du trajet',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sélecteur origine/destination
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              children: [
                                // Origine
                                GestureDetector(
                                  onTap: () => _showQuartierPicker(
                                    isOrigin: true,
                                    title: 'Position de départ',
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: AppColors.textPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Départ',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            Text(
                                              _selectedOrigin != null
                                                  ? _selectedOrigin!['name']
                                                  : 'Choisir un quartier…',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedOrigin != null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down,
                                          color: AppColors.textMuted, size: 20),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 5.5, top: 8, bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(width: 1.5, height: 20, color: AppColors.divider),
                                    ],
                                  ),
                                ),

                                // Destination
                                GestureDetector(
                                  onTap: () => _showQuartierPicker(
                                    isOrigin: false,
                                    title: 'Destination finale',
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded,
                                          color: AppColors.danger, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Destination',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            Text(
                                              _selectedDestination != null
                                                  ? _selectedDestination!['name']
                                                  : 'Choisir un quartier…',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedDestination != null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down,
                                          color: AppColors.textMuted, size: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_selectedOrigin != null && _selectedDestination != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.accent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.route_rounded,
                                        color: AppColors.accent, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedOrigin!['name']} → ${_selectedDestination!['name']}',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '4 colis sur le trajet',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 28),

                          // Info heatmap
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_fire_department_rounded,
                                      color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Zones de forte demande',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Marché Central et Kakataré sont actifs',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Bouton publier
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _isPublishing ? null : _publishTrajet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPrimary,
                                foregroundColor: AppColors.buttonText,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: _isPublishing
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.buttonText,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Publier le trajet',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    final hasRoute =
        _selectedOrigin != null && _selectedDestination != null;

    final markers = <Marker>[];

    if (_selectedOrigin != null) {
      markers.add(Marker(
        point: LatLng(_selectedOrigin!['lat'], _selectedOrigin!['lon']),
        width: 48,
        height: 48,
        child: _buildPin(Colors.white, Icons.trip_origin_rounded),
      ));
    }
    if (_selectedDestination != null) {
      markers.add(Marker(
        point: LatLng(_selectedDestination!['lat'], _selectedDestination!['lon']),
        width: 48,
        height: 48,
        child: _buildPin(AppColors.danger, Icons.location_on_rounded),
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _mapCenter,
        initialZoom: 13.5,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.all),
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
        CircleLayer(
          circles: LocalDataService().getDemandHeatZones().map((z) {
            final intensity = (z['intensity'] as num).toDouble();
            final color = Color.lerp(
                Colors.yellow.withOpacity(0.05),
                Colors.orange.withOpacity(0.3),
                intensity)!;
            return CircleMarker(
              point: LatLng(z['lat'], z['lon']),
              radius: 400 + intensity * 300,
              useRadiusInMeter: true,
              color: color,
              borderColor: color.withOpacity(0.6),
              borderStrokeWidth: 1.5,
            );
          }).toList(),
        ),
        if (hasRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  LatLng(_selectedOrigin!['lat'], _selectedOrigin!['lon']),
                  LatLng(_selectedDestination!['lat'],
                      _selectedDestination!['lon']),
                ],
                strokeWidth: 3,
                color: AppColors.accent.withOpacity(0.6),
                strokeCap: StrokeCap.round,
                isDotted: true,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildPin(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ],
    );
  }

  void _showQuartierPicker({required bool isOrigin, required String title}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...maroaQuartiers.map((q) => ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.textMuted, size: 20),
                  title: Text(
                    q['name'],
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    setState(() {
                      if (isOrigin) {
                        _selectedOrigin = q;
                      } else {
                        _selectedDestination = q;
                      }
                    });
                    Navigator.pop(ctx);
                    // Mettre à jour la carte
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        _mapController.move(_mapCenter, 13.5);
                      }
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showVehiclePicker() {
    _showBottomOptions(
      title: 'Sélectionner un véhicule',
      options: ['Mon véhicule', 'Camion bâché 5T', 'Pick-up', 'Motocyclette', 'Autre'],
      onSelect: (val) => setState(() => _selectedVehicle = val),
    );
  }

  void _showVolumePicker() {
    _showBottomOptions(
      title: 'Volume disponible',
      options: [
        '0.1m³ (~Sac à dos)',
        '0.5m³ (~Valise)',
        '1m³ (~Petit réfrigérateur)',
        '5m³ (~Canapé)',
        'À définir'
      ],
      onSelect: (val) => setState(() => _selectedVolume = val),
    );
  }

  void _showBottomOptions({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt, style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  onSelect(opt);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
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