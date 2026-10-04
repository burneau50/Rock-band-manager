# Rock Band Manager — refactorisation de main.dart

Cette archive contient la refactorisation du code actuellement valide.

## Fichiers modifies/crees

- `lib/main.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/home_song_methods.dart`
- `lib/screens/home_representation_methods.dart`
- `lib/screens/home_ui_methods.dart`

Les fichiers existants `lib/models/song.dart`, `lib/services/song_service.dart` et `lib/services/auth_service.dart` ne sont pas modifies.

## Application automatique

1. Decompressez cette archive ou utilisez `apply_refactor.ps1`.
2. Ouvrez PowerShell dans la racine du projet Flutter.
3. Executez :

`powershell -ExecutionPolicy Bypass -File .\apply_refactor.ps1`

Le script sauvegarde automatiquement l'ancien `lib/main.dart` avant remplacement.

## Verification

```powershell
flutter analyze
flutter build web
flutter run -d chrome
```

## Git apres validation

```powershell
git add lib/main.dart lib/screens
git commit -m "Refactorise l architecture de l application"
git push
```
