import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/vehicle.dart';
import 'dashboard_screen.dart';
import '../services/user_service.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  int _currentStep = 0;
  String _userType = 'Transporteur';
  final _nameController = TextEditingController(text: 'Alim');
  final _phoneController = TextEditingController(text: '656496419');
  final _passwordController = TextEditingController(text: 'hisense2018');
  final List<Vehicle> _vehicles = [];
  bool _isVerifying = false;
  final _userService = UserService();

  // Document status
  bool _idUploaded = false;
  bool _licenseUploaded = false;
  bool _selfieUploaded = false;

  final Map<VehicleType, List<String>> _brandsByType = {
    VehicleType.moto: ['Yamaha', 'Suzuki', 'Haojue', 'Honda', 'TVS', 'Bajaj'],
    VehicleType.voiture: [
      'Toyota',
      'Mercedes',
      'Peugeot',
      'Renault',
      'Hyundai',
      'Dacia'
    ],
    VehicleType.camion: [
      'Mercedes-Benz',
      'Volvo',
      'MAN',
      'Scania',
      'Iveco',
      'Renault Trucks',
      'DAF'
    ],
    VehicleType.autre: ['Caterpillar', 'JCB', 'Komatsu', 'Autres'],
  };

  void _nextStep() {
    if (_validateStep()) {
      if (_currentStep < 4) {
        setState(() => _currentStep++);
      } else {
        _finishRegistration();
      }
    }
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 1:
        if (_nameController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty ||
            _passwordController.text.trim().isEmpty) {
          _showError('Veuillez remplir toutes les informations personnelles.');
          return false;
        }
        if (_userType == 'Transporteur' &&
            (_nameController.text.trim() != 'Alim' ||
             _phoneController.text.trim() != '656496419' ||
             _passwordController.text.trim() != 'hisense2018')) {
          _showError('Veuillez utiliser les identifiants de test (Alim, 656496419, hisense2018).');
          return false;
        }
        break;
      case 2:
        if (_userType == 'Transporteur' &&
            (!_idUploaded || !_licenseUploaded || !_selfieUploaded)) {
          _showError('Veuillez uploader tous les documents requis.');
          return false;
        }
        break;
      case 3:
        if (_userType == 'Transporteur' && _vehicles.isEmpty) {
          _showError('Veuillez ajouter au moins un véhicule.');
          return false;
        }
        break;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _finishRegistration() async {
    setState(() => _isVerifying = true);
    
    // Simulation IA verification
    await Future.delayed(const Duration(milliseconds: 3000));

    final newUser = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _userType,
      phone: _phoneController.text.trim(),
      vehicles: _vehicles,
      isVerified: true,
    );

    final success = await _userService.registerUser(newUser);

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        setState(() => _isVerifying = false);
        _showError('Erreur lors de l\'enregistrement. Vérifiez que le serveur est lancé.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: _isVerifying ? _buildVerifyingState() : _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 5,
                  backgroundColor: AppColors.divider,
                  color: AppColors.accent,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentStep + 1}/5',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _getStepWidget(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(
                _currentStep == 4 ? 'Terminer' : 'Suivant',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return Container();
    }
  }

  // Step 0: User Type
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
            'Je suis...', 'Choisissez votre profil pour commencer.'),
        const SizedBox(height: 32),
        _buildChoiceCard(
          title: 'Transporteur',
          desc: 'Je possède un véhicule et je souhaite livrer des colis.',
          icon: Icons.local_shipping_rounded,
          isSelected: _userType == 'Transporteur',
          onTap: () => setState(() => _userType = 'Transporteur'),
        ),
        const SizedBox(height: 16),
        _buildChoiceCard(
          title: 'Client',
          desc: 'Je souhaite envoyer des marchandises.',
          icon: Icons.shopping_bag_rounded,
          isSelected: _userType == 'Client',
          onTap: () => setState(() => _userType = 'Client'),
        ),
      ],
    );
  }

  // Step 1: Basic Info
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
            'Informations personnelles', 'Parlez-nous un peu de vous.'),
        const SizedBox(height: 32),
        _buildLabel('Nom complet'),
        _buildTextField(
            controller: _nameController,
            hint: 'Ex: Jean Dupont',
            icon: Icons.person_outline),
        const SizedBox(height: 24),
        _buildLabel('Numéro de téléphone'),
        _buildTextField(
            controller: _phoneController,
            hint: '+237 6XX XXX XXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 24),
        _buildLabel('Mot de passe'),
        _buildTextField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: true),
      ],
    );
  }

  // Step 2: Documents
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Vérification d\'identité',
            'Uploadez vos documents pour validation.'),
        const SizedBox(height: 32),
        _buildDocUpload(
          'Carte d\'identité / Passeport',
          Icons.badge_outlined,
          _idUploaded,
          () => setState(() => _idUploaded = true),
        ),
        const SizedBox(height: 16),
        _buildDocUpload(
          'Permis de conduire',
          Icons.credit_card_outlined,
          _licenseUploaded,
          () => setState(() => _licenseUploaded = true),
        ),
        const SizedBox(height: 16),
        _buildDocUpload(
          'Photo de profil (Selfie)',
          Icons.camera_alt_outlined,
          _selfieUploaded,
          () => setState(() => _selfieUploaded = true),
        ),
      ],
    );
  }

  // Step 3: Vehicles
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
            'Mes véhicules', 'Enregistrez les véhicules que vous utiliserez.'),
        const SizedBox(height: 24),
        if (_vehicles.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.divider, style: BorderStyle.none),
            ),
            child: Column(
              children: [
                const Icon(Icons.directions_car_filled_outlined,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Aucun véhicule enregistré',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
              ],
            ),
          )
        else
          ..._vehicles.map((v) => _buildVehicleCard(v)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _showAddVehicleModal,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un véhicule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Step 4: Final Summary
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Prêt pour la vérification ?',
            'L\'IA va analyser vos documents pour valider votre compte.'),
        const SizedBox(height: 32),
        _buildSummaryRow('Profil', _userType),
        _buildSummaryRow('Nom', _nameController.text),
        _buildSummaryRow('Véhicules', '${_vehicles.length} enregistrés'),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La vérification prend généralement moins d\'une minute.',
                  style:
                      GoogleFonts.dmSans(color: AppColors.accent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 3),
          ),
          const SizedBox(height: 48),
          Text(
            'Vérification par l\'IA...',
            style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyse des documents et des photos en cours',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildStepHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(sub,
            style: GoogleFonts.dmSans(
                fontSize: 15, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildChoiceCard(
      {required String title,
      required String desc,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.divider,
              width: 2),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool obscure = false,
      TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.dmSans(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDocUpload(
      String label, IconData icon, bool done, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: done ? AppColors.accent : AppColors.divider,
              width: done ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: done ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                    color:
                        done ? AppColors.textPrimary : AppColors.textSecondary),
              ),
            ),
            if (done)
              const Icon(Icons.check_circle, color: AppColors.accent)
            else
              const Icon(Icons.cloud_upload_outlined,
                  color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Icon(
            v.type == VehicleType.moto
                ? Icons.motorcycle
                : Icons.local_shipping_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${v.brand} — ${v.registrationNumber}',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('${v.typeLabel} • ${v.capacity} m³',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (v.photoUrl != null)
            const Icon(Icons.image, color: AppColors.success, size: 18),
        ],
      ),
    );
  }

  void _showAddVehicleModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _VehicleEntryModal(
        brandsByType: _brandsByType,
        onSave: (v) => setState(() => _vehicles.add(v)),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          Text(val,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _VehicleEntryModal extends StatefulWidget {
  final Map<VehicleType, List<String>> brandsByType;
  final Function(Vehicle) onSave;

  const _VehicleEntryModal({required this.brandsByType, required this.onSave});

  @override
  State<_VehicleEntryModal> createState() => _VehicleEntryModalState();
}

class _VehicleEntryModalState extends State<_VehicleEntryModal> {
  VehicleType _selectedType = VehicleType.camion;
  String? _selectedBrand;
  final _registrationController = TextEditingController();
  bool _photoUploaded = false;

  @override
  Widget build(BuildContext context) {
    final brands = widget.brandsByType[_selectedType] ?? [];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nouveau véhicule',
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 24),

          // Type de véhicule
          _buildLabel('Type de véhicule'),
          Row(
            children: VehicleType.values.map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = type;
                    _selectedBrand = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.1)
                          : AppColors.divider.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent),
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color:
                          isSelected ? AppColors.accent : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Marque
          _buildLabel('Marque'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBrand,
                hint: Text('Choisir une marque',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted)),
                isExpanded: true,
                dropdownColor: AppColors.card,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                items: brands
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBrand = val),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Immatriculation
          _buildLabel('Numéro d\'immatriculation'),
          _buildTextField(
            controller: _registrationController,
            hint: 'Ex: LT-123-XY',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 24),

          // Photo du véhicule
          _buildLabel('Photo du véhicule (facultatif)'),
          GestureDetector(
            onTap: () => setState(() => _photoUploaded = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        _photoUploaded ? AppColors.success : AppColors.divider,
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(
                      _photoUploaded
                          ? Icons.check_circle
                          : Icons.camera_alt_outlined,
                      color: _photoUploaded
                          ? AppColors.success
                          : AppColors.textMuted,
                      size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _photoUploaded ? 'Photo enregistrée' : 'Prendre une photo',
                    style: GoogleFonts.dmSans(
                        color: _photoUploaded
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _validateAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              child: Text('Enregistrer le véhicule',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() {
    if (_selectedBrand == null || _registrationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
      return;
    }

    final vehicle = Vehicle(
      id: DateTime.now().toString(),
      name: _selectedBrand!,
      brand: _selectedBrand!,
      registrationNumber: _registrationController.text.toUpperCase(),
      type: _selectedType,
      capacity: _selectedType == VehicleType.camion ? 15 : 2,
      photoUrl: _photoUploaded ? 'simulated_path' : null,
    );

    widget.onSave(vehicle);
    Navigator.pop(context);
  }

  IconData _getIconForType(VehicleType t) {
    switch (t) {
      case VehicleType.moto:
        return Icons.motorcycle;
      case VehicleType.voiture:
        return Icons.directions_car;
      case VehicleType.camion:
        return Icons.local_shipping;
      case VehicleType.autre:
        return Icons.more_horiz;
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        style: GoogleFonts.dmSans(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
