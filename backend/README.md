# Task Manager — API Spring Boot

API REST sécurisée permettant à chaque utilisateur de créer et gérer ses propres tâches.

## Fonctionnalités

- inscription et connexion avec JWT ;
- mots de passe chiffrés avec BCrypt ;
- création, lecture, modification et suppression des tâches ;
- filtrage par statut et recherche dans le titre ou la description ;
- isolation des données : un utilisateur ne peut accéder qu'à ses tâches ;
- MySQL et API exécutables avec Docker Compose ;
- tests d'intégration sur une base H2 isolée.

## Prérequis

- Docker et Docker Compose, ou Java 21 avec une instance MySQL 8 ;
- Maven n'a pas besoin d'être installé : le wrapper `mvnw` est fourni.

## Démarrage avec Docker

Depuis ce dossier :

```bash
docker compose up --build
```

L'API est alors accessible sur `http://localhost:8080` et MySQL sur le port `3306`.

Pour un environnement autre que le développement, définir au minimum des secrets robustes :

```bash
export DB_PASSWORD='mot-de-passe-mysql-robuste'
export MYSQL_ROOT_PASSWORD='mot-de-passe-root-robuste'
export JWT_SECRET='secret-jwt-aleatoire-d-au-moins-32-caracteres'
docker compose up --build
```

## Démarrage local

Démarrer uniquement MySQL :

```bash
docker compose up mysql -d
./mvnw spring-boot:run
```

## API

### Créer un compte

```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "Alice",
  "email": "alice@example.com",
  "password": "password123"
}
```

### Se connecter

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "alice@example.com",
  "password": "password123"
}
```

Les deux routes renvoient un champ `token`. Les routes suivantes exigent l'en-tête :

```http
Authorization: Bearer <token>
```

### Gérer les tâches

| Méthode | Route | Description |
|---|---|---|
| `GET` | `/api/tasks` | Liste des tâches de l'utilisateur connecté |
| `GET` | `/api/tasks?status=DONE` | Filtre par statut |
| `GET` | `/api/tasks?search=rapport` | Recherche dans le titre et la description |
| `POST` | `/api/tasks` | Crée une tâche |
| `PUT` | `/api/tasks/{id}` | Remplace les données d'une tâche |
| `DELETE` | `/api/tasks/{id}` | Supprime une tâche |

Corps de création ou modification :

```json
{
  "title": "Préparer la démonstration",
  "description": "Valider tous les scénarios",
  "status": "TODO"
}
```

Les statuts acceptés sont `TODO`, `IN_PROGRESS` et `DONE`. `status` et `search` peuvent être combinés.

## Configuration

| Variable | Valeur par défaut en développement |
|---|---|
| `PORT` | `8080` |
| `DB_URL` | `jdbc:mysql://localhost:3306/task_manager_db?...` |
| `DB_USERNAME` | `task_manager` |
| `DB_PASSWORD` | `task_manager_password` |
| `JWT_SECRET` | secret local fourni dans la configuration |
| `JWT_EXPIRATION` | `86400` secondes |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:3000,http://localhost:5173` |
| `JPA_DDL_AUTO` | `update` |

## Tests

```bash
./mvnw test
```

Les tests couvrent l'authentification, le CRUD, les filtres et l'isolation des tâches entre utilisateurs.
