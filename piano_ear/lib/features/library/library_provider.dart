import 'package:flutter/material.dart';
import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';

class LibraryProvider extends ChangeNotifier {
  final SongRepository _repo;
  List<Song> _songs = [];
  bool _loading = false;

  LibraryProvider({SongRepository? repo}) : _repo = repo ?? SongRepository();

  List<Song> get songs => _songs;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _songs = await _repo.fetchAllSongs();
    _loading = false;
    notifyListeners();
  }

  Future<void> rename(String id, String newTitle) async {
    await _repo.renameSong(id, newTitle);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteSong(id);
    await load();
  }
}