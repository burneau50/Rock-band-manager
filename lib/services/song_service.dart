import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/song.dart';

class SongService {
  final FirebaseFirestore _firestore;

  SongService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _songsCollection {
    return _firestore.collection('songs');
  }

  Stream<List<Song>> watchSongs() {
    return _songsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map(Song.fromFirestore).toList(growable: false);
    });
  }

  Future<Song> addSong({
    required String title,
    required String artist,
    required String youtubeUrl,
    required String songsterrUrl,
    required String addedBy,
  }) async {
    final documentReference = await _songsCollection.add({
      'title': title,
      'artist': artist,
      'youtubeUrl': youtubeUrl,
      'songsterrUrl': songsterrUrl,
      'addedBy': addedBy,
      'likes': <String>[],
      'progress': <String, dynamic>{},
      'status': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    final document = await documentReference.get();

    return Song.fromFirestore(document);
  }

  Future<void> updateSong({
    required String songId,
    required String title,
    required String artist,
    required String youtubeUrl,
    required String songsterrUrl,
  }) async {
    await _songsCollection.doc(songId).update({
      'title': title,
      'artist': artist,
      'youtubeUrl': youtubeUrl,
      'songsterrUrl': songsterrUrl,
    });
  }

  Future<void> deleteSong(String songId) async {
    await _songsCollection.doc(songId).delete();
  }

  Future<void> setUserProgress({
    required String songId,
    required String userId,
    required List<String> instruments,
  }) async {
    await _songsCollection.doc(songId).update({
      'progress.$userId': instruments,
    });
  }

  Future<void> setUserStatus({
    required String songId,
    required String userId,
    required String status,
  }) async {
    await _songsCollection.doc(songId).update({'status.$userId': status});
  }

  Future<void> addLike({required String songId, required String userId}) async {
    await _songsCollection.doc(songId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeLike({
    required String songId,
    required String userId,
  }) async {
    await _songsCollection.doc(songId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> toggleLike({
    required String songId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      await removeLike(songId: songId, userId: userId);
    } else {
      await addLike(songId: songId, userId: userId);
    }
  }
}
