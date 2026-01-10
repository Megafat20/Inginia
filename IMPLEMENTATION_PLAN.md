# Plan d'Implémentation - Améliorations Majeures Inginia

## 📍 Phase 1 : Géolocalisation et Tri par Proximité (EN COURS)

### ✅ Complété

- [x] Ajout de `latitude` et `longitude` au modèle `User`
- [x] Enrichissement du `LocationService` avec calcul de distance (Haversine)
- [x] Méthodes de tri et filtrage par proximité

### 🔄 En cours

- [ ] Mise à jour du `ClientDashboardScreen` pour :
  - Obtenir la position de l'utilisateur au démarrage
  - Trier la section "À proximité" par distance réelle
  - Ajouter un filtre par rayon (5km, 10km, 20km)
  - Afficher la distance sur chaque carte de prestataire

### 📋 À faire

- [ ] Créer un écran de carte interactive (`ProvidersMapScreen`)
  - Affichage des prestataires sur une carte
  - Marqueurs personnalisés par catégorie
  - Info-bulles au clic sur un marqueur
  - Navigation vers `ProviderDetailScreen`
- [ ] Ajouter un bouton "Vue Carte" dans le dashboard
- [ ] Gérer les cas d'erreur (GPS désactivé, permissions refusées)
- [ ] Ajouter un indicateur de chargement pendant la géolocalisation

---

## 🔔 Phase 2 : Système de Notifications Push (CODE TERMINÉ)

### ✅ Complété

- [x] Backend : Table `device_tokens` et modèle `DeviceToken` présents
- [x] Backend : Routes API (`/devices/register`) et Controller
- [x] Backend : Service d'envoi FCM (`FcmService`) et Listeners d'événements
- [x] Flutter : Service `PushNotificationService` pour l'enregistrement du token
- [x] Flutter : Gestion des notifications en premier plan et arrière-plan

### ⚠️ Configuration Requise (Action Utilisateur)

- [ ] Ajouter `google-services.json` (Android) et `GoogleService-Info.plist` (iOS)
- [ ] Configurer les clés Firebase dans `.env` du backend (`FIREBASE_CREDENTIALS`, etc.)
- [ ] Tester l'envoi via l'endpoint de test `/api/notifications/test`

---

## 💬 Phase 3 : Chat en Temps Réel Amélioré (EN COURS)

### ✅ Complété

- [x] Refonte de l'interface `ChatScreen` (Design type Messenger/iMessage)
- [x] Intégration WebSocket (`WebSocketService`) écoutant `private-chat.{id}`
- [x] Affichage groupé des messages et timestamps intelligents
- [x] Indicateur visuel "En train d'écrire..." (UI prête)
- [x] Préparation bouton envoi d'image

### 📋 À faire

1. **Backend - Upload Médias**

   - Endpoint `/api/chat/upload` pour stocker les images
   - Lien avec le message

2. **Backend - WebSocket Typing**

   - Événements `client-typing` sur le canal

3. **Frontend - Finalisation**

   - Connecter l'upload d'image
   - Tester le temps réel en conditions réelles

   - Sélection et envoi de photos
   - Prévisualisation des images
   - Compression des images avant envoi
   - Affichage des images dans le chat

4. **Persistance et historique**

   - Base de données locale (SQLite/Hive)
   - Synchronisation avec le serveur
   - Chargement de l'historique au scroll
   - Recherche dans les conversations

5. **Backend**
   - Endpoint pour upload de fichiers
   - Stockage des médias
   - Endpoint pour récupérer l'historique paginé
   - WebSocket events pour "typing indicator"

---

## 🎯 Ordre d'Implémentation Recommandé

### Semaine 1

- ✅ Géolocalisation de base (FAIT)
- 🔄 Tri par proximité dans le dashboard (EN COURS)
- ⏳ Écran de carte interactive

### Semaine 2

- Configuration FCM
- Backend notifications
- Réception notifications Flutter

### Semaine 3

- Refonte interface chat
- Indicateur "typing"
- Envoi de photos

### Semaine 4

- Persistance locale du chat
- Tests et optimisations
- Documentation

---

## 📝 Notes Techniques

### Dépendances à ajouter

```yaml
dependencies:
  # Géolocalisation (déjà présent)
  geolocator: ^10.1.0

  # Carte interactive
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0

  # Chat amélioré
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  cached_network_image: ^3.3.1

  # Persistance
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
```

### Permissions requises

**Android** (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

**iOS** (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin de votre position pour trouver les prestataires à proximité</string>
<key>NSCameraUsageDescription</key>
<string>Autoriser l'accès à la caméra pour envoyer des photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Autoriser l'accès aux photos pour les partager dans le chat</string>
```

---

## 🚀 Prochaines Étapes Immédiates

1. Terminer l'intégration de la géolocalisation dans `ClientDashboardScreen`
2. Créer `ProvidersMapScreen` pour la vue carte
3. Tester le tri par distance avec des données réelles
4. Passer à la Phase 2 (Notifications)
