$ErrorActionPreference = 'Stop'

$project = "C:\Users\PC-Bureau\3D Objects\rock_band_app"
$target = Join-Path $project "lib\main.dart"
$backup = Join-Path $project ("lib\main.before-architecture-step1-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".dart")

if (-not (Test-Path $project)) {
    throw "Projet introuvable : $project"
}

if (-not (Test-Path (Join-Path $project "lib"))) {
    throw "Dossier lib introuvable : $project\lib"
}

if (Test-Path $target) {
    Copy-Item $target $backup -Force
    Write-Host "Sauvegarde créée : $backup"
}

$mainContent = @'
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'models/song.dart';
import 'services/song_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB25UcAbzt3Jr-CP305W9738Rf8LbR2W-s",
      authDomain: "playerkiss-9d8fa.firebaseapp.com",
      projectId: "playerkiss-9d8fa",
      storageBucket: "playerkiss-9d8fa.firebasestorage.app",
      messagingSenderId: "798232377817",
      appId: "1:798232377817:web:62c7942235923947c1c1c8",
    ),
  );

  runApp(const RockBandApp());
}

class RockBandApp extends StatelessWidget {
  static const String adminPseudo = 'antonin';
  static const String adminEmail = 'antoninlemonnier50@gmail.com';
  static const String internalEmailDomain = '@rockband-app.invalid';

  const RockBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rock Band Manager',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomeScreen(user: snapshot.data!);
        }
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pseudoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  String _normalizePseudo(String pseudo) {
    return pseudo
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '');
  }

  String _buildInternalEmail(String pseudo) {
    final normalized = _normalizePseudo(pseudo);
    return '$normalized${RockBandApp.internalEmailDomain}';
  }

  Future<void> _submit() async {
    final pseudo = _pseudoController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final normalized = _normalizePseudo(pseudo);

    if (pseudo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le pseudo et le mot de passe.'),
        ),
      );
      return;
    }

    if (normalized.isEmpty || pseudo.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le pseudo n’est pas valide.')),
      );
      return;
    }

    if (!_isLogin && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les deux mots de passe ne correspondent pas.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Antonin utilise volontairement son ancien compte Firebase.
        // Ainsi les règles Firestore qui autorisent l'administrateur
        // avec antoninlemonnier50@gmail.com continuent de fonctionner.
        final email = normalized == RockBandApp.adminPseudo
            ? RockBandApp.adminEmail
            : _buildInternalEmail(pseudo);

        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // On renseigne aussi le pseudo dans le profil Firebase de l'admin.
        // Cela permet à l'interface de l'identifier même si le displayName
        // était vide auparavant.
        if (normalized == RockBandApp.adminPseudo &&
            credential.user != null &&
            credential.user!.displayName != 'Antonin') {
          await credential.user!.updateDisplayName('Antonin');
        }
      } else {
        // Le pseudo Antonin est réservé au compte administrateur existant.
        if (normalized == RockBandApp.adminPseudo) {
          throw FirebaseAuthException(
            code: 'pseudo-reserved',
            message: 'Le pseudo Antonin est réservé à l’administrateur.',
          );
        }

        // L'adresse Firebase est générée à partir du pseudo.
        // L'utilisateur ne voit jamais cette adresse.
        // Elle reste identique à chaque connexion : aucun accès public
        // à la collection users n'est nécessaire pour retrouver le compte.
        final internalEmail = _buildInternalEmail(pseudo);

        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );

        if (credential.user != null) {
          await credential.user!.updateDisplayName(pseudo);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
            'displayName': pseudo,
            'username': pseudo,
            'usernameLower': normalized,
            'email': internalEmail,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = e.message ?? 'Erreur d’authentification.';

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Pseudo ou mot de passe incorrect.';
          break;
        case 'user-not-found':
          message = 'Pseudo ou mot de passe incorrect.';
          break;
        case 'email-already-in-use':
          message = 'Ce pseudo est déjà utilisé.';
          break;
        case 'invalid-email':
          message = 'Le pseudo n’est pas valide.';
          break;
        case 'weak-password':
          message = 'Le mot de passe doit contenir au moins 6 caractères.';
          break;
        case 'pseudo-reserved':
          message = 'Le pseudo Antonin est réservé à l’administrateur.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.guitar,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Connexion Groupe' : 'Créer un compte',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pseudoController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Pseudo',
                    hintText: 'Ex : Antonin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction:
                      _isLogin ? TextInputAction.done : TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  onSubmitted: (_) {
                    if (_isLogin && !_isLoading) _submit();
                  },
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) {
                      if (!_isLoading) _submit();
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isLogin ? 'Se connecter' : 'S’inscrire',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Pas de compte ? Créer un compte'
                        : 'Déjà un compte ? Se connecter',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  bool get _isAdmin =>
      user.uid == 'i9FgMz7tKxZqKEa73SCKEa4lmQV2';

  static const Map instruments = {
    'guitare': FontAwesomeIcons.guitar,
    'basse': FontAwesomeIcons.guitar,
    'synthe': FontAwesomeIcons.sliders,
    'batterie': FontAwesomeIcons.drum,
  };

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
      String currentSongsterrUrl) async {
    final titleController = TextEditingController(text: currentTitle);
    final artistController = TextEditingController(text: currentArtist);
    final youtubeController = TextEditingController(text: currentYoutubeUrl);
    final songsterrController =
        TextEditingController(text: currentSongsterrUrl);

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
                    content:
                        Text('Le titre et l’artiste sont obligatoires.'),
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
        const SnackBar(
          content: Text('Morceau modifié avec succès.'),
        ),
      );
    }
  }


  Future<void> _toggleInstrument(
      String docId, List currentLearned, String key) async {
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
      String docId, List userLearned, BuildContext context) {
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
                child: FaIcon(
                  entry.value,
                  size: 17,
                  color: Colors.amber,
                ),
              ),
            ),
          const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Future _openYoutubeLink(
      String urlString, BuildContext context) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien YouTube invalide')),
        );
      }
    }
  }

  Future _openSongsterrLink(
      String urlString, BuildContext context) async {
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
      String docId, Map availability, bool value) async {
    await FirebaseFirestore.instance
        .collection('representations')
        .doc(docId)
        .update({
      'availability.${user.uid}': value,
    });
  }

  Future<void> _deleteRepresentation(
      BuildContext context, String docId, String dateLabel) async {
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
      BuildContext context, Map availability) async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

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
                  const Text('Personne pour le moment.',
                      style: TextStyle(color: Colors.grey))
                else
                  ...available.map((name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                          ],
                        ),
                      )),
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
                  const Text('Tout le monde est disponible.',
                      style: TextStyle(color: Colors.grey))
                else
                  ...unavailable.map((name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_circle_outline,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer',
                style: TextStyle(color: Colors.amber)),
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
                final availability =
                    Map<String, dynamic>.from(data['availability'] ?? {});
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
                        const Icon(
                          Icons.event,
                          color: Colors.amber,
                          size: 28,
                        ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
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

  void _showSongDetailsDialog(BuildContext context, String title,
      String artist, List likes, Map progressMap) {
    final Set allUserIds = {
      ...likes.cast(),
      ...progressMap.keys.cast(),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(artist,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
                        final List userLearned =
                            rawProg is List ? rawProg : [];
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
                                      .where((entry) =>
                                          userLearned.contains(entry.key))
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2.0),
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
            child:
                const Text('Fermer', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
                        border: Border.all(
                          color: Colors.amber,
                          width: 1,
                        ),
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
                      border: Border.all(
                        color: Colors.amber,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.amber,
                      size: 18,
                    ),
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
                Tab(icon: Icon(Icons.table_chart, size: 16), text: 'Récapitulatif'),
                Tab(icon: Icon(Icons.event, size: 16), text: 'RDV'),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 19),
              onPressed: () => FirebaseAuth.instance.signOut(),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
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
            final String artist =
                song.artist.isEmpty ? 'Inconnu' : song.artist;
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
                            value: <String>[
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
                                child: _statusMenuItem(
                                  'Prêt',
                                  Colors.green,
                                ),
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
                                    backgroundColor:
                                        const Color(0xFF2C2C2C),
                                    title:
                                        const Text('Supprimer ce morceau ?'),
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
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFF2C2C2C)),
                  dataRowColor:
                      WidgetStateProperty.all(const Color(0xFF1E1E1E)),
                  border:
                      TableBorder.all(color: Colors.grey.shade800, width: 1),
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
                      final String name =
                          (data['displayName'] ?? 'Membre').toString();

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
                    final String title =
                        song.title.isEmpty ? 'Sans titre' : song.title;
                    final String artist =
                        song.artist.isEmpty ? 'Inconnu' : song.artist;

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
                              Text(
                                '-',
                                style: TextStyle(color: Colors.grey),
                              ),
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
                                                ? Colors.orange.withOpacity(
                                                    0.18,
                                                  )
                                                : Colors.red.withOpacity(0.18),
                                        borderRadius:
                                            BorderRadius.circular(10),
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
'@

Set-Content -Path $target -Value $mainContent -Encoding UTF8

Write-Host ""
Write-Host "main.dart remplacé avec succès."
Write-Host "Architecture étape 1 : SongService intégré."
Write-Host ""
Write-Host "Prochaine vérification :"
Write-Host "  cd `"$project`""
Write-Host "  dart format lib\main.dart lib\models\song.dart lib\services\song_service.dart"
Write-Host "  flutter analyze"
Write-Host ""
