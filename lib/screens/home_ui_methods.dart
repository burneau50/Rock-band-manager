part of 'home_screen.dart';

extension _HomeUiMethods on _HomeScreenState {

  Widget _buildHomeUi(BuildContext context) {

    return DefaultTabController(

      length: 3,

      child: Scaffold(

        appBar: AppBar(

          toolbarHeight: 62,

          titleSpacing: 12,

          title: Row(

            children: [

              const Flexible(

                child: Text(

                  'Rock Band Manager',

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),

                ),

              ),

              if (_isAdmin) ...[

                const SizedBox(width: 6),

                Tooltip(

                  message: _adminMode

                      ? 'DÃ©sactiver le mode administration'

                      : 'Activer le mode administration',

                  child: InkWell(

                    onTap: _toggleAdminMode,

                    borderRadius: BorderRadius.circular(5),

                    child: Container(

                      padding: const EdgeInsets.symmetric(

                        horizontal: 7,

                        vertical: 2,

                      ),

                      decoration: BoxDecoration(

                        color: _adminMode

                            ? Colors.amber

                            : Colors.amber.withValues(alpha: 0.75),

                        borderRadius: BorderRadius.circular(5),

                        border: Border.all(color: Colors.amber, width: 1),

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Icon(

                            _adminMode

                                ? Icons.admin_panel_settings

                                : Icons.admin_panel_settings_outlined,

                            color: Colors.black,

                            size: 13,

                          ),

                          const SizedBox(width: 3),

                          const Text(

                            'ADMIN',

                            style: TextStyle(

                              color: Colors.black,

                              fontSize: 9,

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ],

              const SizedBox(width: 5),

              Tooltip(

                message: 'Ajouter un morceau',

                child: InkWell(

                  onTap: () => _showAddSongDialog(context),

                  borderRadius: BorderRadius.circular(16),

                  child: Container(

                    width: 28,

                    height: 28,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      border: Border.all(color: Colors.amber, width: 1.5),

                    ),

                    child: const Icon(Icons.add, color: Colors.amber, size: 18),

                  ),

                ),

              ),

              if (_isAdmin && _adminMode) ...[
                const SizedBox(width: 5),
                Tooltip(
                  message: 'Retirer tous les likes dâ€™un utilisateur',
                  child: InkWell(
                    onTap: () => _showClearUserLikesDialog(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],

            ],

          ),

          bottom: const PreferredSize(

            preferredSize: Size.fromHeight(34),

            child: TabBar(

              indicatorColor: Colors.amber,

              labelColor: Colors.amber,

              unselectedLabelColor: Colors.grey,

              labelStyle: TextStyle(fontSize: 10),

              unselectedLabelStyle: TextStyle(fontSize: 10),

              labelPadding: EdgeInsets.symmetric(horizontal: 4),

              tabs: [

                Tab(icon: Icon(Icons.music_note, size: 16), text: 'Morceaux'),

                Tab(

                  icon: Icon(Icons.table_chart, size: 16),

                  text: 'RÃ©capitulatif',

                ),

                Tab(icon: Icon(Icons.calendar_month, size: 16), text: 'Calendrier'),

              ],

            ),

          ),

          actions: [

            IconButton(

              icon: const Icon(Icons.logout, size: 19),

              onPressed: () => AuthService().signOut(),

              tooltip: 'DÃ©connexion',

              padding: const EdgeInsets.symmetric(horizontal: 8),

              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),

            ),

          ],

        ),

        body: TabBarView(

          children: [

            _buildSongsList(context),

            _buildSummaryTable(),

            _buildCalendarUi(context),

          ],

        ),

      ),

    );

  }

  Widget _statusMenuItem(String label, Color color) {

    return Row(

      mainAxisSize: MainAxisSize.min,

      children: [

        Container(

          width: 9,

          height: 9,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),

        ),

        const SizedBox(width: 7),

        Text(label),

      ],

    );

  }

  Widget _statusLabel(String status) {

    final Color color;

    final String label;

    switch (status) {

      case 'en_cours':

        color = Colors.orange;

        label = 'En cours';

        break;

      case 'pret':

        color = Colors.green;

        label = 'PrÃªt';

        break;

      default:

        color = Colors.red;

        label = 'Ã _apprendre';

    }

    return Align(

      alignment: Alignment.centerRight,

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Container(

            width: 8,

            height: 8,

            decoration: BoxDecoration(color: color, shape: BoxShape.circle),

          ),

          const SizedBox(width: 4),

          Text(

            label,

            style: const TextStyle(color: Colors.white, fontSize: 10),

          ),

        ],

      ),

    );

  }


  Future<void> _showClearUserLikesDialog(BuildContext context) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      if (!context.mounted) return;

      if (usersSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun utilisateur trouvÃ©.')),
        );
        return;
      }

      final users = [...usersSnapshot.docs]..sort((a, b) {
        String label(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final data = doc.data();
          return (data['displayName'] ?? data['name'] ?? data['email'] ?? doc.id)
              .toString()
              .toLowerCase();
        }

        return label(a).compareTo(label(b));
      });

      final selectedUser = await showDialog<QueryDocumentSnapshot<Map<String, dynamic>>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Retirer les likes'),
          content: SizedBox(
            width: 420,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data();
                  final name = (data['displayName'] ?? data['name'] ?? '')
                      .toString()
                      .trim();
                  final email = (data['email'] ?? '').toString().trim();
                  final title = name.isNotEmpty
                      ? name
                      : (email.isNotEmpty ? email : doc.id);

                  return ListTile(
                    leading: const Icon(Icons.person_outline, color: Colors.amber),
                    title: Text(title, style: const TextStyle(color: Colors.white)),
                    subtitle: email.isNotEmpty && email != title
                        ? Text(email, style: const TextStyle(color: Colors.grey))
                        : null,
                    onTap: () => Navigator.of(dialogContext).pop(doc),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );

      if (selectedUser == null || !context.mounted) return;

      final userData = selectedUser.data();
      final userName = (userData['displayName'] ?? userData['name'] ??
              userData['email'] ?? selectedUser.id)
          .toString();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Retirer tous les likes de Â« $userName Â» sur tous les morceaux ?\n\nCette action ne peut pas Ãªtre annulÃ©e.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Retirer les likes'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final songsSnapshot = await FirebaseFirestore.instance
          .collection('songs')
          .get();
      final targetUid = selectedUser.id;
      final matchingSongs = songsSnapshot.docs.where((doc) {
        final likes = doc.data()['likes'];
        return likes is List && likes.contains(targetUid);
      }).toList();

      // Firestore limite un batch Ã  500 opÃ©rations : on utilise des lots de 450.
      for (var start = 0; start < matchingSongs.length; start += 450) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (start + 450 < matchingSongs.length)
            ? start + 450
            : matchingSongs.length;
        for (final doc in matchingSongs.sublist(start, end)) {
          batch.update(doc.reference, {
            'likes': FieldValue.arrayRemove([targetUid]),
          });
        }
        await batch.commit();
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            matchingSongs.isEmpty
                ? 'Cet utilisateur nï¿½?Tavait aucun like.'
                : '${matchingSongs.length} like(s) retirÃ©(s) pour $userName.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du retrait des likes : $e')),
      );
    }
  }

  Future<void> _toggleLikeWithLimit(
    BuildContext context,
    Song song,
    bool currentlyLiked,
  ) async {
    try {
      // Retirer un like reste toujours autorisÃ©, mÃªme Ã  la limite.
      if (currentlyLiked) {
        await _songService.toggleLike(
          songId: song.id,
          userId: user.uid,
          currentlyLiked: true,
        );
        return;
      }

      // Compte les morceaux dÃ©jÃ  aimÃ©s par cet utilisateur.
      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .get();

      final likedSongsCount = snapshot.docs.where((doc) {
        final likes = doc.data()['likes'];
        return likes is List && likes.contains(user.uid);
      }).length;

      if (likedSongsCount >= 8) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu as atteint la limite de 8 likes. '
              'Retire un like avant dâ€™en ajouter un autre.',
            ),
          ),
        );
        return;
      }

      await _songService.toggleLike(
        songId: song.id,
        userId: user.uid,
        currentlyLiked: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier ce like.'),
        ),
      );
    }
  }

  Widget _buildSongsList(BuildContext context) {

    return StreamBuilder<List<Song>>(

      stream: _songService.watchSongs(),

      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {

          return const Center(child: CircularProgressIndicator());

        }

        if (snapshot.hasError) {

          return Center(

            child: Text(

              'Erreur de chargement des morceaux.\n${snapshot.error}',

              textAlign: TextAlign.center,

              style: const TextStyle(color: Colors.redAccent),

            ),

          );

        }

        var songs = [...(snapshot.data ?? <Song>[])];

        songs.sort((a, b) {

          final aDate = a.createdAt;

          final bDate = b.createdAt;

          if (aDate == null && bDate == null) return 0;

          if (aDate == null) return 1;

          if (bDate == null) return -1;

          return bDate.compareTo(aDate);

        });

        if (!_songOrderLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        // Applique l'ordre personnel enregistrÃ© pour cet utilisateur.
        final songsById = <String, Song>{
          for (final song in songs) song.id: song,
        };
        final orderedSongs = <Song>[];

        for (final id in _preferredSongOrder) {
          final song = songsById.remove(id);
          if (song != null) {
            orderedSongs.add(song);
          }
        }

        // Les nouveaux morceaux sont ajoutÃ©s Ã  la fin sans effacer
        // l'ordre personnalisÃ© dÃ©jÃ  enregistrÃ©.
        for (final song in songs) {
          final remainingSong = songsById.remove(song.id);
          if (remainingSong != null) {
            orderedSongs.add(remainingSong);
          }
        }

        songs = orderedSongs;

        if (songs.isEmpty) {

          return const Center(

            child: Text(

              'Aucun morceau pour l\'instant.\nClique sur le bouton pour en ajouter un !',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey, fontSize: 16),

            ),

          );

        }

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: songs.length,
          onReorderItem: (oldIndex, newIndex) {
            _reorderSongs(
              songs,
              oldIndex,
              newIndex + (newIndex > oldIndex ? 1 : 0),
            );
          },
          itemBuilder: (context, index) {

            final song = songs[index];

            final String title = song.title.isEmpty ? 'Sans titre' : song.title;

            final String artist = song.artist.isEmpty ? 'Inconnu' : song.artist;

            final String youtubeUrl = song.youtubeUrl;

            final String songsterrUrl = song.songsterrUrl;

            final List<String> likes = song.likes;

            final Map<String, List<String>> progressMap = song.progress;

            final Map<String, String> statusMap = song.status;

            final bool isLiked = likes.contains(user.uid);

            final List<String> userLearned =

                progressMap[user.uid] ?? <String>[];

            return Card(
              key: ValueKey(song.id),
              color: const Color(0xFF1E1E1E),

              margin: const EdgeInsets.only(bottom: 10),

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(12),

              ),

              child: InkWell(

                borderRadius: BorderRadius.circular(12),

                onTap: () => _showSongDetailsDialog(

                  context,

                  title,

                  artist,

                  likes,

                  progressMap,

                ),

                child: Padding(

                  padding: const EdgeInsets.fromLTRB(12, 9, 8, 8),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Row(

                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.drag_indicator,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          ),

                          Expanded(

                            child: Text(

                              title,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(

                                fontSize: 17,

                                fontWeight: FontWeight.bold,

                                color: Colors.white,

                              ),

                            ),

                          ),

                          const SizedBox(width: 4),

                          DropdownButton<String>(

                            value:

                                <String>[

                                  'Ã _apprendre',

                                  'en_cours',

                                  'pret',

                                ].contains(statusMap[user.uid])

                                ? statusMap[user.uid]

                                : 'Ã _apprendre',

                            dropdownColor: const Color(0xFF2C2C2C),

                            underline: const SizedBox.shrink(),

                            isDense: true,

                            icon: const Icon(

                              Icons.arrow_drop_down,

                              color: Colors.grey,

                              size: 18,

                            ),

                            style: const TextStyle(

                              color: Colors.white,

                              fontSize: 11,

                            ),

                            selectedItemBuilder: (context) {

                              return [

                                _statusLabel('Ã _apprendre'),

                                _statusLabel('en_cours'),

                                _statusLabel('pret'),

                              ];

                            },

                            items: [

                              DropdownMenuItem(

                                value: 'Ã _apprendre',

                                child: _statusMenuItem(

                                  'Ã _apprendre',

                                  Colors.red,

                                ),

                              ),

                              DropdownMenuItem(

                                value: 'en_cours',

                                child: _statusMenuItem(

                                  'En cours',

                                  Colors.orange,

                                ),

                              ),

                              DropdownMenuItem(

                                value: 'pret',

                                child: _statusMenuItem('PrÃªt', Colors.green),

                              ),

                            ],

                            onChanged: (newStatus) {

                              if (newStatus != null) {

                                _setSongStatus(song.id, newStatus);

                              }

                            },

                          ),

                          if (_isAdmin && _adminMode)

                            IconButton(

                              tooltip: 'Modifier le morceau',

                              icon: const Icon(Icons.edit, size: 18),

                              padding: const EdgeInsets.all(4),

                              constraints: const BoxConstraints(

                                minWidth: 30,

                                minHeight: 30,

                              ),

                              onPressed: () => _editSong(

                                context,

                                song.id,

                                title,

                                artist,

                                youtubeUrl,

                                songsterrUrl,

                              ),

                            ),

                          if (_isAdmin && _adminMode)

                            IconButton(

                              tooltip: 'Supprimer le morceau',

                              icon: const Icon(

                                Icons.delete_outline,

                                color: Colors.redAccent,

                                size: 19,

                              ),

                              padding: const EdgeInsets.all(4),

                              constraints: const BoxConstraints(

                                minWidth: 30,

                                minHeight: 30,

                              ),

                              onPressed: () async {

                                final confirm = await showDialog<bool>(

                                  context: context,

                                  builder: (ctx) => AlertDialog(

                                    backgroundColor: const Color(0xFF2C2C2C),

                                    title: const Text('Supprimer ce morceau ?'),

                                    actions: [

                                      TextButton(

                                        onPressed: () =>

                                            Navigator.pop(ctx, false),

                                        child: const Text('Annuler'),

                                      ),

                                      ElevatedButton(

                                        style: ElevatedButton.styleFrom(

                                          backgroundColor: Colors.redAccent,

                                        ),

                                        onPressed: () =>

                                            Navigator.pop(ctx, true),

                                        child: const Text('Supprimer'),

                                      ),

                                    ],

                                  ),

                                );

                                if (confirm == true) {

                                  await _songService.deleteSong(song.id);

                                }

                              },

                            ),

                        ],

                      ),

                      Row(

                        children: [

                          Expanded(

                            child: Text(

                              artist,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(

                                color: Colors.grey,

                                fontSize: 13,

                              ),

                            ),

                          ),

                          _buildInstrumentSelector(

                            song.id,

                            userLearned,

                            context,

                          ),

                          if (youtubeUrl.isNotEmpty)

                            IconButton(

                              padding: const EdgeInsets.all(3),

                              constraints: const BoxConstraints(

                                minWidth: 27,

                                minHeight: 27,

                              ),

                              icon: const Icon(

                                Icons.play_circle_fill,

                                color: Colors.red,

                                size: 22,

                              ),

                              tooltip: 'Ã‰couter sur YouTube',

                              onPressed: () =>

                                  _openYoutubeLink(youtubeUrl, context),

                            ),

                          if (songsterrUrl.isNotEmpty)

                            IconButton(

                              padding: const EdgeInsets.all(3),

                              constraints: const BoxConstraints(

                                minWidth: 27,

                                minHeight: 27,

                              ),

                              icon: const Icon(

                                Icons.library_music,

                                color: Colors.amber,

                                size: 21,

                              ),

                              tooltip: 'Ouvrir sur Songsterr',

                              onPressed: () =>

                                  _openSongsterrLink(songsterrUrl, context),

                            ),

                          IconButton(

                            padding: const EdgeInsets.all(3),

                            constraints: const BoxConstraints(

                              minWidth: 27,

                              minHeight: 27,

                            ),

                            icon: Icon(

                              isLiked

                                  ? Icons.thumb_up

                                  : Icons.thumb_up_outlined,

                              color: isLiked ? Colors.amber : Colors.grey,

                              size: 20,

                            ),

                            tooltip: 'Jâ€™aime',

                            onPressed: () {
                              _toggleLikeWithLimit(context, song, isLiked);
                            },

                          ),

                          Text(

                            '${likes.length}',

                            style: const TextStyle(

                              color: Colors.grey,

                              fontSize: 11,

                            ),

                          ),

                        ],

                      ),

                    ],

                  ),

                ),

              ),

            );

          },

        );

      },

    );

  }

  Widget _buildSummaryTable() {
    return StreamBuilder<List<Song>>(
      stream: _songService.watchSongs(),
      builder: (context, songSnapshot) {
        if (songSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (songSnapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement des morceaux.\n${songSnapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final songs = [...(songSnapshot.data ?? <Song>[])];
            final userDocs = userSnapshot.data?.docs ?? [];
            songs.sort((a, b) => b.likes.length.compareTo(a.likes.length));
            if (songs.isEmpty) {
              return const Center(
                child: Text('Aucun morceau enregistrÃ©.', style: TextStyle(color: Colors.grey)),
              );
            }
            if (userDocs.isEmpty) {
              return const Center(
                child: Text('Aucun utilisateur trouvÃ©.', style: TextStyle(color: Colors.grey)),
              );
            }
            return _PersonalizableSummaryTable(
              songs: songs,
              userDocs: userDocs,
              instruments: instruments,
              userId: user.uid,
            );
          },
        );
      },
    );
  }

}

/// Tableau rÃ©capitulatif avec ordre des colonnes enregistrÃ© individuellement.
class _PersonalizableSummaryTable extends StatefulWidget {
  const _PersonalizableSummaryTable({
    required this.songs,
    required this.userDocs,
    required this.instruments,
    required this.userId,
  });

  final List<Song> songs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs;
  final Map<String, dynamic> instruments;
  final String userId;

  @override
  State<_PersonalizableSummaryTable> createState() => _PersonalizableSummaryTableState();
}

class _PersonalizableSummaryTableState extends State<_PersonalizableSummaryTable> {
  static const double _songWidth = 230;
  static const double _totalWidth = 55;
  static const double _userWidth = 103;

  List<String> _userOrder = [];
  bool _orderLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(widget.userId)
          .get();
      final saved = doc.data()?['summaryUserOrder'];
      final availableIds = widget.userDocs.map((d) => d.id).toSet();
      final ordered = <String>[];
      if (saved is List) {
        for (final id in saved) {
          if (id is String && availableIds.contains(id) && !ordered.contains(id)) {
            ordered.add(id);
          }
        }
      }
      for (final doc in widget.userDocs) {
        if (!ordered.contains(doc.id)) ordered.add(doc.id);
      }
      if (!mounted) return;
      setState(() {
        _userOrder = ordered;
        _orderLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userOrder = widget.userDocs.map((d) => d.id).toList();
        _orderLoaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger lï¿½?Tordre des colonnes.')),
      );
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(widget.userId)
          .set({
        'summaryUserOrder': _userOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible dï¿½?Tenregistrer lï¿½?Tordre des colonnes.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _moveUser(String draggedId, String targetId) {
    if (draggedId == targetId) return;
    final next = List<String>.from(_userOrder);
    final oldIndex = next.indexOf(draggedId);
    final newIndex = next.indexOf(targetId);
    if (oldIndex < 0 || newIndex < 0) return;
    next.removeAt(oldIndex);
    next.insert(newIndex, draggedId);
    setState(() => _userOrder = next);
    _saveOrder();
  }

  @override
  Widget build(BuildContext context) {
    if (!_orderLoaded) return const Center(child: CircularProgressIndicator());
    final usersById = {for (final doc in widget.userDocs) doc.id: doc};
    final orderedDocs = _userOrder
        .where(usersById.containsKey)
        .map((id) => usersById[id]!)
        .toList();

    Widget headerCell(String text, double width, {bool amber = false}) => Container(
      width: width,
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: amber ? Colors.amber : Colors.white)),
    );

    Widget dataCell(double width, Widget child) => Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_saving)
          const LinearProgressIndicator(minHeight: 2, color: Colors.amber),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      headerCell('', _totalWidth, amber: true),
                      headerCell('Morceau', _songWidth, amber: true),
                      ...orderedDocs.map((doc) {
                        final name = (doc.data()['displayName'] ?? 'Membre').toString();
                        return DragTarget<String>(
                          onWillAcceptWithDetails: (details) => details.data != doc.id,
                          onAcceptWithDetails: (details) => _moveUser(details.data, doc.id),
                          builder: (context, candidates, rejected) => Draggable<String>(
                            data: doc.id,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: _userWidth,
                                child: headerCell(name, _userWidth),
                              ),
                            ),
                            childWhenDragging: Container(
                              width: _userWidth,
                              height: 52,
                              color: Colors.amber.withValues(alpha: 0.12),
                            ),
                            child: Container(
                              width: _userWidth,
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: candidates.isNotEmpty
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : const Color(0xFF2C2C2C),
                                border: Border.all(color: Colors.grey.shade800, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.drag_indicator, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  ...widget.songs.map((song) {
                    final title = song.title.isEmpty ? 'Sans titre' : song.title;
                    final artist = song.artist.isEmpty ? 'Inconnu' : song.artist;
                    return Row(
                      // Le contenu du tableau est dans un dÃ©filement vertical :
                      // ne pas Ã©tirer les cellules sur une hauteur non bornÃ©e.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dataCell(_totalWidth, Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.thumb_up, size: 16, color: Colors.amber),
                          const SizedBox(width: 5),
                          Text('${song.likes.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ])),
                        dataCell(_songWidth, Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(artist, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )),
                        ...orderedDocs.map((doc) {
                          final uid = doc.id;
                          final learnedList = song.progress[uid] ?? <String>[];
                          final status = song.status[uid];
                          final isLiked = song.likes.contains(uid);
                          if (learnedList.isEmpty && status == null && !isLiked) {
                            return dataCell(_userWidth, const Text('-', style: TextStyle(color: Colors.grey)));
                          }
                          return dataCell(_userWidth, Wrap(
                            spacing: 5,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...widget.instruments.entries
                                  .where((entry) => learnedList.contains(entry.key))
                                  .map((entry) => FaIcon(entry.value, size: 14, color: Colors.amber)),
                              if (status != null)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status == 'pret' ? Colors.green : status == 'en_cours' ? Colors.orange : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (isLiked) const Icon(Icons.thumb_up, size: 15, color: Colors.amber),
                            ],
                          ));
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}



