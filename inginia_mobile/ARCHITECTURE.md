# Architecture du Projet Inginia Mobile

## 📁 Structure Organisée

### 1. **Repositories** (`lib/repositories/`)

Les repositories gèrent la logique de communication avec l'API backend.

#### `auth_repository.dart`

- **Section 1: Authentication** - Login, Register, Logout
- **Section 2: User Profile Management** - GetMe, UpdateProfile

#### `provider_repository.dart`

- **Section 1: Provider Discovery** - Liste des prestataires, détails, avis
- **Section 2: Client Actions** - Réservations, avis clients
- **Section 3: Reservation Management** - Récupération des missions (client/provider)
- **Section 4: Mission Actions** - Statut, localisation, signalements
- **Section 5: Provider Services Management** - CRUD des services
- **Section 6: Availability Management** - Gestion des disponibilités
- **Section 7: Profile & Portfolio** - Profil et portfolio prestataire

#### `chat_repository.dart`

- **Chat & Messaging** - Récupération et envoi de messages

---

### 2. **Services** (`lib/services/`)

Les services fournissent des fonctionnalités transversales.

#### `api_service.dart`

Service central pour les requêtes HTTP :

- Configuration automatique de l'URL selon la plateforme
- Gestion des tokens d'authentification
- Intercepteurs pour l'injection automatique du token

#### `location_service.dart`

Gestion de la géolocalisation :

- Vérification des permissions
- Récupération de la position actuelle

#### `websocket_service.dart`

Communication temps réel via WebSockets

#### `push_notification_service.dart`

Gestion des notifications push

#### `tracking_service.dart`

Suivi en temps réel des missions

#### `admin_service.dart`

Services spécifiques à l'administration

---

### 3. **Screens** (`lib/screens/`)

Organisation par fonctionnalité :

#### Authentification

- `login_screen.dart` - Connexion
- `register_screen.dart` - Inscription
- `pending_validation_screen.dart` - Validation en attente

#### Dashboards

- `client_dashboard_screen.dart` - Tableau de bord client
- `provider/provider_dashboard_screen.dart` - Tableau de bord prestataire
- `admin/admin_dashboard_screen.dart` - Tableau de bord admin

#### Gestion des Prestataires

- `providers_list_screen.dart` - Liste des prestataires
- `provider_detail_screen.dart` - Détails d'un prestataire
- `provider/provider_planning_screen.dart` - Planning du prestataire
- `provider/portfolio_management_screen.dart` - Gestion du portfolio

#### Missions & Réservations

- `mission_screen.dart` - Détails d'une mission
- `tracking_screen.dart` - Suivi de mission
- `tracking_map_screen.dart` - Carte de suivi
- `rate_provider_screen.dart` - Évaluation du prestataire

#### Communication

- `chat_screen.dart` - Messagerie

#### Profil

- `profile_screen.dart` - Profil utilisateur
- `profile/edit_profile_screen.dart` - Édition du profil

#### Administration

- `admin/provider_validation_screen.dart` - Validation des prestataires

---

### 4. **Models** (`lib/models/`)

Modèles de données pour la sérialisation/désérialisation JSON :

- `user_model.dart` - Utilisateur
- `provider_details_model.dart` - Détails prestataire
- `reservation_model.dart` - Réservation/Mission
- `availability_model.dart` - Disponibilité
- `message_model.dart` - Message

---

## 🎯 Principes d'Organisation

### Séparation des Responsabilités

1. **Repositories** : Communication API uniquement
2. **Services** : Logique métier transversale
3. **Screens** : Interface utilisateur et état local
4. **Models** : Structure des données

### Conventions de Nommage

- **Fichiers** : `snake_case.dart`
- **Classes** : `PascalCase`
- **Méthodes** : `camelCase`
- **Constantes** : `UPPER_SNAKE_CASE`

### Organisation des Méthodes

Chaque fichier est organisé en sections logiques avec des commentaires de séparation :

```dart
// -----------------------------------------------------------------------------
// 1. Nom de la Section
// -----------------------------------------------------------------------------
```

### Documentation

- Commentaires de classe expliquant le rôle
- Documentation des méthodes importantes
- Commentaires inline pour la logique complexe

---

## 🔄 Flux de Données

```
User Action (Screen)
    ↓
State Management (Provider/Bloc)
    ↓
Repository (API Call)
    ↓
API Service (HTTP)
    ↓
Backend Laravel
```

---

## 🚀 Bonnes Pratiques

### 1. Gestion d'Erreurs

- Try-catch dans tous les repositories
- Messages d'erreur explicites
- Retour de valeurs par défaut ([], null) en cas d'échec

### 2. Async/Await

- Toutes les opérations réseau sont asynchrones
- Utilisation de `Future<T>` pour les retours

### 3. Typage Fort

- Éviter `dynamic` autant que possible
- Utiliser les modèles typés

### 4. Sécurité

- Tokens stockés dans `FlutterSecureStorage`
- Injection automatique du token via intercepteurs

---

## 📱 Configuration Plateforme

### Android Emulator

- URL: `http://10.0.2.2:8000/api`

### iOS Simulator / Desktop

- URL: `http://127.0.0.1:8000/api`

### Web

- URL: `http://localhost:8000/api`

### Appareil Physique

- Modifier l'URL dans `api_service.dart`
- Lancer le serveur : `php artisan serve --host=0.0.0.0`
- Utiliser l'IP locale (ex: `http://192.168.1.x:8000/api`)

---

## 🔧 Maintenance

### Ajout d'une Nouvelle Fonctionnalité

1. Créer le modèle dans `models/`
2. Ajouter les méthodes API dans le repository approprié
3. Créer le screen dans `screens/`
4. Mettre à jour cette documentation

### Modification d'une API

1. Mettre à jour le repository concerné
2. Vérifier les modèles de données
3. Tester les écrans utilisant cette API

---

_Dernière mise à jour : 2026-01-08_
