import 'dart:io';
import 'package:app_inventario/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/producto.dart';
import 'services/database_helper.dart';
import 'package:app_inventario/screens/inventario_screen.dart';

String _nombreLocal = "APP INVENTARIO";
bool _mostrarAlertas = true; // Variable global en el estado

final _nombreCtrl = TextEditingController();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanaderiaApp());
}

class PanaderiaApp extends StatelessWidget {
  const PanaderiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INVENTARIO',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5AE6DF),
          secondary: Color(0xFFE67E22),
          surface: Color(0xFF121212),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF121212),
          border:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
      home: const InventarioScreen(),
    );
  }
}

class InventarioMaster extends StatefulWidget {
  const InventarioMaster({super.key});

  @override
  State<InventarioMaster> createState() => _InventarioMasterState();
}

class _InventarioMasterState extends State<InventarioMaster> {
  // Controladores de formulario
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  // Controlador de búsqueda
  final _searchCtrl = TextEditingController();
  String _filtroBusqueda = "";

  String? _imagePath;
  int? _editingId;
  String _categoriaSeleccionada = 'Salado';
  final List<String> _categorias = [
    'Salado',
    'Dulce',
    'Pastelería',
    'Bebida',
    'Otro'
  ];

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
  }

  List<String> _categoriasApp = [
    'Salado',
    'Dulce',
    'Pastelería',
    'Bebida',
    'Otro'
  ];
  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreLocal = prefs.getString('nombre_negocio') ?? "APP INVENTARIO";
      _mostrarAlertas = prefs.getBool('alertas_stock') ?? true;

      // CARGAR CATEGORÍAS DINÁMICAS
      _categoriasApp = prefs.getStringList('lista_categorias') ??
          ['Salado', 'Dulce', 'Pastelería', 'Bebida', 'Otro'];

      // Validar que la categoría seleccionada aún exista en la lista
      if (!_categoriasApp.contains(_categoriaSeleccionada)) {
        _categoriaSeleccionada = _categoriasApp.first;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarPreferencias(); // Carga el nombre al iniciar la app
  }

  Future<void> _procesarDatos() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _notificar("El nombre es obligatorio", esError: true);
      return;
    }

    final int? cant = int.tryParse(_cantidadCtrl.text);
    if (cant == null || cant < 0) {
      _notificar("Stock debe ser un número positivo", esError: true);
      return;
    }
    final double? precio = double.tryParse(_precioCtrl.text);
    if (precio == null || precio <= 0) {
      _notificar("El precio debe ser mayor a 0", esError: true);
      return;
    }

    final producto = Product(
      id: _editingId,
      name: _nombreCtrl.text,
      stock: cant,
      price: double.tryParse(_precioCtrl.text) ?? 0.0,
      category: _categoriaSeleccionada,
      imagePath: _imagePath,
    );

    await DbHelper.instance.upsert(producto);
    _notificar(
        _editingId == null ? "Registrado con éxito" : "Actualizado con éxito");
    _limpiarFormulario();
    setState(() {});
  }

  void _notificar(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            esError ? Colors.redAccent : const Color.fromARGB(255, 46, 214, 12),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _cantidadCtrl.clear();
    _precioCtrl.clear();
    setState(() {
      _imagePath = null;
      _editingId = null;
      _categoriaSeleccionada = 'Salado';
    });
  }

  // --- COMPONENTES DE INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nombreLocal,
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()));
              _cargarPreferencias(); // ¡Esta línea es vital para que la lista cambie de color!
            },
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(), // Nueva barra de búsqueda
          _buildDashboard(),
          _buildFormulario(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  // Widget de búsqueda (HU mejorada)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) =>
            setState(() => _filtroBusqueda = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar pan o categoría...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5AE6DF)),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _filtroBusqueda = "");
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
            borderSide: const BorderSide(color: Color(0xFF5AE6DF)),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        final productos = snapshot.data ?? [];
        double valorTotal =
            productos.fold(0, (sum, p) => sum + (p.price * p.stock));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("PRODUCTOS", productos.length.toString()),
              Container(width: 1, height: 30, color: Colors.white10),
              _statItem("VALOR STOCK", "\$${valorTotal.toStringAsFixed(2)}"),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF21E408))),
      ],
    );
  }

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF5AE6DF)),
                  ),
                  child: _imagePath == null
                      ? const Icon(Icons.add_a_photo_outlined,
                          color: Colors.grey, size: 20)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child:
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _precioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio'))),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  items: _categoriasApp
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _procesarDatos,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_editingId == null ? 'REGISTRAR' : 'GUARDAR CAMBIOS'),
          ),
          if (_editingId != null)
            TextButton(
                onPressed: _limpiarFormulario,
                child: const Text("Cancelar edición",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        // --- FILTRO DE BÚSQUEDA ---
        final productos = snapshot.data!.where((p) {
          return p.name.toLowerCase().contains(_filtroBusqueda) ||
              p.category.toLowerCase().contains(_filtroBusqueda);
        }).toList();

        if (productos.isEmpty) {
          return const Center(
              child: Text("No se encontraron resultados",
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: productos.length,
          itemBuilder: (context, i) {
            final p = productos[i];
            final bool bajoStock = _mostrarAlertas && p.stock < 5;

            // ... dentro de tu itemBuilder
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: 140, // Un poco más de aire para seguridad
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: bajoStock
                        ? Colors.redAccent
                        : const Color(0xFF5AE6DF).withOpacity(0.3),
                    width: bajoStock ? 2.5 : 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. IMAGEN
                  p.imagePath != null
                      ? CircleAvatar(
                          radius: 30,
                          backgroundImage: FileImage(File(p.imagePath!)))
                      : const CircleAvatar(
                          radius: 30, child: Icon(Icons.bakery_dining)),

                  const SizedBox(width: 12),

                  // 2. INFORMACIÓN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("Stock: ${p.stock}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: bajoStock
                                    ? Colors.redAccent
                                    : Colors.grey)),
                        if (bajoStock) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.redAccent, size: 26),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(p.category.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // 3. PRECIO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "\$${p.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Color(0xFF21E408),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  // 4. SECCIÓN DE ACCIONES
                  // Usamos Expanded para que la columna respete el alto del Container

                  SizedBox(
                    width: 100, // Ancho fijo para la zona de botones
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // BOTONES SUPERIORES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _editingId = p.id;
                                    _nombreCtrl.text = p.name;
                                    _cantidadCtrl.text = p.stock.toString();
                                    _precioCtrl.text = p.price.toString();
                                    _imagePath = p.imagePath;
                                    _categoriaSeleccionada = p.category;
                                  });
                                },
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_note,
                                        color: Color(0xFF5AE6DF), size: 30),
                                    Text("Editar",
                                        style: TextStyle(
                                            color: Color(0xFF5AE6DF),
                                            fontSize: 10)),
                                  ],
                                )),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => _confirmarBorrado(p),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 30),
                                  Text("Eliminar",
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // BOTONES INFERIORES (+ y -)
                        // Agregamos un FittedBox para que si el contenido es muy grande, se encoja en lugar de desbordar
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => p.stock > 0
                                    ? _actualizarStockRapido(p, p.stock - 1)
                                    : null,
                                child: const Icon(Icons.remove_circle_outline,
                                    color: Colors.grey, size: 36),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () =>
                                    _actualizarStockRapido(p, p.stock + 1),
                                child: const Icon(Icons.add_circle_outline,
                                    color: Color(0xFF5AE6DF), size: 36),
                              ),
                              const SizedBox(width: 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarBorrado(Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text("Eliminar"),
        content: Text("¿Quitar '${p.name}' del inventario?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("NO")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DbHelper.instance.delete(p.id!);
              Navigator.pop(context);
              setState(() {});
              _notificar("Producto '${p.name}' eliminado", esError: true);
            },
            child:
                const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _actualizarStockRapido(Product producto, int nuevoStock) async {
    setState(() {
      producto.stock = nuevoStock;
    });

    // Usamos 'instance.upsert' que es el método que ya tienes definido
    await DbHelper.instance.upsert(producto);
  }
}
