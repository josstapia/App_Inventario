import 'package:flutter/material.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: const Text('Inventario de Panadería')),
      body: const Center(child: Text('Aquí Xavier pondrá la lista de panes')),
      floatingActionButton: FloatingActionButton(
=======
      app_bar: AppBar(title: const Text('Inventario de Panadería')),
      body: const Center(child: Text('Aquí Xavier pondrá la lista de panes')),
      floating_action_button: FloatingActionButton(
>>>>>>> ae6a1c4e4bef7c9ead2600f83a447db4baa0ff8e
        onPressed: () {}, // Aquí se irá a la pantalla de registro
        child: const Icon(Icons.add),
      ),
    );
  }
}
