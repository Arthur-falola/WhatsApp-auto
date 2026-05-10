import 'dart:convert';

enum MatchType { exact, contains, startsWith, regex, any }

class ReplyRule {
  final String id;
  String keyword;
  String response;
  MatchType matchType;
  bool isActive;
  bool isCaseSensitive;
  int delaySeconds;
  DateTime createdAt;

  ReplyRule({
    required this.id,
    required this.keyword,
    required this.response,
    this.matchType = MatchType.contains,
    this.isActive = true,
    this.isCaseSensitive = false,
    this.delaySeconds = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool matches(String message) {
    if (!isActive) return false;
    if (matchType == MatchType.any) return true;

    final String msg = isCaseSensitive ? message : message.toLowerCase();
    final String kw = isCaseSensitive ? keyword : keyword.toLowerCase();

    switch (matchType) {
      case MatchType.exact:
        return msg == kw;
      case MatchType.contains:
        return msg.contains(kw);
      case MatchType.startsWith:
        return msg.startsWith(kw);
      case MatchType.regex:
        try {
          return RegExp(keyword, caseSensitive: isCaseSensitive).hasMatch(message);
        } catch (_) {
          return false;
        }
      case MatchType.any:
        return true;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'keyword': keyword,
        'response': response,
        'matchType': matchType.index,
        'isActive': isActive,
        'isCaseSensitive': isCaseSensitive,
        'delaySeconds': delaySeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReplyRule.fromMap(Map<String, dynamic> map) => ReplyRule(
        id: map['id'],
        keyword: map['keyword'],
        response: map['response'],
        matchType: MatchType.values[map['matchType'] ?? 0],
        isActive: map['isActive'] ?? true,
        isCaseSensitive: map['isCaseSensitive'] ?? false,
        delaySeconds: map['delaySeconds'] ?? 0,
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      );

  String toJson() => jsonEncode(toMap());
  factory ReplyRule.fromJson(String source) => ReplyRule.fromMap(jsonDecode(source));

  ReplyRule copyWith({
    String? keyword,
    String? response,
    MatchType? matchType,
    bool? isActive,
    bool? isCaseSensitive,
    int? delaySeconds,
  }) =>
      ReplyRule(
        id: id,
        keyword: keyword ?? this.keyword,
        response: response ?? this.response,
        matchType: matchType ?? this.matchType,
        isActive: isActive ?? this.isActive,
        isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
        delaySeconds: delaySeconds ?? this.delaySeconds,
        createdAt: createdAt,
      );
}
