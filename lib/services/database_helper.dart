import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_inventario/models/producto.dart';

export 'package:app_inventario/models/producto.dart'; // Para que el main vea a Producto

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;
  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_inventario.db'); //
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL, 
        stock INTEGER NOT NULL, 
        price REAL NOT NULL, 
        category TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  // HU01 & HU03: Guardar y Editar
  Future<int> upsert(Product p) async {
    final db = await instance.database;
    if (p.id == null) return await db.insert('products', p.toMap());
    return await db
        .update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  // HU06: Eliminación permanente
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAll() async {
    final db = await instance.database;
    final res = await db.query('products', orderBy: 'name ASC');
    return res.map((e) => Product.fromMap(e)).toList();
  }
}
