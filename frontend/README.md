# Task manager — Frontend Task Manager

Interface Next.js du gestionnaire de tâches, connectée à l'API Spring Boot du dossier `../task-manager`.

## Fonctionnalités

- inscription et connexion ;
- JWT conservé dans un cookie sécurisé `HttpOnly` ;
- session restaurée au rechargement de la page ;
- création, modification, suppression et changement rapide de statut ;
- recherche et filtrage côté API ;
- compteurs dynamiques par statut ;
- erreurs de formulaire et notifications ;
- interface responsive pour ordinateur, tablette et mobile.

## Configuration

Copier le fichier d'exemple :

```bash
cp .env.example .env.local
```

La variable `API_URL` doit pointer vers l'API Spring Boot :

```dotenv
API_URL=http://localhost:8080
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

`API_URL` reste uniquement côté serveur. Le navigateur appelle les routes internes Next.js, qui ajoutent le JWT au moment de transmettre les requêtes à Spring Boot.

## Démarrage local

1. Démarrer MySQL et l'API Spring Boot dans `../task-manager`.
2. Installer les dépendances et lancer l'interface :

```bash
npm install
npm run dev
```

Ouvrir [http://localhost:3000](http://localhost:3000).

## Vérifications

```bash
npm run lint
npm run build -- --webpack
```

L'option Webpack évite une limitation locale de Turbopack rencontrée dans certains environnements isolés ; elle ne change pas le résultat produit.
