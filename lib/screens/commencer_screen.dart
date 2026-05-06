import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'publier_trajet_screen.dart';
import 'connexion_screen.dart';
import 'inscription_screen.dart';

class CommencerScreen extends StatefulWidget {
  const CommencerScreen({super.key});

  @override
  State<CommencerScreen> createState() => _CommencerScreenState();
}

class _CommencerScreenState extends State<CommencerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image simulation (warehouse feel avec dégradé)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1208),
                  Color(0xFF0D0D0D),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Texture overlay subtile
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Logo TRIL
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppColors.accent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TRIL',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Hero visuel — camion stylisé
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _TruckIllustration(),
                ),

                const Spacer(flex: 1),

                // Texte principal
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            'Optimisez vos\nvoyages',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mutualisez vos chargements, évitez\nles zones à risque et réduisez vos\ncoûts jusqu\'à 50% dans le Sahel.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Boutons
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Bouton Commencer
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const InscriptionScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPrimary,
                                foregroundColor: AppColors.buttonText,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: Text(
                                'Commencer',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Lien connexion
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Vous avez un compte ? ',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ConnexionScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Connexion',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Illustration camion SVG-like avec CustomPainter
class _TruckIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _TruckPainter(),
        size: const Size(double.infinity, 200),
      ),
    );
  }
}

class _TruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow derrière
    final glowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(cx, cy), 120, glowPaint);

    final bodyPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    // Corps de la remorque
    final trailerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 120, cy - 30, 160, 55),
      const Radius.circular(4),
    );
    canvas.drawRRect(trailerRect, bodyPaint);

    // Bande accent sur la remorque
    canvas.drawRect(
      Rect.fromLTWH(cx - 120, cy - 30, 160, 6),
      accentPaint,
    );

    // Cabine du camion
    final cabinPath = Path()
      ..moveTo(cx + 40, cy - 30)
      ..lineTo(cx + 40, cy + 25)
      ..lineTo(cx + 105, cy + 25)
      ..lineTo(cx + 105, cy - 5)
      ..lineTo(cx + 90, cy - 30)
      ..close();
    canvas.drawPath(cabinPath, bodyPaint);

    // Vitre cabine
    final windshieldPath = Path()
      ..moveTo(cx + 45, cy - 26)
      ..lineTo(cx + 45, cy - 5)
      ..lineTo(cx + 88, cy - 5)
      ..lineTo(cx + 88, cy - 8)
      ..lineTo(cx + 76, cy - 26)
      ..close();
    canvas.drawPath(
      windshieldPath,
      Paint()..color = const Color(0xFF1565C0).withOpacity(0.6),
    );

    // Phare
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 97, cy + 5, 8, 5),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.accent,
    );

    // Roues
    for (final x in [cx - 90.0, cx - 55.0, cx + 60.0, cx + 85.0]) {
      canvas.drawCircle(Offset(x, cy + 25), 14, darkPaint);
      canvas.drawCircle(
        Offset(x, cy + 25),
        14,
        Paint()
          ..color = const Color(0xFF3A3A3A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(Offset(x, cy + 25), 5, bodyPaint);
    }

    // Ligne de sol
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(cx - 160, cy + 39),
      Offset(cx + 160, cy + 39),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
