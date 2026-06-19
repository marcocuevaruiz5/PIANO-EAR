import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

/// Acceso de bajo nivel a la base de datos SQLite local. Una sola tabla
/// `songs` guarda los metadatos de cada interpretación; las notas se
/// almacenan serializadas como JSON en la columna `notes_json` (ver
/// [Song.toRow]/[Song.fromRow]). Para el alcance de esta app esto es más
/// simple y suficientemente rápido que normalizar una tabla `notes`
/// separada, y evita N+1 queries al cargar la biblioteca.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, AppConstants.dbName);

    return openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            duration_ms INTEGER NOT NULL,
            tempo_bpm REAL NOT NULL,
            ts_num INTEGER NOT NULL,
            ts_den INTEGER NOT NULL,
            key_signature TEXT,
            audio_path TEXT,
            notes_json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE practice_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id TEXT NOT NULL,
            date TEXT NOT NULL,
            correct INTEGER NOT NULL,
            wrong INTEGER NOT NULL,
            missed INTEGER NOT NULL,
            total_expected INTEGER NOT NULL,
            FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}
