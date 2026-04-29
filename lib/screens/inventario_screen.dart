import 'package:flutter/material.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      app_bar: AppBar(title: const Text('Inventario de Panadería')),
      body: const Center(child: Text('Aquí Xavier pondrá la lista de panes')),
      floating_action_button: FloatingActionButton(
        onPressed: () {}, // Aquí se irá a la pantalla de registro
        child: const Icon(Icons.add),
      ),
    );
  }
}
