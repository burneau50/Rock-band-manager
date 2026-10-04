import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';
import '../services/song_service.dart';
import '../services/auth_service.dart';

part 'home_song_methods.dart';
part 'home_representation_methods.dart';
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

  @override
  Widget build(BuildContext context) => _buildHomeUi(context);
}
