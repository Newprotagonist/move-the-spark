# Planner

Application personnelle de planification (PWA) : objectifs quotidiens/hebdomadaires avec
gamification simple, rendez-vous, chrono d'objectifs, listes de courses, et rappels par
notification push. Voir `SPEC.md` et `PLAN.md` pour le détail des choix produit et techniques.

Mono-utilisateur, sans authentification — l'app n'est pas prévue pour être exposée publiquement.

## Prérequis

- Ruby (voir `.ruby-version`)
- Pas de base de données externe : tout tourne sur SQLite (fichiers dans `storage/`)

## Installation

```bash
bin/setup
```

(ou manuellement : `bundle install && bin/rails db:prepare`)

## Lancer l'app en local

```bash
bin/dev
```

Démarre le serveur Rails + le watcher Tailwind. Ouvrir **http://localhost:3000**.

Pour que les rappels programmés fonctionnent (rendez-vous à venir, objectifs du jour non
faits), lancer en parallèle le worker Solid Queue :

```bash
bin/jobs
```

Sans `bin/jobs`, l'app fonctionne normalement mais aucune notification push n'est envoyée
(les jobs `AppointmentReminderJob` / `DailyGoalReminderJob`, programmés toutes les 5 minutes
via `config/recurring.yml`, ne tournent pas).

## Notifications push

Nécessite un navigateur servant l'app en HTTPS *ou* en localhost (les deux sont autorisés par
les navigateurs pour Service Worker + Push). Pour activer :

1. Aller dans **Réglages** (⚙ dans le menu).
2. Cliquer sur "Activer les notifications" et accepter la permission du navigateur.

Les clés VAPID sont déjà générées et stockées dans les credentials chiffrées Rails
(`config/credentials.yml.enc`, sous la clé `vapid`). Pour les régénérer :

```bash
bin/rails runner "k = Webpush.generate_key; puts k.public_key; puts k.private_key"
bin/rails credentials:edit
# puis mettre à jour vapid.public_key / vapid.private_key
```

> Note technique : le gem `webpush` utilise une API OpenSSL incompatible avec les versions
> récentes du gem `openssl` (OpenSSL 3+, clés EC immuables). Un correctif est appliqué dans
> `config/initializers/webpush_openssl3_compat.rb` — à retirer si `webpush` publie un jour un
> correctif upstream.

## Tests

```bash
bin/rails test           # tests unitaires / requêtes
bin/rails test:system    # tests système (Capybara + Chrome headless)
```

## Stack

Rails 8, SQLite, Solid Queue (jobs planifiés, zéro infra supplémentaire), Tailwind CSS,
Turbo + Stimulus (pas de framework JS séparé), gem `webpush` pour les notifications Web Push.
