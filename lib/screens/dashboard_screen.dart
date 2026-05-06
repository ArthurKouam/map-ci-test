import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tril_app/map/models/route_stop.dart';
import '../theme/app_theme.dart';
import '../map/pages/map_page.dart';
import '../map/data/demo_map_data.dart';
import 'publier_trajet_screen.dart';
import '../services/local_data_service.dart';
import '../services/user_service.dart';
import '../models/vehicle.dart';
import 'package:latlong2/latlong.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showModal = true;
  List<UserProfile> _users = [];
  final _userService = UserService();
  final _localData = LocalDataService();
  bool _isLoading = true;
  List<dynamic> _riskZones = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await _localData.init();
    final users = await _userService.getUsers();
    final zones = _localData.getRiskZones();
    
    if (mounted) {
      setState(() {
        _users = users;
        _riskZones = zones;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Background Map
          MapPage(
            departure: const RouteStop(label: 'Maroua', position: LatLng(10.59918, 14.297)),
            arrival: const RouteStop(label: 'Maroua', position: LatLng(10.59918, 14.297)),
            riskZones: _riskZones,
            customPolyline: const [], // Hide route until trip is created
            showSummary: false,
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildCircleBtn(Icons.menu, () {}),
                  const Spacer(),
                  _buildCircleBtn(
                    _showModal ? Icons.map_outlined : Icons.list_alt_rounded,
                    () => setState(() => _showModal = !_showModal),
                  ),
                ],
              ),
            ),
          ),

          // Floating Modal
          if (_showModal)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildWelcomeModal(),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildWelcomeModal() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, Alim !',
                    style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Profil vérifié • Sahel Nord',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.accent))
          else if (_users.isNotEmpty) ...[
            Text(
              'Transporteurs actifs à proximité',
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle, color: AppColors.textMuted, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          user.name,
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.vehicles.isNotEmpty ? user.vehicles.first.brand : 'A pied',
                          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublierTrajetScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_location_alt_rounded),
                  const SizedBox(width: 12),
                  Text(
                    'Lancer un trajet',
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
