import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart'; // Tu paquete local
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  // Inicialización necesaria para asegurar que SQLite esté listo antes de arrancar
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanaderiaApp());
}

class PanaderiaApp extends StatelessWidget {
  const PanaderiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APP INVENTARIO', // Título interno de la aplicación
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 90, 230, 223)),
        useMaterial3: true,
      ),
      home: const InventarioMaster(),
    );
  }
}

class InventarioMaster extends StatefulWidget {
  const InventarioMaster({super.key});

  @override
  State<InventarioMaster> createState() => _InventarioMasterState();
}

class _InventarioMasterState extends State<InventarioMaster> {
  // Controladores de texto
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  // Variables de estado para edición e imagen
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

  // Función para seleccionar imagen desde la galería
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
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

  // Lógica para Guardar o Actualizar en la base de datos
  Future<void> _procesarDatos() async {
    if (_nombreCtrl.text.isEmpty || _cantidadCtrl.text.isEmpty) return;

    final datos = {
      'nombre': _nombreCtrl.text,
      'cantidad': int.parse(_cantidadCtrl.text),
      'precio': double.tryParse(_precioCtrl.text) ?? 0.0,
      'categoria': _categoriaSeleccionada,
      'imagen': _imagePath,
    };

    if (_editingId == null) {
      await DatabaseHelper.instance.insertar(datos);
    } else {
      datos['id'] = _editingId;
      await DatabaseHelper.instance.actualizar(datos);
    }

    _limpiarFormulario();
    setState(() {}); // Refresca la lista de productos
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APP INVENTARIO',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 90, 230, 223),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: 10, top: 5), // Espaciado para que no pegue al borde
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DatabaseViewScreen())),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.table_chart, color: Colors.black54),
                  Text(
                    'DataBase', // Salto de línea para que no sea muy ancho
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFormulario(),
          const Divider(thickness: 2),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  // Widget que construye el formulario de entrada
  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color.fromARGB(255, 90, 230, 223))),
                  child: _imagePath == null
                      ? const Icon(Icons.add_a_photo,
                          color: Color.fromARGB(255, 0, 0, 0))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nombre del producto')),
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
                      decoration: const InputDecoration(labelText: 'Cant.'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                controller: _precioCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Precio \nUnitario'),
                textAlign: TextAlign.center,
              )),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias
                      .map((String cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _procesarDatos,
            icon: Icon(_editingId == null ? Icons.add : Icons.save),
            label: Text(_editingId == null
                ? 'Agregar al Inventario'
                : 'Guardar Cambios'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: const Color.fromARGB(255, 90, 230, 223),
                foregroundColor: Colors.white),
          ),
          if (_editingId != null)
            TextButton(
                onPressed: _limpiarFormulario,
                child: const Text('Cancelar Edición')),
        ],
      ),
    );
  }

  // Widget que construye la lista de productos registrados
  Widget _buildLista() {
    return FutureBuilder<List<Producto>>(
      future: DatabaseHelper.instance.obtenerTodos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final productos = snapshot.data!;
        if (productos.isEmpty)
          return const Center(child: Text("No hay productos registrados"));

        return ListView.builder(
          itemCount: productos.length,
          itemBuilder: (context, i) {
            final p = productos[i];
            return ListTile(
              leading: (p.imagen != null && p.imagen!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(File(p.imagen!),
                          width: 50, height: 50, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.inventory_2,
                      size: 40, color: Colors.orange),
              title: Text(p.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text("${p.categoria} | Stock: ${p.cantidad} | \$${p.precio}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _editingId = int.parse(p.id);
                          _nombreCtrl.text = p.nombre;
                          _cantidadCtrl.text = p.cantidad.toString();
                          _precioCtrl.text = p.precio.toString();
                          _imagePath = p.imagen;
                          _categoriaSeleccionada = p.categoria ?? 'Salado';
                        });
                      }),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper.instance.eliminar(int.parse(p.id));
                        setState(() {});
                      }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Pantalla para visualizar los datos técnicos (Raw)
class DatabaseViewScreen extends StatelessWidget {
  const DatabaseViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visor Técnico SQLite')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.obtenerRaw(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Categoría')),
                DataColumn(label: Text('Imagen')),
              ],
              rows: data
                  .map((row) => DataRow(cells: [
                        DataCell(Text(row['id'].toString())),
                        DataCell(Text(row['nombre'].toString())),
                        DataCell(Text(row['categoria'].toString())),
                        DataCell(
                            Text(row['imagen']?.split('/').last ?? 'Sin foto')),
                      ]))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
