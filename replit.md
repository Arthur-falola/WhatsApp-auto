# WhatsAuto - Projet Flutter

## Description
Application Android de réponse automatique WhatsApp avec deux modes :
1. **Mode WhatsApp Web** : liaison par code, fenêtre flottante, injection JS
2. **Mode Notification** : intercepte et répond aux notifications WhatsApp Business

## Comment compiler

### Via GitHub Actions (recommandé pour mobile)
1. Pousser le code sur GitHub
2. Aller dans Actions → Build WhatsAuto APK
3. Run workflow → télécharger l'APK dans les Artifacts

### En local
```bash
flutter pub get
flutter build apk --release
```

## User preferences
- Langue : Français
- Plateforme cible : Android uniquement
- Framework : Flutter + Kotlin natif
