import 'package:flutter/material.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de Panadería')),
      body: const Center(child: Text('Aquí Xavier pondrá la lista de panes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Aquí se irá a la pantalla de registro
        child: const Icon(Icons.add),
      ),
    );
  }
}
