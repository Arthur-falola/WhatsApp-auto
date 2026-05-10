import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/auto_reply_service.dart';
import '../services/notification_channel.dart';

class WhatsAppWebScreen extends StatefulWidget {
  const WhatsAppWebScreen({super.key});

  @override
  State<WhatsAppWebScreen> createState() => _WhatsAppWebScreenState();
}

class _WhatsAppWebScreenState extends State<WhatsAppWebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _autoReplyEnabled = false;
  bool _overlayEnabled = false;
  String _status = 'Connexion...';
  final AutoReplyService _autoReplyService = AutoReplyService();

  static const String _whatsWebUrl = 'https://web.whatsapp.com';

  static const String _autoReplyScript = r"""
  (function() {
    if (window._whatsAutoInjected) return;
    window._whatsAutoInjected = true;

    const processedMessages = new Set();

    function getReplyInput() {
      return document.querySelector('div[contenteditable="true"][data-tab="10"]') ||
             document.querySelector('div[contenteditable="true"][data-tab="1"]') ||
             document.querySelector('footer div[contenteditable="true"]');
    }

    function sendMessage(text) {
      const input = getReplyInput();
      if (!input) return false;
      input.focus();
      const nativeInputSetter = Object.getOwnPropertyDescriptor(window.HTMLElement.prototype, 'innerHTML').set;
      nativeInputSetter.call(input, text);
      input.dispatchEvent(new Event('input', { bubbles: true }));
      setTimeout(() => {
        const sendBtn = document.querySelector('span[data-icon="send"]')?.closest('button') ||
                        document.querySelector('button[aria-label="Send"]');
        if (sendBtn) sendBtn.click();
      }, 300);
      return true;
    }

    function extractMessages() {
      const msgs = document.querySelectorAll('div.message-in');
      msgs.forEach(msg => {
        const textEl = msg.querySelector('span.selectable-text span');
        if (!textEl) return;
        const text = textEl.innerText.trim();
        const msgId = msg.getAttribute('data-id') || text.substring(0, 30);
        if (processedMessages.has(msgId)) return;
        processedMessages.add(msgId);
        if (window.WhatsAutoFlutter) {
          window.WhatsAutoFlutter.postMessage(JSON.stringify({ type: 'message', text: text, id: msgId }));
        }
      });
    }

    window._whatsAutoReply = function(text) {
      sendMessage(text);
    };

    const observer = new MutationObserver(() => extractMessages());
    observer.observe(document.body, { childList: true, subtree: true });

    setInterval(extractMessages, 2000);
    console.log('[WhatsAuto] Script injected');
  })();
  """;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..addJavaScriptChannel(
        'WhatsAutoFlutter',
        onMessageReceived: _onMessageReceived,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _status = 'Chargement...';
          }),
          onPageFinished: (_) async {
            setState(() {
              _isLoading = false;
              _status = 'WhatsApp Web chargé';
            });
            if (_autoReplyEnabled) {
              await _injectAutoReply();
            }
          },
          onWebResourceError: (error) => setState(
              () => _status = 'Erreur: ${error.description}'),
        ),
      )
      ..loadRequest(Uri.parse(_whatsWebUrl));

    final androidController =
        _controller.platform as AndroidWebViewController;
    androidController.setMediaPlaybackRequiresUserGesture(false);
  }

  void _onMessageReceived(JavaScriptMessage message) async {
    try {
      final data = message.message;
      if (data.contains('"type":"message"')) {
        final textMatch = RegExp(r'"text":"([^"]*)"').firstMatch(data);
        if (textMatch != null) {
          final text = textMatch.group(1) ?? '';
          final reply = _autoReplyService.getAutoReply(text);
          if (reply != null && _autoReplyEnabled) {
            final escapedReply = reply.replaceAll("'", "\\'").replaceAll('"', '\\"');
            await Future.delayed(const Duration(milliseconds: 800));
            await _controller.runJavaScript(
                'window._whatsAutoReply("$escapedReply")');
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _injectAutoReply() async {
    await _controller.runJavaScript(_autoReplyScript);
  }

  Future<void> _toggleAutoReply() async {
    setState(() => _autoReplyEnabled = !_autoReplyEnabled);
    if (_autoReplyEnabled) {
      await _injectAutoReply();
      setState(() => _status = 'Réponse automatique ACTIVE');
    } else {
      await _controller.runJavaScript('window._whatsAutoInjected = false;');
      setState(() => _status = 'Réponse automatique INACTIVE');
    }
  }

  Future<void> _toggleOverlay() async {
    if (!_overlayEnabled) {
      final hasPermission =
          await NotificationChannelService.isOverlayPermissionGranted();
      if (!hasPermission) {
        await NotificationChannelService.requestOverlayPermission();
        return;
      }
      await NotificationChannelService.showOverlayWindow();
    } else {
      await NotificationChannelService.hideOverlayWindow();
    }
    setState(() => _overlayEnabled = !_overlayEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Web'),
        actions: [
          Tooltip(
            message: 'Fenêtre flottante',
            child: IconButton(
              icon: Icon(
                _overlayEnabled ? Icons.picture_in_picture : Icons.picture_in_picture_alt,
                color: _overlayEnabled ? Colors.amber : Colors.white,
              ),
              onPressed: _toggleOverlay,
            ),
          ),
          Tooltip(
            message: 'Réponse automatique',
            child: IconButton(
              icon: Icon(
                _autoReplyEnabled ? Icons.smart_toy : Icons.smart_toy_outlined,
                color: _autoReplyEnabled ? Colors.greenAccent : Colors.white,
              ),
              onPressed: _toggleAutoReply,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: _autoReplyEnabled
                ? const Color(0xFF25D366)
                : Colors.grey[700],
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(
                  _autoReplyEnabled
                      ? Icons.smart_toy
                      : Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleAutoReply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _autoReplyEnabled ? 'ACTIF' : 'INACTIF',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: Color(0xFF25D366)),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
