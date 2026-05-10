import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/reply_rule.dart';

class AutoReplyService {
  static const String _rulesKey = 'reply_rules';
  static const String _globalMessageKey = 'global_message';
  static const String _isActiveKey = 'service_active';
  static const String _modeKey = 'app_mode';

  static final AutoReplyService _instance = AutoReplyService._internal();
  factory AutoReplyService() => _instance;
  AutoReplyService._internal();

  final _uuid = const Uuid();
  List<ReplyRule> _rules = [];
  String _globalMessage = 'Merci pour votre message. Je vous réponds dès que possible.';
  bool _isActive = false;
  String _mode = 'notification';

  List<ReplyRule> get rules => List.unmodifiable(_rules);
  String get globalMessage => _globalMessage;
  bool get isActive => _isActive;
  String get mode => _mode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = prefs.getStringList(_rulesKey) ?? [];
    _rules = rulesJson
        .map((e) => ReplyRule.fromMap(jsonDecode(e)))
        .toList();
    _globalMessage = prefs.getString(_globalMessageKey) ??
        'Merci pour votre message. Je vous réponds dès que possible.';
    _isActive = prefs.getBool(_isActiveKey) ?? false;
    _mode = prefs.getString(_modeKey) ?? 'notification';
    if (_rules.isEmpty) {
      _rules = _defaultRules();
      await _saveRules();
    }
  }

  List<ReplyRule> _defaultRules() => [
        ReplyRule(
          id: _uuid.v4(),
          keyword: '',
          response: _globalMessage,
          matchType: MatchType.any,
          isActive: true,
        ),
        ReplyRule(
          id: _uuid.v4(),
          keyword: 'bonjour',
          response: 'Bonjour ! Comment puis-je vous aider ?',
          matchType: MatchType.contains,
          isActive: true,
        ),
        ReplyRule(
          id: _uuid.v4(),
          keyword: 'prix',
          response: 'Pour connaître nos tarifs, veuillez consulter notre site ou rappeler plus tard.',
          matchType: MatchType.contains,
          isActive: true,
        ),
      ];

  String? getAutoReply(String message) {
    if (!_isActive) return null;
    for (final rule in _rules) {
      if (rule.matches(message)) {
        return rule.response;
      }
    }
    return null;
  }

  Future<ReplyRule> addRule({
    required String keyword,
    required String response,
    MatchType matchType = MatchType.contains,
    bool isCaseSensitive = false,
    int delaySeconds = 0,
  }) async {
    final rule = ReplyRule(
      id: _uuid.v4(),
      keyword: keyword,
      response: response,
      matchType: matchType,
      isCaseSensitive: isCaseSensitive,
      delaySeconds: delaySeconds,
    );
    _rules.add(rule);
    await _saveRules();
    return rule;
  }

  Future<void> updateRule(ReplyRule updated) async {
    final index = _rules.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _rules[index] = updated;
      await _saveRules();
    }
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    await _saveRules();
  }

  Future<void> toggleRule(String id) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = _rules[index].copyWith(isActive: !_rules[index].isActive);
      await _saveRules();
    }
  }

  Future<void> reorderRules(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final rule = _rules.removeAt(oldIndex);
    _rules.insert(newIndex, rule);
    await _saveRules();
  }

  Future<void> setGlobalMessage(String message) async {
    _globalMessage = message;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalMessageKey, message);
  }

  Future<void> setActive(bool active) async {
    _isActive = active;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isActiveKey, active);
  }

  Future<void> setMode(String mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode);
  }

  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _rulesKey,
      _rules.map((r) => jsonEncode(r.toMap())).toList(),
    );
  }
}
