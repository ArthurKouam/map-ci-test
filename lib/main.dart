import 'package:flutter/material.dart';

import 'data/demo_map_data.dart';
import 'pages/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MapPage(departure: demoDeparture, arrival: demoArrival),
      debugShowCheckedModeBanner: false,
    );
  }
}
