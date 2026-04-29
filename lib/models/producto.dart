class Producto {
  final String id;
  final String nombre;
  final int cantidad;
  final double precio;
  final String? categoria; // Nuevo campo para el Dropdown
  final String? imagen; // Nuevo campo para la ruta de la foto

  Producto({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    this.categoria,
    this.imagen,
  });

  // Este método transforma lo que devuelve SQLite (Map) en un objeto Producto
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'].toString(),
      nombre: map['nombre'] ?? 'Sin nombre',
      cantidad: map['cantidad'] ?? 0,
      precio: (map['precio'] is int)
          ? (map['precio'] as int).toDouble()
          : (map['precio'] ?? 0.0),
      categoria: map['categoria'] ?? 'General',
      imagen: map['imagen'], // Puede ser null si no hay foto
    );
  }

  // Método útil si necesitas convertir el objeto de vuelta a un Mapa
  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(id),
      'nombre': nombre,
      'cantidad': cantidad,
      'precio': precio,
      'categoria': categoria,
      'imagen': imagen,
    };
  }
}
