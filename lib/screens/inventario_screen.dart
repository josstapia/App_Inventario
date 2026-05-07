import 'package:flutter/material.dart';
import 'package:app_inventario/models/producto.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:app_inventario/widgets/product_card.dart';
import 'package:app_inventario/screens/add_product_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_inventario/screens/settings_page.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroBusqueda = '';
  bool _mostrarAlertas = true;
  String _nombreLocal = 'APP INVENTARIO';

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreLocal = prefs.getString('nombre_negocio') ?? 'APP INVENTARIO';
      _mostrarAlertas = prefs.getBool('alertas_stock') ?? true;
    });
  }

  void _notificar(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError
            ? Colors.redAccent
            : const Color.fromARGB(255, 46, 214, 12),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmarBorrado(Product p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto',
            style: TextStyle(color: Colors.white)),
        content: Text(
          "¿Quitar '${p.name}' del inventario?\nEsta acción no se puede deshacer.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DbHelper.instance.delete(p.id!);
      setState(() {});
      _notificar("'${p.name}' eliminado", esError: true);
    }
  }

  Future<void> _actualizarStock(Product p, int nuevoStock) async {
    setState(() => p.stock = nuevoStock);
    await DbHelper.instance.upsert(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(
          _nombreLocal,
          style: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsPage()));
              _cargarPreferencias();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildDashboard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          Expanded(child: _buildLista()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddProductScreen()),
          );
          setState(() {});
        },
        backgroundColor: const Color(0xFFE67E22),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('REGISTRAR',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── BARRA DE BÚSQUEDA ─────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) =>
            setState(() => _filtroBusqueda = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar pan o categoría...',
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF5AE6DF)),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _filtroBusqueda = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: Color(0xFF5AE6DF)),
          ),
        ),
      ),
    );
  }

  // ── DASHBOARD RESUMEN ─────────────────────────────────────
  Widget _buildDashboard() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        final productos = snapshot.data ?? [];
        final valorTotal =
            productos.fold(0.0, (sum, p) => sum + (p.price * p.stock));
        final bajoStock =
            productos.where((p) => p.stock < 5).length;

        return Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('PRODUCTOS', '${productos.length}',
                  const Color(0xFF21E408)),
              Container(width: 1, height: 30, color: Colors.white10),
              _statItem('VALOR STOCK',
                  '\$${valorTotal.toStringAsFixed(2)}',
                  const Color(0xFF5AE6DF)),
              if (_mostrarAlertas) ...[
                Container(
                    width: 1, height: 30, color: Colors.white10),
                _statItem(
                    'ALERTAS', '$bajoStock', Colors.redAccent),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  // ── LISTA DE PRODUCTOS ────────────────────────────────────
  Widget _buildLista() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF5AE6DF)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final productos = snapshot.data!.where((p) {
          return p.name.toLowerCase().contains(_filtroBusqueda) ||
              p.category.toLowerCase().contains(_filtroBusqueda);
        }).toList();

        if (productos.isEmpty) {
          return const Center(
            child: Text('No se encontraron resultados',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: productos.length,
          itemBuilder: (context, i) {
            final p = productos[i];
            return ProductCard(
              product: p,
              bajoStock: _mostrarAlertas && p.stock < 5,
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddProductScreen(producto: p)),
                );
                setState(() {});
              },
              onDelete: () => _confirmarBorrado(p),
              onIncrement: () => _actualizarStock(p, p.stock + 1),
              onDecrement: () => _actualizarStock(p, p.stock - 1),
            );
          },
        );
      },
    );
  }

  // ── ESTADO VACÍO ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bakery_dining,
              size: 72, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('Sin productos aún',
              style:
                  TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Toca REGISTRAR para agregar el primero',
              style:
                  TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}