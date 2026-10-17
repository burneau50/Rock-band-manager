import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';
import '../services/song_service.dart';
import '../services/auth_service.dart';

part 'home_song_methods.dart';
part 'home_calendar_methods.dart';
part 'home_ui_methods.dart';

const Map<String, FaIconData> instruments = {
  'guitare': FontAwesomeIcons.guitar,
  'basse': FontAwesomeIcons.guitar,
  'synthe': FontAwesomeIcons.sliders,
  'batterie': FontAwesomeIcons.drum,
};

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User get user => widget.user;

  bool _adminMode = false;

  final SongService _songService = SongService();

  bool get _isAdmin => user.uid == 'i9FgMz7tKxZqKEa73SCKEa4lmQV2';

  void _toggleAdminMode() {
    setState(() {
      _adminMode = !_adminMode;
    });
  }

  @override
  Widget build(BuildContext context) => _buildHomeUi(context);

    List<String> _preferredSongOrder = [];
    bool _songOrderLoaded = false;

    @override
    void initState() {
      super.initState();
      _loadPreferredSongOrder();
    }

    Future<void> _loadPreferredSongOrder() async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(user.uid)
            .get();

        final savedOrder = doc.data()?['songOrder'];

        if (!mounted) return;

        setState(() {
          _preferredSongOrder = savedOrder is List
              ? savedOrder.whereType<String>().toList()
              : [];
          _songOrderLoaded = true;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _songOrderLoaded = true;
        });
      }
    }

    Future<void> _reorderSongs(
      List<Song> songs,
      int oldIndex,
      int newIndex,
    ) async {
     
      final reorderedSongs = List<Song>.from(songs);
      final movedSong = reorderedSongs.removeAt(oldIndex);
      reorderedSongs.insert(newIndex, movedSong);

      final newOrder = reorderedSongs.map((song) => song.id).toList();

      setState(() {
        _preferredSongOrder = newOrder;
      });

      try {
        await FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(user.uid)
            .set({
          'songOrder': newOrder,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d’enregistrer votre ordre personnel.',
            ),
          ),
        );
      }
    }
}
