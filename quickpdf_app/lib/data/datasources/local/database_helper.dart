import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'quickpdf.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String documentsTable = 'documents';

  // Document table columns
  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnTemplateId = 'template_id';
  static const String columnFilename = 'filename';
  static const String columnContent = 'content';
  static const String columnFileUrl = 'file_url';
  static const String columnFilePath = 'file_path';
  static const String columnFileSize = 'file_size';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsSynced = 'is_synced';
  static const String columnServerId = 'server_id';
  static const String columnLastSyncAttempt = 'last_sync_attempt';

  static Database? _database;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $documentsTable (
        $columnId TEXT PRIMARY KEY,
        $columnUserId TEXT NOT NULL,
        $columnTemplateId TEXT,
        $columnFilename TEXT NOT NULL,
        $columnContent TEXT NOT NULL,
        $columnFileUrl TEXT,
        $columnFilePath TEXT,
        $columnFileSize INTEGER,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        $columnIsSynced INTEGER NOT NULL DEFAULT 0,
        $columnServerId TEXT,
        $columnLastSyncAttempt INTEGER
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_documents_user_id ON $documentsTable($columnUserId)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_documents_created_at ON $documentsTable($columnCreatedAt)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_documents_filename ON $documentsTable($columnFilename)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_documents_sync_status ON $documentsTable($columnIsSynced)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_documents_server_id ON $documentsTable($columnServerId)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}