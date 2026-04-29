import 'package:app_inventario/screens/inventario_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Asegúrate que el nombre coincida

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Panadería Stock',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const InventarioScreen(), // <--- Cargamos la pantalla de Xavier
    );
  }
}
