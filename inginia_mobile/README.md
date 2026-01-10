# 📱 Inginia Mobile

Application mobile Flutter pour la plateforme Inginia - Mise en relation entre clients et prestataires de services.

## 🎯 Fonctionnalités

### Pour les Clients

- ✅ Recherche et découverte de prestataires
- ✅ Consultation des profils et portfolios
- ✅ Réservation de services
- ✅ Suivi en temps réel des missions
- ✅ Messagerie intégrée
- ✅ Évaluation et avis
- ✅ Gestion du profil

### Pour les Prestataires

- ✅ Tableau de bord des missions
- ✅ Gestion des disponibilités
- ✅ Gestion des services proposés
- ✅ Portfolio de réalisations
- ✅ Messagerie avec les clients
- ✅ Suivi des réservations
- ✅ Notifications en temps réel

### Pour les Administrateurs

- ✅ Validation des prestataires
- ✅ Gestion des utilisateurs
- ✅ Tableau de bord statistiques

## 🚀 Installation

### Prérequis

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / Xcode (pour émulateurs)
- Backend Laravel Inginia en cours d'exécution

### Configuration

1. **Cloner le projet**

```bash
cd c:\Users\LEGEION\Desktop\Inginia\inginia_mobile
```

2. **Installer les dépendances**

```bash
flutter pub get
```

3. **Configurer l'URL du backend**
   Modifier `lib/services/api_service.dart` si nécessaire :

- Émulateur Android : `http://10.0.2.2:8000/api`
- iOS Simulator : `http://127.0.0.1:8000/api`
- Appareil physique : `http://[VOTRE_IP]:8000/api`

4. **Lancer le backend**

```bash
cd ..\inginia_backend
php artisan serve
php artisan reverb:start
```

5. **Lancer l'application**

```bash
# Android
flutter run -d emulator-5554

# iOS
flutter run -d [IOS_DEVICE_ID]

# Web
flutter run -d chrome
```

## 📁 Structure du Projet

```
lib/
├── models/              # Modèles de données
├── repositories/        # Communication avec l'API
├── services/           # Services transversaux
├── screens/            # Écrans de l'application
│   ├── admin/         # Écrans administrateur
│   ├── provider/      # Écrans prestataire
│   └── profile/       # Gestion du profil
├── widgets/            # Composants réutilisables
└── main.dart          # Point d'entrée

```

Voir [ARCHITECTURE.md](./ARCHITECTURE.md) pour plus de détails.

## 🔧 Technologies Utilisées

### Framework & Langage

- **Flutter** - Framework UI multiplateforme
- **Dart** - Langage de programmation

### Packages Principaux

- `dio` - Client HTTP
- `flutter_secure_storage` - Stockage sécurisé des tokens
- `geolocator` - Géolocalisation
- `google_maps_flutter` - Cartes interactives
- `image_picker` - Sélection d'images
- `laravel_echo` - WebSockets temps réel
- `pusher_channels_flutter` - Notifications push

### Architecture

- **Repository Pattern** - Séparation logique/données
- **Service Layer** - Logique métier transversale
- **State Management** - Provider/StatefulWidget

## 🌐 API Backend

L'application communique avec le backend Laravel via REST API :

### Endpoints Principaux

- `/api/login` - Authentification
- `/api/register` - Inscription
- `/api/providers` - Liste des prestataires
- `/api/reservations` - Gestion des réservations
- `/api/messages` - Messagerie
- `/api/availabilities` - Disponibilités

Voir la documentation du backend pour la liste complète.

## 🔐 Sécurité

- **Tokens JWT** stockés dans `FlutterSecureStorage`
- **Injection automatique** du token via intercepteurs Dio
- **HTTPS** recommandé en production
- **Validation** des entrées utilisateur

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📱 Plateformes Supportées

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web
- ⚠️ Windows/macOS/Linux (non testé)

## 🐛 Débogage

### Problèmes Courants

**Erreur de connexion au backend**

- Vérifier que le serveur Laravel est lancé
- Vérifier l'URL dans `api_service.dart`
- Pour appareil physique : utiliser l'IP locale

**Problèmes de permissions**

- Localisation : Vérifier `AndroidManifest.xml` et `Info.plist`
- Caméra : Permissions dans les fichiers de configuration

**Hot reload ne fonctionne pas**

```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Commandes Utiles

```bash
# Nettoyer le projet
flutter clean

# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Générer l'APK
flutter build apk

# Générer l'IPA
flutter build ios

# Vérifier les dépendances
flutter pub outdated
```

## 🚀 Déploiement

### Android

```bash
flutter build apk --release
# APK dans build/app/outputs/flutter-apk/
```

### iOS

```bash
flutter build ios --release
# Ouvrir Xcode pour archiver et uploader
```

### Web

```bash
flutter build web --release
# Fichiers dans build/web/
```

## 👥 Contributeurs

- **Développeur Principal** - Architecture et développement

## 📄 Licence

Projet privé - Tous droits réservés

## 📞 Support

Pour toute question ou problème :

- Consulter [ARCHITECTURE.md](./ARCHITECTURE.md)
- Vérifier les logs : `flutter logs`
- Consulter la documentation Flutter : https://flutter.dev/docs

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-01-08
