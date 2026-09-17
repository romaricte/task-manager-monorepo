# Task Manager Monorepo

Application complète de gestion de tâches : API Spring Boot sécurisée par JWT, interface Next.js, client Flutter et automatisation GitHub Actions.

## Structure

```text
task-manager-monorepo/
├── backend/                 # Java 21, Spring Boot, JPA, MySQL, JWT
├── frontend/                # Next.js, React, TypeScript, Tailwind CSS
├── mobile/                  # Flutter, Dart, Dio, BLoC
├── .github/workflows/       # CI et validation continue des images Docker
├── docker-compose.yml       # Environnement local complet
└── .env.example             # Variables locales sans secret réel
```

## Description technique rapide

### Architecture générale

Le frontend web et l'application mobile utilisent la même API REST. L'API authentifie les utilisateurs avec un JWT, applique les règles métier et enregistre les comptes et les tâches dans MySQL.

```text
Frontend Next.js ─┐
                  ├──> API Spring Boot ───> MySQL
Application Flutter ─┘
```

Cette organisation permet de partager les mêmes données entre le web et le mobile. Une tâche créée depuis une application est donc disponible dans l'autre après actualisation.

### Backend — Spring Boot

- **Spring Web** expose les routes REST d'inscription, de connexion et de gestion des tâches.
- **Spring Security et JWT** protègent les routes et identifient l'utilisateur connecté.
- **Spring Data JPA** simplifie l'accès aux données et la relation entre un utilisateur et ses tâches.
- **MySQL** conserve les données de manière persistante.
- Les contrôleurs reçoivent les requêtes, les services appliquent les règles métier et les repositories communiquent avec la base.

### Frontend — Next.js

- **Next.js, React et TypeScript** fournissent une interface web typée et organisée en composants.
- **Tailwind CSS** gère la mise en forme et l'affichage responsive.
- **TanStack Query** gère le chargement, le cache et l'actualisation des tâches après une modification.
- Les routes serveur Next.js servent de relais vers Spring Boot. Elles conservent le JWT dans un cookie `HttpOnly`, afin qu'il ne soit pas directement accessible au JavaScript du navigateur.

### Mobile — Flutter

- **Flutter et Dart** permettent d'utiliser une base de code commune pour Android et iOS.
- **Dio** effectue les appels HTTP vers la même API Spring Boot que le frontend web.
- **Flutter BLoC** sépare l'état de l'interface des appels réseau et des règles de présentation.
- **Flutter Secure Storage** conserve le JWT dans le stockage sécurisé de l'appareil.

### Docker et automatisation

- **Docker Compose** lance localement MySQL, le backend et le frontend avec une seule commande.
- **GitHub Actions** teste et compile chaque projet à chaque contribution.
- Un second workflow vérifie que les images Docker du backend et du frontend peuvent être construites, sans les publier ni effectuer de déploiement.

## Démarrage rapide avec Docker

Prérequis : Docker Desktop avec Docker Compose.

```bash
cp .env.example .env
docker compose up --build
```

L'interface web est disponible sur `http://localhost:3000` et l'API sur `http://localhost:8080`.

Pour arrêter les services :

```bash
docker compose down
```

Les données MySQL restent conservées dans le volume `mysql_data`. La commande `docker compose down -v` les efface ; ne l'utiliser que si cette suppression est souhaitée.

## Développement par application

### Backend

```bash
cd backend
./mvnw spring-boot:run
./mvnw test
```

Le backend nécessite MySQL. Il peut être lancé seul avec `docker compose up mysql -d` depuis la racine.

### Frontend

```bash
cd frontend
cp .env.example .env.local
npm ci
npm run dev
```

Vérifications :

```bash
npm test
npm run lint
npm run build -- --webpack
```

### Mobile

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

L'émulateur Android utilise par défaut `http://10.0.2.2:8080`. Pour iOS Simulator :

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Automatisation GitHub Actions

- **CI** s'exécute sur les pull requests et les pushes vers `main`. Elle teste le backend, teste/lint/build le frontend, puis analyse, teste et compile l'application Flutter.
- **CD - Docker validation** démarre uniquement après une CI réussie sur `main` (ou manuellement). Elle construit les images Docker du backend et du frontend sans les publier.

Aucune ressource GCP, aucun registre distant et aucun déploiement ne sont configurés à ce stade. La future phase GCP pourra ajouter l'authentification sans clé, Artifact Registry et Cloud Run sans modifier les applications.

## Sécurité

Les valeurs de `.env.example` sont uniquement destinées au développement. Les fichiers `.env` et les identifiants temporaires sont ignorés par Git. En environnement distant, utiliser des secrets robustes et le gestionnaire de secrets de la plateforme.
