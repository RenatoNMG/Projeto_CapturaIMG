import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const AppFotosGeo());
}

class AppFotosGeo extends StatelessWidget {
  const AppFotosGeo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Fotos + Geolocalização',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(title: 'Fotos & Localização'),
      debugShowCheckedModeBanner: false,
    );
  }
}
