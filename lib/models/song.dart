import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String youtubeUrl;
  final String songsterrUrl;
  final String addedBy;
  final List<String> likes;
  final Map<String, List<String>> progress;
  final Map<String, String> status;
  final DateTime? createdAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeUrl,
    required this.songsterrUrl,
    required this.addedBy,
    required this.likes,
    required this.progress,
    required this.status,
    required this.createdAt,
  });

  factory Song.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Le document Firestore ${document.id} ne contient aucune donnée.',
      );
    }

    // ------------------------------------------------------------
    // LIKES
    // ------------------------------------------------------------
    //
    // Firestore peut nous retourner un tableau dynamique sur le Web.
    // On reconstruit donc explicitement un List<String>.
    //
    final List<String> likes = <String>[];

    final dynamic rawLikes = data['likes'];

    if (rawLikes is Iterable) {
      for (final value in rawLikes) {
        if (value is String) {
          likes.add(value);
        }
      }
    }

    // ------------------------------------------------------------
    // PROGRESS
    // ------------------------------------------------------------
    //
    // Structure Firestore :
    //
    // progress: {
    //   "uid_utilisateur": ["guitare", "basse"]
    // }
    //
    // Chaque tableau est reconstruit explicitement en List<String>.
    //
    final Map<String, List<String>> progress = <String, List<String>>{};

    final dynamic rawProgress = data['progress'];

    if (rawProgress is Map) {
      for (final entry in rawProgress.entries) {
        final String userId = entry.key.toString();
        final dynamic rawInstruments = entry.value;

        final List<String> instruments = <String>[];

        if (rawInstruments is Iterable) {
          for (final instrument in rawInstruments) {
            if (instrument is String) {
              instruments.add(instrument);
            }
          }
        }

        progress[userId] = instruments;
      }
    }

    // ------------------------------------------------------------
    // STATUS
    // ------------------------------------------------------------

    final Map<String, String> status = <String, String>{};

    final dynamic rawStatus = data['status'];

    if (rawStatus is Map) {
      for (final entry in rawStatus.entries) {
        final String userId = entry.key.toString();
        final dynamic value = entry.value;

        if (value is String) {
          status[userId] = value;
        }
      }
    }

    // ------------------------------------------------------------
    // DATE DE CREATION
    // ------------------------------------------------------------

    DateTime? createdAt;

    final dynamic rawCreatedAt = data['createdAt'];

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    }

    return Song(
      id: document.id,
      title: (data['title'] ?? '').toString(),
      artist: (data['artist'] ?? '').toString(),
      youtubeUrl: (data['youtubeUrl'] ?? '').toString(),
      songsterrUrl: (data['songsterrUrl'] ?? '').toString(),
      addedBy: (data['addedBy'] ?? '').toString(),
      likes: List<String>.unmodifiable(likes),
      progress: Map<String, List<String>>.unmodifiable(
        progress.map(
          (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
        ),
      ),
      status: Map<String, String>.unmodifiable(status),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'youtubeUrl': youtubeUrl,
      'songsterrUrl': songsterrUrl,
      'addedBy': addedBy,
      'likes': List<String>.from(likes),
      'progress': progress.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      'status': Map<String, String>.from(status),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? youtubeUrl,
    String? songsterrUrl,
    String? addedBy,
    List<String>? likes,
    Map<String, List<String>>? progress,
    Map<String, String>? status,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      songsterrUrl: songsterrUrl ?? this.songsterrUrl,
      addedBy: addedBy ?? this.addedBy,
      likes: likes ?? this.likes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
