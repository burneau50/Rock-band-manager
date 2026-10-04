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
                      ? 'Désactiver le mode administration'
                      : 'Activer le mode administration',
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _adminMode = !_adminMode;
                      });
                    },
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _adminMode
                            ? Colors.amber
                            : Colors.amber.withOpacity(0.75),
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
                  text: 'Récapitulatif',
                ),
                Tab(icon: Icon(Icons.event, size: 16), text: 'RDV'),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 19),
              onPressed: () => AuthService().signOut(),
              tooltip: 'Déconnexion',
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildSongsList(context),
            _buildSummaryTable(),
            _buildRepresentations(),
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
        label = 'Prêt';
        break;
      default:
        color = Colors.red;
        label = 'À apprendre';
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

        final songs = [...(snapshot.data ?? <Song>[])];

        songs.sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return bDate.compareTo(aDate);
        });

        if (songs.isEmpty) {
          return const Center(
            child: Text(
              'Aucun morceau pour l\'instant.\nClique sur le bouton pour en ajouter un !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: songs.length,
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
                                  'a_apprendre',
                                  'en_cours',
                                  'pret',
                                ].contains(statusMap[user.uid])
                                ? statusMap[user.uid]
                                : 'a_apprendre',
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
                                _statusLabel('a_apprendre'),
                                _statusLabel('en_cours'),
                                _statusLabel('pret'),
                              ];
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'a_apprendre',
                                child: _statusMenuItem(
                                  'À apprendre',
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
                                child: _statusMenuItem('Prêt', Colors.green),
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
                              tooltip: 'Écouter sur YouTube',
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
                            tooltip: 'J’aime',
                            onPressed: () {
                              _songService.toggleLike(
                                songId: song.id,
                                userId: user.uid,
                                currentlyLiked: isLiked,
                              );
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
                child: Text(
                  'Aucun morceau enregistré.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            if (userDocs.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun utilisateur trouvé.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF2C2C2C),
                  ),
                  dataRowColor: WidgetStateProperty.all(
                    const Color(0xFF1E1E1E),
                  ),
                  border: TableBorder.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                  columns: [
                    const DataColumn(
                      label: Text(
                        'Morceau',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Total pouces',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    ...userDocs.map((uDoc) {
                      final data = uDoc.data();
                      final String name = (data['displayName'] ?? 'Membre')
                          .toString();

                      return DataColumn(
                        label: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
                  ],
                  rows: songs.map((song) {
                    final String title = song.title.isEmpty
                        ? 'Sans titre'
                        : song.title;
                    final String artist = song.artist.isEmpty
                        ? 'Inconnu'
                        : song.artist;

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                artist,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.thumb_up,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${song.likes.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...userDocs.map((uDoc) {
                          final String uid = uDoc.id;
                          final List<String> learnedList =
                              song.progress[uid] ?? <String>[];
                          final String? status = song.status[uid];
                          final bool isLiked = song.likes.contains(uid);

                          if (learnedList.isEmpty &&
                              status == null &&
                              !isLiked) {
                            return const DataCell(
                              Text('-', style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (learnedList.isNotEmpty)
                                  ...instruments.entries
                                      .where(
                                        (entry) =>
                                            learnedList.contains(entry.key),
                                      )
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 6.0,
                                          ),
                                          child: FaIcon(
                                            entry.value,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                if (status != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 'pret'
                                            ? Colors.green.withOpacity(0.18)
                                            : status == 'en_cours'
                                            ? Colors.orange.withOpacity(0.18)
                                            : Colors.red.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: status == 'pret'
                                              ? Colors.green
                                              : status == 'en_cours'
                                              ? Colors.orange
                                              : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (isLiked)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 2.0),
                                    child: Icon(
                                      Icons.thumb_up,
                                      size: 15,
                                      color: Colors.amber,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
