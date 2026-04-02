import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../model/songs/song.dart';
import '../../dtos/song_dto.dart';
import 'song_repository.dart';

class SongRepositoryFirebase extends SongRepository {
  static final Uri baseUri = Uri.https(
    'seyha-learn-first-firebase-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
  final Uri songsUri = baseUri.replace(path: '/songs.json');

  List<Song>? _cachedSongs;

  @override
  Future<List<Song>> fetchSongs({bool forceFetch = false}) async {
    if (_cachedSongs != null && !forceFetch) {
      return _cachedSongs!;
    }
    final http.Response response = await http.get(songsUri);

    if (response.statusCode == 200) {
      // 1 - Send the retrieved list of songs
      Map<String, dynamic> songJson = json.decode(response.body);

      List<Song> result = [];
      for (final entry in songJson.entries) {
        result.add(SongDto.fromJson(entry.key, entry.value));
      }
      _cachedSongs = result;
      return result;
    } else {
      // 2- Throw expcetion if any issue
      throw Exception('Failed to load posts');
    }
  }

  @override
  Future<Song?> fetchSongById(String id) async {}

  @override
  Future<void> incrementSongLikes(String songId, int currentLikes) async {
    final Uri updateUri = baseUri.replace(path: '/songs/$songId.json');
    final int newLikes = currentLikes + 1;

    final response = await http.patch(
      updateUri,
      body: json.encode({SongDto.likeKey: newLikes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update likes for song: $songId');
    }
    _cachedSongs = null;
  }
}
