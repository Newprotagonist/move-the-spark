# Spec — Application de planification personnelle (v1)

## Objectif

Application web personnelle (PWA), à usage mono-utilisateur, pour planifier ses journées et
semaines : objectifs quotidiens/hebdomadaires avec un système de gamification simple, et un
endroit unique pour noter ses rendez-vous.

## Fonctionnalités v1

### 1. Objectifs (quotidiens et hebdomadaires)
- Créer un objectif ponctuel (aujourd'hui) ou récurrent (chaque jour / chaque semaine).
- Cocher un objectif comme accompli.
- Distinction visuelle objectifs du jour / objectifs de la semaine.

### 2. Gamification simple
- Points gagnés à chaque objectif coché.
- Suivi de streak (nombre de jours/semaines consécutifs avec au moins un objectif complété,
  ou avec tous les objectifs complétés — à trancher en phase de plan).
- Affichage du total de points et du streak courant sur la vue principale.
- Pas de niveaux, badges ou récompenses en v1 (prévu comme évolution future).
  **Mise à jour** : un système de niveaux simple (100 points par niveau, barre de progression)
  a finalement été ajouté lors de la refonte visuelle "Planner Moderne" importée depuis Claude
  Design — le design importé l'incluait explicitement, et l'utilisateur a validé cet écart
  au périmètre initial plutôt que de l'omettre. Toujours pas de badges/récompenses débloquables.

### 3. Rendez-vous (RDV)
- Créer un rdv avec titre, date, heure (et lieu/notes optionnels).
- Lister les rdv à venir.
- Un rdv peut être rattaché à un jour donné, visible dans la vue combinée.

### 4. Vue principale combinée
- Une vue jour (par défaut) et une vue semaine, affichant ensemble objectifs et rdv du/des
  jour(s) concernés — pas de sections séparées.

### 5. Notifications push
- Rappel push pour un rdv à venir (délai exact à définir en phase de plan, ex. 30 min avant).
- Rappel push pour les objectifs du jour non complétés (heure/fréquence à définir en phase de
  plan).
- Implémenté via Web Push (service worker + clés VAPID), compatible PWA installée sur Android.

### 6. Chronométrage des objectifs
- Chrono démarrer/arrêter directement sur un objectif existant (pas de nouvelle entité "tâche"
  séparée).
- Durée réelle enregistrée à chaque fois qu'un objectif chronométré est réalisé.
- Pas de saisie d'estimation manuelle en v1 : l'appli se contente de logger le temps réel.
- Pour les objectifs récurrents, affichage d'une moyenne des durées passées (ex. "en moyenne
  25 min"), pour aider à mieux planifier les prochaines occurrences.

### 7. Listes de courses
- Plusieurs listes nommées possibles (ex. "Courses hebdo", "Anniversaire"), créées, conservées
  et réutilisables comme modèles.
- Ajout/suppression d'articles dans une liste, articles cochables pendant les courses.
- Fonctionnalité utilitaire indépendante : pas de points ni de lien avec le streak/gamification.
- Affichée dans une section dédiée, séparée de la vue combinée jour/semaine (qui reste centrée
  sur objectifs + rdv).

## Hors périmètre v1 (évolutions futures possibles)

- Multi-utilisateur / authentification (aucun login prévu — accès direct, usage privé).
- Gamification avancée (niveaux, badges, récompenses déblocables).
- Synchronisation avec calendriers externes (Google Calendar, etc.).
- Application native (Hotwire Native) — on reste sur une PWA pour la v1.

## Contraintes techniques

- Backend : Ruby on Rails.
- Frontend : vues Rails classiques (ERB/Turbo), pas de framework JS séparé a priori.
- PWA : manifest.json, service worker, installable sur écran d'accueil Android.
- Notifications : Web Push API (VAPID), déclenchées côté serveur (nécessite un job
  planifié/scheduler pour les rappels).
- Hébergement : à définir en phase de plan (ex. Render ou Fly.io).
- Pas d'authentification (accès mono-utilisateur, URL non partagée).

## Questions ouvertes à trancher en phase de plan

- Barème exact des points (fixe par objectif ? bonus pour un streak long ?).
- Règle précise du streak (au moins un objectif fait, ou tous les objectifs faits, pour
  compter le jour/la semaine).
- Délai des rappels push pour les rdv et heure des rappels pour les objectifs du jour.
- Choix de l'hébergeur et mise en place du scheduler (rappels programmés).
- Comment identifier qu'un objectif est "récurrent" pour calculer sa moyenne de durée (même
  titre ? objectif template dupliqué chaque jour/semaine ?).
- Articles de liste de courses : simple texte libre, ou avec quantité/unité en plus du nom ?
- Nom de l'application.
