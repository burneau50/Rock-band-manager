part of 'home_screen.dart';

extension _HomeScreenCalendarMethods on _HomeScreenState {
  Widget _buildCalendarUi(BuildContext context) {
    return _CalendarView(homeState: this);
  }
}

class _CalendarView extends StatefulWidget {
  final _HomeScreenState homeState;

  const _CalendarView({required this.homeState});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const List<String> _weekDays = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) =>
      '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';

  String _monthLabel(DateTime date) {
    const months = [
      'Janvier',
      'FÃ©vrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'AoÃ»t',
      'Septembre',
      'Octobre',
      'Novembre',
      'DÃ©cembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<DateTime> _daysOfMonth() {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final mondayOffset = first.weekday - DateTime.monday;
    final totalCells = ((mondayOffset + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final day = index - mondayOffset + 1;
      return DateTime(_displayedMonth.year, _displayedMonth.month, day);
    });
  }

  List<Map<String, dynamic>> _eventsForDay(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime day,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final data = doc.data();
      final rawDate = data['date'];
      DateTime? eventDate;
      if (rawDate is Timestamp) {
        eventDate = rawDate.toDate();
      } else if (rawDate is DateTime) {
        eventDate = rawDate;
      }
      if (eventDate != null && _sameDay(eventDate, day)) {
        result.add({...data, '_id': doc.id});
      }
    }
    result.sort((a, b) =>
        (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));
    return result;
  }

  Future<void> _showEventDialog({
    required DateTime selectedDate,
    Map<String, dynamic>? event,
  }) async {
    final isAdmin = widget.homeState._isAdmin && widget.homeState._adminMode;
    if (!isAdmin && event == null) return;

    final titleController = TextEditingController(text: event?['title']?.toString() ?? '');
    final timeController = TextEditingController(text: event?['time']?.toString() ?? '');
    final locationController = TextEditingController(text: event?['location']?.toString() ?? '');
    final notesController = TextEditingController(text: event?['notes']?.toString() ?? '');
    DateTime eventDate = selectedDate;

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(event == null ? 'Nouvel Ã©vÃ©nement' : 'Modifier lâ€™Ã©vÃ©nement'),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 430,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today, color: Colors.amber),
                          title: const Text('Date'),
                          subtitle: Text(_formatDate(eventDate)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: eventDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              locale: const Locale('fr', 'FR'),
                            );
                            if (picked != null) {
                              setDialogState(() => eventDate = picked);
                            }
                          },
                        ),
                        TextField(
                          controller: titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Titre *',
                            prefixIcon: Icon(Icons.event),
                          ),
                        ),
                        TextField(
                          controller: timeController,
                          decoration: const InputDecoration(
                            labelText: 'Heure',
                            hintText: 'Ex. 20:30',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                        ),
                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Lieu',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (event != null && isAdmin)
                    TextButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, 'delete'),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  if (isAdmin)
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, 'save'),
                      child: const Text('Enregistrer'),
                    ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || result == null) return;

      final collection = FirebaseFirestore.instance.collection('calendar_events');
      final id = event?['_id']?.toString();

      if (result == 'delete' && id != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer lâ€™Ã©vÃ©nement ?'),
            content: Text('Â« ${event?['title'] ?? 'Ã‰vÃ©nement'} Â» sera dÃ©finitivement supprimÃ©.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await collection.doc(id).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ã‰vÃ©nement supprimÃ©.')),
            );
          }
        }
        return;
      }

      if (result == 'save') {
        final title = titleController.text.trim();
        if (title.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Le titre est obligatoire.')),
            );
          }
          return;
        }

        final data = <String, dynamic>{
          'date': Timestamp.fromDate(_dateOnly(eventDate)),
          'title': title,
          'time': timeController.text.trim(),
          'location': locationController.text.trim(),
          'notes': notesController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': widget.homeState.user.uid,
        };

        if (id == null) {
          data['createdAt'] = FieldValue.serverTimestamp();
          data['createdBy'] = widget.homeState.user.uid;
          await collection.add(data);
        } else {
          await collection.doc(id).update(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(id == null ? 'Ã‰vÃ©nement crÃ©Ã©.' : 'Ã‰vÃ©nement modifiÃ©.')),
          );
        }
      }
    } finally {
      titleController.dispose();
      timeController.dispose();
      locationController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _showDayEvents(
    DateTime day,
    List<Map<String, dynamic>> events,
  ) async {
    if (events.isEmpty) {
      if (widget.homeState._isAdmin && widget.homeState._adminMode) {
        await _showEventDialog(selectedDate: day);
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isAdmin = widget.homeState._isAdmin && widget.homeState._adminMode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(day),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        tooltip: 'Ajouter',
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _showEventDialog(selectedDate: day);
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.amber),
                      ),
                  ],
                ),
                const Divider(),
                ...events.map(
                  (event) => ListTile(
                    leading: const Icon(Icons.event, color: Colors.amber),
                    title: Text(event['title']?.toString() ?? 'Ã‰vÃ©nement'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((event['time'] ?? '').toString().isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event['time'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if ((event['location'] ?? '').toString().isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event['location'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if ((event['notes'] ?? '').toString().isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event['notes'].toString(),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: isAdmin ? const Icon(Icons.edit, size: 18) : null,
                    onTap: isAdmin
                        ? () async {
                            Navigator.pop(sheetContext);
                            await _showEventDialog(selectedDate: day, event: event);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('calendar_events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur calendrier : ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final days = _daysOfMonth();
        final today = _dateOnly(DateTime.now());
        final isAdmin = widget.homeState._isAdmin && widget.homeState._adminMode;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Mois prÃ©cÃ©dent',
                    onPressed: () => setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                    }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel(_displayedMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mois suivant',
                    onPressed: () => setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                    }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
                    }),
                    child: const Text("Aujourd'hui"),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Nouvel Ã©vÃ©nement',
                      onPressed: () => _showEventDialog(
                        selectedDate: _dateOnly(DateTime.now()),
                      ),
                      icon: const Icon(Icons.add_circle, color: Colors.amber),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: _weekDays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.92,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final inMonth = day.month == _displayedMonth.month;
                  final events = _eventsForDay(docs, day);
                  final isToday = _sameDay(day, today);

                  return InkWell(
                    onTap: () => _showDayEvents(day, events),
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.amber.withOpacity(0.12)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isToday ? Colors.amber : Colors.grey.withOpacity(0.22),
                          width: isToday ? 1.5 : 0.7,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: inMonth ? null : Colors.grey.withOpacity(0.45),
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...events.take(3).map(
                            (event) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                event['title']?.toString() ?? 'Ã‰vÃ©nement',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 8.5),
                              ),
                            ),
                          ),
                          if (events.length > 3)
                            Text(
                              '+${events.length - 3}',
                              style: const TextStyle(fontSize: 8, color: Colors.amber),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
