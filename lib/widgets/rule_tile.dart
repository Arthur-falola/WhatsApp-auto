import 'package:flutter/material.dart';
import '../models/reply_rule.dart';

class RuleTile extends StatelessWidget {
  final ReplyRule rule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RuleTile({
    super.key,
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _matchTypeLabel(MatchType type) {
    switch (type) {
      case MatchType.any:
        return 'Tout message';
      case MatchType.contains:
        return 'Contient';
      case MatchType.exact:
        return 'Exact';
      case MatchType.startsWith:
        return 'Commence par';
      case MatchType.regex:
        return 'Regex';
    }
  }

  Color _matchTypeColor(MatchType type) {
    switch (type) {
      case MatchType.any:
        return Colors.purple;
      case MatchType.contains:
        return Colors.blue;
      case MatchType.exact:
        return Colors.orange;
      case MatchType.startsWith:
        return Colors.teal;
      case MatchType.regex:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _matchTypeColor(rule.matchType);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                rule.matchType == MatchType.any
                    ? Icons.public
                    : Icons.message,
                color: color,
              ),
            ),
            if (!rule.isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                rule.matchType == MatchType.any
                    ? 'Réponse par défaut'
                    : '"${rule.keyword}"',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration:
                      rule.isActive ? null : TextDecoration.lineThrough,
                  color: rule.isActive ? null : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                _matchTypeLabel(rule.matchType),
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule.response,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (rule.delaySeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Délai: ${rule.delaySeconds}s',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle') onToggle();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(rule.isActive ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(rule.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
