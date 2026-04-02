import 'package:flutter/material.dart';
import '../../../../data/repositories/artist/artist_repository.dart';
import '../../../../data/repositories/songs/song_repository.dart';
import '../../../../model/artist/artist.dart';
import '../../../states/player_state.dart';
import '../../../../model/songs/song.dart';
import '../../../utils/async_value.dart';
import 'library_item_data.dart';

class LibraryViewModel extends ChangeNotifier {
  final SongRepository songRepository;
  final ArtistRepository artistRepository;

  final PlayerState playerState;

  AsyncValue<List<LibraryItemData>> data = AsyncValue.loading();

  LibraryViewModel({
    required this.songRepository,
    required this.playerState,
    required this.artistRepository,
  }) {
    playerState.addListener(notifyListeners);

    // init
    _init();
  }

  @override
  void dispose() {
    playerState.removeListener(notifyListeners);
    super.dispose();
  }

  void _init() async {
    fetchSong();
  }

  void fetchSong({bool forceFetch = false}) async {
    if(!forceFetch){

    // 1- Loading state
    data = AsyncValue.loading();
    notifyListeners();
    }

    try {
      // 1- Fetch songs
      List<Song> songs = await songRepository.fetchSongs(
        forceFetch: forceFetch,
      );

      // 2- Fethc artist
      List<Artist> artists = await artistRepository.fetchArtists(forceFetch: forceFetch);

      // 3- Create the mapping artistid-> artist
      Map<String, Artist> mapArtist = {};
      for (Artist artist in artists) {
        mapArtist[artist.id] = artist;
      }

      List<LibraryItemData> data = songs
          .map(
            (song) =>
                LibraryItemData(song: song, artist: mapArtist[song.artistId]!),
          )
          .toList();

      this.data = AsyncValue.success(data);

    } catch (e) {
      // 3- Fetch is unsucessfull
      data = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> incrementLike(Song song) async {
    if (data.state != AsyncValueState.success) return;

    final list = data.data!;
    final index = list.indexWhere((item) => item.song.id == song.id);

    final original = list[index];

    list[index] = original.copyWith(song: song.copyWith(likes: song.likes + 1));
    data = AsyncValue.success(list);
    notifyListeners();

    try {
      await songRepository.incrementSongLikes(song.id, song.likes);
    } catch (e) {
      list[index] = original;
      data = AsyncValue.success(list);
      notifyListeners();
      throw Exception('Failed to like song. Try again.');
    }
  }

  bool isSongPlaying(Song song) => playerState.currentSong == song;

  void start(Song song) => playerState.start(song);
  void stop(Song song) => playerState.stop();
}
