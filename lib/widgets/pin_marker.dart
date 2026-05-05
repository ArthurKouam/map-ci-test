import 'package:flutter/material.dart';

class PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const PinMarker({
    super.key,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 24)),
    );
  }
}
