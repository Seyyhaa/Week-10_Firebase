import '../../../model/artist/artist.dart';
 

abstract class ArtistRepository {
  Future<List<Artist>> fetchArtists({required bool forceFetch});
  
  Future<Artist?> fetchArtistById(String id);
}
