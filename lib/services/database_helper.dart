import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_inventario/models/producto.dart';

export 'package:app_inventario/models/producto.dart'; // Para que el main vea a Producto

class DatabaseHelper {
  // Patrón Singleton para una única instancia en toda la app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('panaderia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version:
          3, // <--- Sube el número de versión cada vez que cambies la tabla
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE productos ADD COLUMN imagen TEXT");
        }
      },
    );
  }

  // Creación de la tabla con todos los campos necesarios
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio REAL NOT NULL,
        categoria TEXT NOT NULL,
        imagen TEXT
      )
    ''');
  }

  // Si ya tenías la app y quieres añadir columnas sin borrar todo
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Si el usuario viene de la versión 1 (solo campos básicos)
    if (oldVersion < 2) {
      try {
        // Añadimos la columna categoria con un valor por defecto para no romper registros viejos
        await db.execute(
            "ALTER TABLE productos ADD COLUMN categoria TEXT DEFAULT 'Salado'");
      } catch (e) {
        print("La columna categoria ya existía: $e");
      }
    }

    // Si el usuario viene de la versión 2 (ya tenía categoría pero no imagen)
    if (oldVersion < 3) {
      try {
        // Añadimos la columna imagen
        await db.execute("ALTER TABLE productos ADD COLUMN imagen TEXT");
      } catch (e) {
        print("La columna imagen ya existía: $e");
      }
    }
  }

  // --- MÉTODOS CRUD ---

  // INSERTAR
  Future<int> insertar(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('productos', row);
  }

  // LEER TODOS (Convierte a objetos Producto)
  Future<List<Producto>> obtenerTodos() async {
    final db = await instance.database;
    final result = await db.query('productos', orderBy: 'id DESC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  // LEER RAW (Para el Visor de Tablas del main)
  Future<List<Map<String, dynamic>>> obtenerRaw() async {
    final db = await instance.database;
    return await db.query('productos');
  }

  // ACTUALIZAR
  Future<int> actualizar(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('productos', row, where: 'id = ?', whereArgs: [id]);
  }

  // ELIMINAR
  Future<int> eliminar(int id) async {
    final db = await instance.database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  // RESTAR STOCK (Lógica de venta rápida)
  Future<bool> restarStock(int id, int cantidadARestar) async {
    final db = await instance.database;
    final res = await db.query('productos', where: 'id = ?', whereArgs: [id]);

    if (res.isNotEmpty) {
      int actual = res.first['cantidad'] as int;
      if (actual >= cantidadARestar) {
        await db.update('productos', {'cantidad': actual - cantidadARestar},
            where: 'id = ?', whereArgs: [id]);
        return true;
      }
    }
    return false;
  }
}
