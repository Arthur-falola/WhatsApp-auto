import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/reply_rule.dart';
import '../services/notification_channel.dart';
import '../widgets/mode_card.dart';
import '../widgets/rule_tile.dart';
import 'whatsapp_web_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _notificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await context.read<AppState>().refresh();
    final enabled =
        await NotificationChannelService.isNotificationListenerEnabled();
    if (mounted) setState(() => _notificationEnabled = enabled);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.white),
              SizedBox(width: 10),
              Text('WhatsAuto',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.tune), text: 'Mode'),
              Tab(icon: Icon(Icons.rule), text: 'Règles'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Statut'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ModeTab(notificationEnabled: _notificationEnabled, onRefresh: _init),
            _RulesTab(state: state),
            _StatusTab(state: state, notificationEnabled: _notificationEnabled),
          ],
        ),
        floatingActionButton: _tabController.index == 1
            ? FloatingActionButton(
                onPressed: () => _showRuleDialog(context, state),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  void _showRuleDialog(BuildContext context, AppState state,
      {ReplyRule? existing}) {
    final keywordCtrl =
        TextEditingController(text: existing?.keyword ?? '');
    final responseCtrl =
        TextEditingController(text: existing?.response ?? '');
    MatchType matchType = existing?.matchType ?? MatchType.contains;
    int delaySeconds = existing?.delaySeconds ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Nouvelle règle' : 'Modifier la règle',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MatchType>(
                value: matchType,
                decoration: const InputDecoration(
                  labelText: 'Type de correspondance',
                  border: OutlineInputBorder(),
                ),
                items: MatchType.values.map((t) {
                  const labels = {
                    MatchType.any: 'Tout message',
                    MatchType.contains: 'Contient',
                    MatchType.exact: 'Exact',
                    MatchType.startsWith: 'Commence par',
                    MatchType.regex: 'Expression régulière',
                  };
                  return DropdownMenuItem(
                      value: t, child: Text(labels[t]!));
                }).toList(),
                onChanged: (v) =>
                    setModalState(() => matchType = v ?? MatchType.contains),
              ),
              const SizedBox(height: 12),
              if (matchType != MatchType.any)
                TextField(
                  controller: keywordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mot-clé / déclencheur',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              if (matchType != MatchType.any) const SizedBox(height: 12),
              TextField(
                controller: responseCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message de réponse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Délai (secondes): '),
                  Expanded(
                    child: Slider(
                      value: delaySeconds.toDouble(),
                      min: 0,
                      max: 60,
                      divisions: 12,
                      label: '${delaySeconds}s',
                      onChanged: (v) =>
                          setModalState(() => delaySeconds = v.toInt()),
                    ),
                  ),
                  Text('${delaySeconds}s'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white),
                      onPressed: () async {
                        if (responseCtrl.text.trim().isEmpty) return;
                        if (existing == null) {
                          await state.autoReplyService.addRule(
                            keyword: keywordCtrl.text.trim(),
                            response: responseCtrl.text.trim(),
                            matchType: matchType,
                            delaySeconds: delaySeconds,
                          );
                        } else {
                          await state.autoReplyService.updateRule(
                            existing.copyWith(
                              keyword: keywordCtrl.text.trim(),
                              response: responseCtrl.text.trim(),
                              matchType: matchType,
                              delaySeconds: delaySeconds,
                            ),
                          );
                        }
                        await state.refresh();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }
}

class _ModeTab extends StatelessWidget {
  final bool notificationEnabled;
  final VoidCallback onRefresh;

  const _ModeTab(
      {required this.notificationEnabled, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Choisissez votre mode',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ModeCard(
            title: 'Mode WhatsApp Web',
            subtitle:
                'Liaison via code téléphonique. Répond depuis une interface web intégrée avec fenêtre flottante.',
            icon: Icons.web,
            isSelected: state.currentMode == 'web',
            isActive: state.isServiceRunning && state.currentMode == 'web',
            color: const Color(0xFF075E54),
            onTap: () async {
              await state.setMode('web');
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WhatsAppWebScreen()),
                );
              }
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ouvre WhatsApp Web avec liaison par code (sans QR). Détecte et répond aux nouveaux messages automatiquement.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ModeCard(
            title: 'Mode Notification',
            subtitle:
                'Intercepte les notifications WhatsApp Business et répond directement depuis les actions de notification.',
            icon: Icons.notifications_active,
            isSelected: state.currentMode == 'notification',
            isActive:
                state.isServiceRunning && state.currentMode == 'notification',
            color: const Color(0xFF25D366),
            onTap: () async {
              await state.setMode('notification');
              if (!notificationEnabled && context.mounted) {
                _showNotificationPermissionDialog(context);
              }
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fonctionne en arrière-plan. Compatible WhatsApp & WhatsApp Business. Nécessite l\'accès aux notifications.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ServiceToggleCard(state: state),
          ),
        ],
      ),
    );
  }

  void _showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('Permission requise'),
          ],
        ),
        content: const Text(
          'Pour intercepter les notifications WhatsApp et y répondre automatiquement, l\'application doit avoir accès à vos notifications système.\n\nAppuyez sur "Autoriser" puis activez WhatsAuto dans les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              NotificationChannelService.openNotificationListenerSettings();
            },
            child: const Text('Autoriser'),
          ),
        ],
      ),
    );
  }
}

class _ServiceToggleCard extends StatelessWidget {
  final AppState state;

  const _ServiceToggleCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: state.isServiceRunning
                        ? Colors.green.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    state.isServiceRunning
                        ? Icons.power
                        : Icons.power_off,
                    color: state.isServiceRunning
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service de réponse automatique',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        state.isServiceRunning
                            ? 'En cours d\'exécution en arrière-plan'
                            : 'Service arrêté',
                        style: TextStyle(
                            fontSize: 12,
                            color: state.isServiceRunning
                                ? Colors.green
                                : Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.isServiceRunning,
                  activeColor: const Color(0xFF25D366),
                  onChanged: (_) => state.toggleService(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesTab extends StatelessWidget {
  final AppState state;

  const _RulesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final rules = state.autoReplyService.rules;
    if (rules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune règle configurée',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Appuyez sur + pour ajouter une règle',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: rules.length,
      onReorder: (o, n) => state.autoReplyService.reorderRules(o, n),
      itemBuilder: (ctx, i) => RuleTile(
        key: ValueKey(rules[i].id),
        rule: rules[i],
        onToggle: () async {
          await state.autoReplyService.toggleRule(rules[i].id);
          state.refresh();
        },
        onEdit: () {
          // trigger edit via HomeScreen
        },
        onDelete: () async {
          final confirm = await showDialog<bool>(
            context: ctx,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer la règle ?'),
              content:
                  const Text('Cette action est irréversible.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirm == true) {
            await state.autoReplyService.deleteRule(rules[i].id);
            state.refresh();
          }
        },
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final AppState state;
  final bool notificationEnabled;

  const _StatusTab(
      {required this.state, required this.notificationEnabled});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusTile(
          icon: Icons.power,
          label: 'Service actif',
          value: state.isServiceRunning ? 'OUI' : 'NON',
          color: state.isServiceRunning ? Colors.green : Colors.red,
        ),
        _StatusTile(
          icon: Icons.swap_horiz,
          label: 'Mode actuel',
          value: state.currentMode == 'web'
              ? 'WhatsApp Web'
              : 'Notifications',
          color: const Color(0xFF25D366),
        ),
        _StatusTile(
          icon: Icons.notifications,
          label: 'Accès notifications',
          value: notificationEnabled ? 'Autorisé' : 'Non autorisé',
          color: notificationEnabled ? Colors.green : Colors.orange,
          onTap: notificationEnabled
              ? null
              : () => NotificationChannelService
                  .openNotificationListenerSettings(),
        ),
        _StatusTile(
          icon: Icons.rule,
          label: 'Règles actives',
          value:
              '${state.autoReplyService.rules.where((r) => r.isActive).length} / ${state.autoReplyService.rules.length}',
          color: const Color(0xFF075E54),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Message par défaut',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Text(
                  state.autoReplyService.globalMessage,
                  style:
                      TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
      ),
    );
  }
}
