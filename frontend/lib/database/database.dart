import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'profile.dart';

/// A helper class to manage all database operations.
/// It handles database initialization, schema creation, upgrades, and CRUD operations
/// for the saved detection results (profiles).
class DatabaseHelper {
  // Database and Table Constants
  static const profileTable = "profiletable";
  static const dbVersion = 3;

  // Column Names
  static const idProfileColumn = "id";
  static const nameColumn = "name";
  static const image64bitColumn = "image64bit";
  static const timestampColumn = "timestamp";
  static const descriptionColumn = "description";

  /// Called when the database is first created.
  /// This function defines the initial schema for the profile table.
  static Future _onCreate(Database db, int version) async {
    await db.execute("""
    CREATE TABLE $profileTable(
      $idProfileColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $nameColumn TEXT,
      $image64bitColumn TEXT,
      $timestampColumn TEXT,
      $descriptionColumn TEXT 
    )    
    """);
  }

  /// Called when the database version is upgraded.
  /// This handles schema migrations, such as adding new columns, without losing existing data.
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // A common pattern for migrations is to check the oldVersion and apply
    // changes incrementally.
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE $profileTable ADD COLUMN $descriptionColumn TEXT",
      );
    }
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $profileTable ADD COLUMN $timestampColumn TEXT",
      );
    }
  }

  /// Opens a connection to the database.
  /// If the database does not exist, it will be created using the _onCreate callback.
  /// If the version number is higher than the existing database, _onUpgrade will be called.
  static Future<Database> open() async {
    final rootPath = await getDatabasesPath();
    final dbPath = path.join(rootPath, "flutter_onnxruntimeDb.db");
    return openDatabase(
      dbPath,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      version: dbVersion,
    );
  }

  /// Inserts a new profile (a map of data) into the database.
  static Future insertProfile(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.open();
    return await db.insert(profileTable, row);
  }

  /// Retrieves all profiles from the database.
  /// Returns a list of ProfileModel objects.
  static Future<List<ProfileModel>> getAllProfile() async {
    final db = await DatabaseHelper.open();
    List<Map<String, dynamic>> mapList = await db.query(profileTable);
    // Converts the list of maps from the database into a list of ProfileModel objects.
    return List.generate(
      mapList.length,
      (index) => ProfileModel.fromMap(mapList[index]),
    );
  }

  /// Deletes an item from the database based on its [id].
  static Future<int> deleteItem(int id) async {
    final db = await DatabaseHelper.open();
    return await db.delete(
      profileTable,
      where: '$idProfileColumn = ?',
      whereArgs: [id],
    );
  }
}
