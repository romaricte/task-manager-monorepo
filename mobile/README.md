# Momentum — Application mobile Flutter

Client mobile du gestionnaire de tâches, connecté à la même API Spring Boot et à la même base MySQL que l'interface web.

## Fonctionnalités

- création de compte et connexion ;
- conservation sécurisée du JWT avec `flutter_secure_storage` ;
- appels HTTP avec Dio et ajout automatique du header `Authorization` ;
- gestion d'état avec Flutter BLoC ;
- liste, recherche et filtrage des tâches via l'API ;
- création, modification, suppression et changement rapide de statut ;
- actualisation par glissement vers le bas ;
- gestion des erreurs réseau et des sessions expirées ;
- interface responsive pour téléphones et tablettes.

## API locale

L'URL est fournie avec `API_BASE_URL`.

### Android Emulator

L'adresse par défaut est déjà configurée :

```text
http://10.0.2.2:8080
```

```bash
flutter run
```

### iOS Simulator ou macOS

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

### Téléphone physique

Utiliser l'adresse IP locale de l'ordinateur qui exécute Spring Boot :

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
```

Le téléphone et l'ordinateur doivent être connectés au même réseau. En production, utiliser l'URL HTTPS de l'API déployée sur GCP.

## Synchronisation web/mobile

Le web et le mobile appellent les mêmes routes :

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/tasks`
- `POST /api/tasks`
- `PUT /api/tasks/{id}`
- `DELETE /api/tasks/{id}`

Les modifications sont persistées dans la même base MySQL. Un glissement vers le bas sur la liste mobile récupère immédiatement les changements effectués sur le web.

## Vérifications

```bash
flutter analyze
flutter test
flutter build apk --debug
```

L'APK de développement est généré dans `build/app/outputs/flutter-apk/app-debug.apk`.
