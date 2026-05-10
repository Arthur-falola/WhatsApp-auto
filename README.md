# WhatsAuto - Réponse automatique WhatsApp

Application Android Flutter pour répondre automatiquement aux messages WhatsApp, avec deux modes de fonctionnement.

## Modes de fonctionnement

### Mode 1 : WhatsApp Web
- Ouvre WhatsApp Web dans un navigateur intégré
- Liaison par **code téléphonique** (sans QR code) via la fonctionnalité native WhatsApp
- Injection JavaScript pour détecter les nouveaux messages et envoyer des réponses automatiques
- **Fenêtre flottante** : l'app peut s'afficher par-dessus d'autres applications
- Fonctionne entièrement en arrière-plan

### Mode 2 : Notifications (WhatsApp Business)
- Intercepte les **notifications entrantes** WhatsApp et WhatsApp Business
- Répond directement via les **actions de notification Android** (RemoteInput)
- Aucune ouverture de WhatsApp requise
- Fonctionne 100% en arrière-plan même si l'écran est éteint
- Compatible avec le démarrage automatique au boot de l'appareil

## Fonctionnalités

- Règles de réponse personnalisables (mot-clé, contient, exact, regex, tout message)
- Délai de réponse configurable par règle
- Priorité des règles (ordre glisser-déposer)
- Activation/désactivation individuelle des règles
- Service en arrière-plan persistant
- Fenêtre flottante déplaçable sur d'autres apps
- Interface Material 3 moderne

## Permissions requises

| Permission | Utilité |
|-----------|---------|
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Lire et répondre aux notifications WhatsApp |
| `SYSTEM_ALERT_WINDOW` | Afficher la fenêtre flottante par-dessus d'autres apps |
| `FOREGROUND_SERVICE` | Maintenir le service actif en arrière-plan |
| `INTERNET` | Charger WhatsApp Web |
| `RECEIVE_BOOT_COMPLETED` | Redémarrer automatiquement après reboot |

## Compilation via GitHub Actions

### Étapes :
1. **Fork** ou **importer** ce projet sur GitHub
2. Aller dans **Actions** → **Build WhatsAuto APK**
3. Cliquer sur **Run workflow**
4. Télécharger l'APK depuis les **Artifacts** en bas de la page

### APK produits :
- `WhatsAuto-release-universal.apk` — Pour tous les appareils
- `WhatsAuto-release-arm64.apk` — Pour smartphones modernes (recommandé)
- `WhatsAuto-release-arm32.apk` — Pour anciens appareils
- `WhatsAuto-debug.apk` — Version debug pour tests

## Installation sur l'appareil

1. Activer "Sources inconnues" dans les paramètres Android
2. Installer l'APK
3. Ouvrir l'app et accorder les permissions :
   - **Accès aux notifications** (Paramètres → Applications → Accès spéciaux → Accès aux notifications)
   - **Fenêtre flottante** (si mode Web utilisé)
4. Choisir votre mode dans l'onglet "Mode"
5. Configurer vos règles dans l'onglet "Règles"
6. Activer le service (interrupteur en bas de l'onglet Mode)

## Configuration WhatsApp Web (Mode 1)

1. Sélectionner "Mode WhatsApp Web" dans l'app
2. Dans WhatsApp Web qui s'ouvre, cliquer sur "Lier un appareil"
3. Sur votre téléphone WhatsApp → Appareils liés → Lier un appareil
4. Choisir **"Lier avec numéro de téléphone"** (en bas)
5. Entrer le code affiché sur l'écran de l'app
6. Activer la réponse automatique (bouton robot en haut à droite)

## Structure du projet

```
whatsapp_autoreply/
├── .github/workflows/build.yml     # CI/CD GitHub Actions
├── android/
│   └── app/src/main/kotlin/com/whatsauto/
│       ├── MainActivity.kt                 # Point d'entrée + MethodChannel
│       ├── WhatsAppNotificationListener.kt # Service écoute notifications
│       ├── OverlayService.kt               # Fenêtre flottante
│       └── BootReceiver.kt                 # Redémarrage après boot
├── lib/
│   ├── main.dart                   # Point d'entrée Flutter
│   ├── models/reply_rule.dart      # Modèle règle de réponse
│   ├── services/
│   │   ├── auto_reply_service.dart  # Logique réponse auto + stockage
│   │   ├── background_service.dart  # Service arrière-plan Flutter
│   │   └── notification_channel.dart # Bridge Flutter ↔ Android
│   ├── screens/
│   │   ├── home_screen.dart         # Écran principal (3 onglets)
│   │   ├── whatsapp_web_screen.dart # WebView WhatsApp Web
│   │   └── settings_screen.dart     # Paramètres
│   └── widgets/
│       ├── mode_card.dart           # Carte sélection mode
│       └── rule_tile.dart           # Tuile règle de réponse
└── pubspec.yaml
```
