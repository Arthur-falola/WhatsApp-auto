import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/notification_channel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _msgController = TextEditingController();
  bool _notificationEnabled = false;
  bool _overlayEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    _msgController.text = state.autoReplyService.globalMessage;
    final notifEnabled =
        await NotificationChannelService.isNotificationListenerEnabled();
    final overlayEnabled =
        await NotificationChannelService.isOverlayPermissionGranted();
    setState(() {
      _notificationEnabled = notifEnabled;
      _overlayEnabled = overlayEnabled;
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Message par défaut'),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _msgController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message envoyé quand aucune règle ne correspond',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white),
                      onPressed: () async {
                        await state.autoReplyService
                            .setGlobalMessage(_msgController.text.trim());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Message mis à jour'),
                                backgroundColor: Color(0xFF25D366)),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader('Permissions Android'),
            _PermissionTile(
              title: 'Accès aux notifications',
              subtitle:
                  'Requis pour le mode Notification - intercepter et répondre aux messages WhatsApp',
              icon: Icons.notifications_active,
              isGranted: _notificationEnabled,
              onRequest: () async {
                await NotificationChannelService
                    .openNotificationListenerSettings();
                await Future.delayed(const Duration(seconds: 1));
                final enabled = await NotificationChannelService
                    .isNotificationListenerEnabled();
                setState(() => _notificationEnabled = enabled);
              },
            ),
            _PermissionTile(
              title: 'Fenêtre flottante (Overlay)',
              subtitle:
                  'Permet d\'afficher WhatsAuto par-dessus d\'autres applications',
              icon: Icons.picture_in_picture,
              isGranted: _overlayEnabled,
              onRequest: () async {
                await NotificationChannelService.requestOverlayPermission();
                await Future.delayed(const Duration(seconds: 1));
                final enabled = await NotificationChannelService
                    .isOverlayPermissionGranted();
                setState(() => _overlayEnabled = enabled);
              },
            ),
            const SizedBox(height: 16),
            _SectionHeader('À propos'),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: Color(0xFF25D366)),
                    title: const Text('WhatsAuto'),
                    subtitle: const Text('Version 1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code,
                        color: Color(0xFF075E54)),
                    title: const Text('Développé avec Flutter'),
                    subtitle: const Text(
                        'Réponse automatique WhatsApp - Mode Web & Notification'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isGranted
              ? Colors.green.withOpacity(0.15)
              : Colors.orange.withOpacity(0.15),
          child: Icon(icon,
              color: isGranted ? Colors.green : Colors.orange),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: onRequest,
                child: const Text('Autoriser'),
              ),
      ),
    );
  }
}
