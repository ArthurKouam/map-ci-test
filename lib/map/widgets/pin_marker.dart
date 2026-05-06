import 'package:flutter/material.dart';

class PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isLarge;

  const PinMarker({
    super.key,
    required this.color,
    required this.icon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo effect
        Container(
          width: isLarge ? 48 : 40,
          height: isLarge ? 48 : 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        // Main marker
        Container(
          width: isLarge ? 32 : 28,
          height: isLarge ? 32 : 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isLarge ? 18 : 16,
          ),
        ),
      ],
    );
  }
}
