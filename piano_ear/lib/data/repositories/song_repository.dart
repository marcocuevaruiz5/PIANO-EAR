import '../db/database_helper.dart';
import '../models/practice_result.dart';
import '../models/song.dart';

/// Capa de repositorio: la única parte de la app que conoce SQL. El resto
/// de la app trabaja exclusivamente con los modelos [Song]/[PracticeResult].
class SongRepository {
  final DatabaseHelper _dbHelper;

  SongRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> saveSong(Song song) async {
    final db = await _dbHelper.database;
    await db.insert('songs', song.toRow());
  }

  Future<void> renameSong(String id, String newTitle) async {
    final db = await _dbHelper.database;
    await db.update(
      'songs',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSong(String id) async {
    final db = await _dbHelper.database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
    await db.delete('practice_results', where: 'song_id = ?', whereArgs: [id]);
  }

  Future<List<Song>> fetchAllSongs() async {
    final db = await _dbHelper.database;
    final rows = await db.query('songs', orderBy: 'created_at DESC');
    return rows.map(Song.fromRow).toList();
  }

  Future<Song?> fetchSongById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Song.fromRow(rows.first);
  }

  Future<void> savePracticeResult(PracticeResult result) async {
    final db = await _dbHelper.database;
    await db.insert('practice_results', result.toRow());
  }

  Future<List<PracticeResult>> fetchPracticeHistory(String songId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'practice_results',
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'date DESC',
    );
    return rows.map(PracticeResult.fromRow).toList();
  }
}
