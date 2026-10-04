part of 'home_screen.dart';

extension _HomeRepresentationMethods on _HomeScreenState {

  String _formatRepresentationDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _showAddRepresentationDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
      helpText: 'Choisir une date de représentation',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    selectedDate = DateTime(picked.year, picked.month, picked.day);

    final existing = await FirebaseFirestore.instance
        .collection('representations')
        .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cette date de représentation existe déjà.'),
          ),
        );
      }
      return;
    }

    await FirebaseFirestore.instance.collection('representations').add({
      'date': Timestamp.fromDate(selectedDate),
      'availability': <String, dynamic>{},
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Représentation du ${_formatRepresentationDate(selectedDate)} ajoutée.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleRepresentationAvailability(
    String docId,
    Map availability,
    bool value,
  ) async {
    await FirebaseFirestore.instance
        .collection('representations')
        .doc(docId)
        .update({'availability.${user.uid}': value});
  }

  Future<void> _deleteRepresentation(
    BuildContext context,
    String docId,
    String dateLabel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Supprimer cette date ?'),
        content: Text('Supprimer la représentation du $dateLabel ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('representations')
          .doc(docId)
          .delete();
    }
  }

  Future<void> _showRepresentationResults(
    BuildContext context,
    Map availability,
  ) async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    final names = <String, String>{};
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      names[doc.id] = (data['displayName'] ?? 'Membre').toString();
    }

    final available = <String>[];
    final unavailable = <String>[];

    for (final entry in names.entries) {
      if (availability[entry.key] == true) {
        available.add(entry.value);
      } else {
        unavailable.add(entry.value);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Résultats des disponibilités'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Disponibles (${available.length})',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (available.isEmpty)
                  const Text(
                    'Personne pour le moment.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...available.map(
                    (name) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(name)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  'Non disponibles / sans réponse (${unavailable.length})',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (unavailable.isEmpty)
                  const Text(
                    'Tout le monde est disponible.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...unavailable.map(
                    (name) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(name)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentations() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('representations')
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Erreur de chargement des représentations.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final totalUsers = usersSnapshot.data?.docs.length ?? 0;

            Widget addButton() {
              return Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddRepresentationDialog(context),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'Proposer une date',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                ),
              );
            }

            if (docs.isEmpty) {
              return Column(
                children: [
                  if (_isAdmin && _adminMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: addButton(),
                    ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Aucune date de représentation proposée.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
              itemCount: docs.length + (_isAdmin && _adminMode ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAdmin && _adminMode && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: addButton(),
                  );
                }

                final doc = docs[_isAdmin && _adminMode ? index - 1 : index];
                final data = doc.data();
                final timestamp = data['date'];

                if (timestamp is! Timestamp) {
                  return const SizedBox.shrink();
                }

                final date = timestamp.toDate();
                final dateLabel = _formatRepresentationDate(date);
                final availability = Map<String, dynamic>.from(
                  data['availability'] ?? {},
                );
                final availableCount = availability.values
                    .where((value) => value == true)
                    .length;
                final bool isAvailable = availability[user.uid] == true;

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Résultats',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            InkWell(
                              onTap: () => _showRepresentationResults(
                                context,
                                availability,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  '$availableCount / $totalUsers disponibles',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: isAvailable
                              ? 'Disponible'
                              : 'Je ne suis pas disponible',
                          child: Checkbox(
                            value: isAvailable,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              _toggleRepresentationAvailability(
                                doc.id,
                                availability,
                                value ?? false,
                              );
                            },
                          ),
                        ),
                        if (_isAdmin && _adminMode)
                          IconButton(
                            tooltip: 'Supprimer la date',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteRepresentation(
                              context,
                              doc.id,
                              dateLabel,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

}
