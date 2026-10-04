part of 'home_screen.dart';

extension _HomeSongMethods on _HomeScreenState {

  Future<void> _setSongStatus(String docId, String status) async {
    await _songService.setUserStatus(
      songId: docId,
      userId: user.uid,
      status: status,
    );
  }

  Future _editSong(
    BuildContext context,
    String docId,
    String currentTitle,
    String currentArtist,
    String currentYoutubeUrl,
    String currentSongsterrUrl,
  ) async {
    final titleController = TextEditingController(text: currentTitle);
    final artistController = TextEditingController(text: currentArtist);
    final youtubeController = TextEditingController(text: currentYoutubeUrl);
    final songsterrController = TextEditingController(
      text: currentSongsterrUrl,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le morceau'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  prefixIcon: Icon(Icons.music_note),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(
                  labelText: 'Artiste',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: youtubeController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Lien YouTube',
                  prefixIcon: Icon(Icons.video_library),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: songsterrController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Lien Songsterr (optionnel)',
                  hintText: 'https://www.songsterr.com/...',
                  prefixIcon: Icon(Icons.library_music),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final artist = artistController.text.trim();
              final youtubeUrl = youtubeController.text.trim();
              final songsterrUrl = songsterrController.text.trim();

              if (title.isEmpty || artist.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le titre et l’artiste sont obligatoires.'),
                  ),
                );
                return;
              }

              await _songService.updateSong(
                songId: docId,
                title: title,
                artist: artist,
                youtubeUrl: youtubeUrl,
                songsterrUrl: songsterrUrl,
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    titleController.dispose();
    artistController.dispose();
    youtubeController.dispose();
    songsterrController.dispose();

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morceau modifié avec succès.')),
      );
    }
  }

  Future<void> _toggleInstrument(
    String docId,
    List currentLearned,
    String key,
  ) async {
    final List<String> updated = currentLearned.cast<String>().toList();

    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }

    await _songService.setUserProgress(
      songId: docId,
      userId: user.uid,
      instruments: updated,
    );
  }

  Widget _buildInstrumentSelector(
    String docId,
    List userLearned,
    BuildContext context,
  ) {
    final selectedEntries = instruments.entries
        .where((entry) => userLearned.contains(entry.key))
        .toList();

    return PopupMenuButton<String>(
      tooltip: 'Choisir les instruments',
      color: const Color(0xFF2C2C2C),
      onSelected: (key) => _toggleInstrument(docId, userLearned, key),
      itemBuilder: (context) {
        return instruments.entries.map((entry) {
          final selected = userLearned.contains(entry.key);
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  entry.value,
                  size: 16,
                  color: selected ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  entry.key == 'synthe'
                      ? 'Synthé'
                      : '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  selected ? Icons.check : Icons.add,
                  size: 17,
                  color: selected ? Colors.amber : Colors.grey,
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedEntries.isEmpty)
            const Icon(Icons.tune, size: 18, color: Colors.grey)
          else
            ...selectedEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FaIcon(entry.value, size: 17, color: Colors.amber),
              ),
            ),
          const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Future _openYoutubeLink(String urlString, BuildContext context) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lien YouTube invalide')));
      }
    }
  }

  Future _openSongsterrLink(String urlString, BuildContext context) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien Songsterr invalide')),
        );
      }
    }
  }


  void _showAddSongDialog(BuildContext context) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final youtubeController = TextEditingController();
    final songsterrController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Ajouter un morceau'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre du morceau'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(labelText: 'Artiste / Groupe'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: youtubeController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Lien YouTube (optionnel)',
                hintText: 'https://www.youtube.com/watch?v=...',
                prefixIcon: Icon(Icons.video_library),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: songsterrController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Lien Songsterr (optionnel)',
                hintText: 'https://www.songsterr.com/...',
                prefixIcon: Icon(Icons.library_music),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              final title = titleController.text.trim();
              final artist = artistController.text.trim();
              final youtubeUrl = youtubeController.text.trim();
              final songsterrUrl = songsterrController.text.trim();

              if (title.isNotEmpty && artist.isNotEmpty) {
                await _songService.addSong(
                  title: title,
                  artist: artist,
                  youtubeUrl: youtubeUrl,
                  songsterrUrl: songsterrUrl,
                  addedBy: user.uid,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSongDetailsDialog(
    BuildContext context,
    String title,
    String artist,
    List likes,
    Map progressMap,
  ) {
    final Set allUserIds = {...likes.cast(), ...progressMap.keys.cast()};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              artist,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(color: Colors.amber, height: 20),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: allUserIds.isEmpty
              ? const Text(
                  'Aucun membre n\'a encore donné son avis.',
                  style: TextStyle(color: Colors.grey),
                )
              : FutureBuilder(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, snapshot) {
                    Map userNames = {};
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map;
                        userNames[doc.id] = data['displayName'] ?? 'Membre';
                      }
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: allUserIds.length,
                      itemBuilder: (context, index) {
                        final uid = allUserIds.elementAt(index);
                        final bool hasLiked = likes.contains(uid);
                        final dynamic rawProg = progressMap[uid];
                        final List userLearned = rawProg is List ? rawProg : [];
                        final bool isCurrentUser = uid == user.uid;

                        final String memberName = isCurrentUser
                            ? 'Moi'
                            : (userNames[uid] ??
                                  'Membre (${uid.substring(0, 4)})');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  memberName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUser
                                        ? Colors.amber
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                hasLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 18,
                                color: hasLiked ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              if (userLearned.isNotEmpty)
                                Row(
                                  children: instruments.entries
                                      .where(
                                        (entry) =>
                                            userLearned.contains(entry.key),
                                      )
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2.0,
                                          ),
                                          child: FaIcon(
                                            entry.value,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
