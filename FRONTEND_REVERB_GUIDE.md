# 🔄 Guide de mise à jour Frontend - Laravel Reverb

## 📱 Modifications nécessaires dans `inginia_frontend`

### 1. **Mettre à jour le fichier `.env`**

Créez ou modifiez `inginia_frontend/.env` :

```env
# API Backend
REACT_APP_API_URL=http://localhost:8000/api

# Laravel Reverb WebSockets
REACT_APP_REVERB_APP_KEY=inginia-key
REACT_APP_REVERB_HOST=localhost
REACT_APP_REVERB_PORT=8080
REACT_APP_REVERB_SCHEME=http
```

---

### 2. **Mettre à jour `src/echo.js`**

**Fichier actuel** (`src/echo.js`):

```javascript
import Echo from "laravel-echo";
import Pusher from "pusher-js";

window.Pusher = Pusher;

window.Echo = new Echo({
  broadcaster: "pusher",
  key: process.env.REACT_APP_PUSHER_APP_KEY,
  wsHost: window.location.hostname,
  wsPort: 6001,
  forceTLS: false,
  disableStats: true,
});

export default window.Echo;
```

**Nouveau fichier** (avec Reverb):

```javascript
import Echo from "laravel-echo";
import Pusher from "pusher-js";

window.Pusher = Pusher;

window.Echo = new Echo({
  broadcaster: "reverb",
  key: process.env.REACT_APP_REVERB_APP_KEY || "inginia-key",
  wsHost: process.env.REACT_APP_REVERB_HOST || "localhost",
  wsPort: process.env.REACT_APP_REVERB_PORT || 8080,
  wssPort: process.env.REACT_APP_REVERB_PORT || 8080,
  forceTLS: (process.env.REACT_APP_REVERB_SCHEME || "http") === "https",
  enabledTransports: ["ws", "wss"],
  disableStats: true,
});

export default window.Echo;
```

---

### 3. **Installer les dépendances (si nécessaire)**

```bash
cd inginia_frontend
npm install laravel-echo pusher-js
```

---

### 4. **Démarrer Laravel Reverb (Backend)**

Dans le terminal backend :

```bash
cd inginia_backend

# Démarrer Reverb
php artisan reverb:start
```

Vous devriez voir :

```
  INFO  Reverb server started on http://localhost:8080
```

---

### 5. **Tester la connexion WebSocket**

Dans votre composant React, vérifiez que la connexion fonctionne :

```javascript
import Echo from "./echo";

// Écouter un événement
Echo.channel("test-channel").listen("TestEvent", (e) => {
  console.log("Message reçu:", e);
});

// Vérifier la connexion
console.log("Echo connecté:", Echo.connector.pusher.connection.state);
```

---

## 🚀 Commandes de démarrage

### Terminal 1 - Backend Laravel

```bash
cd inginia_backend
php artisan serve
# Serveur API sur http://localhost:8000
```

### Terminal 2 - Laravel Reverb

```bash
cd inginia_backend
php artisan reverb:start
# WebSocket sur http://localhost:8080
```

### Terminal 3 - Frontend React

```bash
cd inginia_frontend
npm start
# Application sur http://localhost:3000
```

---

## 🔍 Debugging

### Vérifier que Reverb fonctionne

```bash
# Dans le backend
php artisan reverb:start --debug
```

### Vérifier la connexion depuis le navigateur

Ouvrez la console du navigateur et tapez :

```javascript
window.Echo.connector.pusher.connection.state;
// Devrait afficher: "connected"
```

### Logs Reverb

Les logs s'affichent directement dans le terminal où Reverb tourne :

```
[2025-12-19 12:00:00] Connection established: socket-id-123
[2025-12-19 12:00:01] Subscribed to channel: private-chat.1
```

---

## ⚠️ Problèmes courants

### 1. **Erreur de connexion**

**Symptôme**: `WebSocket connection failed`

**Solution**:

- Vérifiez que Reverb tourne : `php artisan reverb:start`
- Vérifiez le port dans `.env` : `REVERB_PORT=8080`
- Vérifiez le firewall Windows

### 2. **Erreur CORS**

**Symptôme**: `Access-Control-Allow-Origin error`

**Solution**: Dans `config/cors.php` (backend):

```php
'paths' => ['api/*', 'broadcasting/auth'],
'allowed_origins' => ['http://localhost:3000'],
```

### 3. **Événements non reçus**

**Symptôme**: Les événements ne sont pas reçus côté frontend

**Solution**:

- Vérifiez que l'événement implémente `ShouldBroadcast`
- Vérifiez le nom du channel
- Vérifiez les logs Reverb

---

## 📊 Comparaison Ancien vs Nouveau

| Fonctionnalité      | Laravel WebSockets | Laravel Reverb   |
| ------------------- | ------------------ | ---------------- |
| **Installation**    | Package tiers      | Officiel Laravel |
| **Configuration**   | Complexe           | Simple           |
| **Performance**     | Bonne              | Excellente       |
| **Support**         | Communauté         | Laravel Team     |
| **Port par défaut** | 6001               | 8080             |
| **Broadcaster**     | `pusher`           | `reverb`         |

---

## ✅ Checklist de migration

- [ ] Mettre à jour `.env` frontend avec variables Reverb
- [ ] Modifier `src/echo.js` avec nouvelle configuration
- [ ] Démarrer Laravel Reverb : `php artisan reverb:start`
- [ ] Tester la connexion WebSocket
- [ ] Vérifier que les événements sont reçus
- [ ] Tester la messagerie en temps réel
- [ ] Tester les notifications push

---

## 🎯 Prochaines étapes

Une fois la migration terminée :

1. **Supprimer les anciennes dépendances** (si présentes):

   ```bash
   npm uninstall @beyondcode/laravel-websockets
   ```

2. **Mettre à jour la documentation** de votre projet

3. **Déployer en production** avec les nouvelles variables d'environnement

---

**Note**: Laravel Reverb est compatible avec tous vos événements et channels existants. Seule la configuration change, pas le code métier !
