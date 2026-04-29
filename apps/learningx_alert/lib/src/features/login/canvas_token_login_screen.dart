import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app_providers.dart';

class CanvasTokenLoginScreen extends ConsumerStatefulWidget {
  const CanvasTokenLoginScreen({super.key});

  @override
  ConsumerState<CanvasTokenLoginScreen> createState() =>
      _CanvasTokenLoginScreenState();
}

class _CanvasTokenLoginScreenState
    extends ConsumerState<CanvasTokenLoginScreen> {
  late final WebViewController _controller;
  var _status = 'SSU Canvas 로그인 페이지를 여는 중입니다.';
  var _isAutomating = false;
  var _profileLoaded = false;
  final _sessionChecks = <String, Completer<bool>>{};

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LearningXAlertBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _handlePageFinished,
          onWebResourceError: (error) {
            setState(() => _status = '페이지 로드 실패: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://canvas.ssu.ac.kr/login'));
  }

  Future<void> _handlePageFinished(String url) async {
    if (_isAutomating) return;

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'canvas.ssu.ac.kr') return;

    if (uri.path == '/profile/settings') {
      _profileLoaded = true;
      await _runTokenAutomation();
      return;
    }

    final loggedIn = await _hasCanvasSession();
    if (loggedIn && !_profileLoaded) {
      setState(() => _status = '로그인 확인됨. 토큰 생성 화면으로 이동합니다.');
      await _controller.loadRequest(
        Uri.parse('https://canvas.ssu.ac.kr/profile/settings'),
      );
    } else if (!loggedIn && mounted) {
      setState(() => _status = 'SSU 통합 로그인을 완료해 주세요.');
    }
  }

  Future<bool> _hasCanvasSession() async {
    final checkId = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<bool>();
    _sessionChecks[checkId] = completer;

    try {
      await _controller.runJavaScript(_sessionCheckScript(checkId));
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _sessionChecks.remove(checkId);
          return false;
        },
      );
    } catch (_) {
      _sessionChecks.remove(checkId);
      return false;
    }
  }

  Future<void> _runTokenAutomation() async {
    if (_isAutomating) return;
    setState(() {
      _isAutomating = true;
      _status = 'Canvas access token 자동 생성을 시도합니다.';
    });

    final deviceName = Platform.localHostname.isEmpty
        ? 'device'
        : Platform.localHostname;
    final purpose = 'LearningX Alert - $deviceName';
    await _controller.runJavaScript(_automationScript(purpose));
  }

  Future<void> _handleBridgeMessage(JavaScriptMessage message) async {
    final data = jsonDecode(message.message) as Map<String, dynamic>;
    final type = data['type'];
    if (type == 'status') {
      final status = data['message'] as String? ?? _status;
      setState(() => _status = status);
      return;
    }
    if (type == 'session') {
      final id = data['id'] as String?;
      final completer = id == null ? null : _sessionChecks.remove(id);
      if (completer != null && !completer.isCompleted) {
        completer.complete(data['ok'] == true);
      }
      return;
    }
    if (type == 'token') {
      final token = data['token'] as String?;
      if (token == null || token.length < 20) return;
      await ref.read(accessTokenProvider.notifier).save(token);
      if (!mounted) return;
      context.go('/');
      return;
    }
    if (type == 'error') {
      setState(() {
        _isAutomating = false;
        _status = data['message'] as String? ?? '토큰 자동 생성에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSU Canvas 로그인'),
        actions: [
          IconButton(
            tooltip: '재시도',
            onPressed: () {
              setState(() {
                _isAutomating = false;
                _profileLoaded = false;
                _status = '로그인 페이지를 다시 엽니다.';
              });
              _controller.loadRequest(
                Uri.parse('https://canvas.ssu.ac.kr/login'),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (_isAutomating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _status,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sessionCheckScript(String checkId) {
  final encodedCheckId = jsonEncode(checkId);
  return '''
    (async () => {
      const post = (payload) => LearningXAlertBridge.postMessage(JSON.stringify(payload));
      try {
        const response = await fetch('/api/v1/users/self/profile', {
          credentials: 'include',
          headers: { 'Accept': 'application/json' }
        });
        post({
          type: 'session',
          id: $encodedCheckId,
          ok: response.ok,
          status: response.status,
          statusText: response.statusText,
          url: response.url,
          location: window.location.href
        });
      } catch (error) {
        post({
          type: 'session',
          id: $encodedCheckId,
          ok: false,
          error: String(error && error.message ? error.message : error),
          location: window.location.href
        });
      }
    })();
  ''';
}

String _automationScript(String purpose) {
  final encodedPurpose = jsonEncode(purpose);
  return '''
    (async () => {
      const purpose = $encodedPurpose;
      const post = (payload) => LearningXAlertBridge.postMessage(JSON.stringify(payload));
      const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
      const csrf = () =>
        document.querySelector('meta[name="csrf-token"]')?.content ||
        document.querySelector('input[name="authenticity_token"]')?.value ||
        '';

      async function profile() {
        const response = await fetch('/api/v1/users/self/profile', {
          credentials: 'include',
          headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) throw new Error('현재 Canvas 사용자를 확인하지 못했습니다.');
        return await response.json();
      }

      async function tryTokenApi() {
        let path = '/profile/tokens';
        try {
          post({ type: 'status', message: 'Canvas access token 생성 요청 중입니다.' });
          clickBySelector('.add_access_token_link');
          await sleep(400);
          const form = tokenForm();
          path = form?.getAttribute('action') || '/profile/tokens';
          const body = tokenRequestBody(form);
          const csrfToken = body.get('authenticity_token') || csrf();
          const response = await fetch(path, {
            method: 'POST',
            credentials: 'include',
            headers: {
              'Accept': 'application/json, text/javascript, application/json+canvas-string-ids, */*; q=0.01',
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              'X-CSRF-Token': csrfToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            referrer: 'https://canvas.ssu.ac.kr/profile/settings',
            body: body.toString()
          });
          const text = await response.text();
          if (!response.ok) {
            throw new Error(`토큰 생성 요청에 실패했습니다. (HTTP \${response.status})`);
          }
          const json = text ? JSON.parse(text) : null;
          const token = tokenFromJson(json);
          if (token) return token;
          throw new Error('토큰 생성 응답에서 access token을 찾지 못했습니다.');
        } catch (error) {
          post({ type: 'error', message: String(error && error.message ? error.message : error) });
        }
        return null;
      }

      function tokenForm() {
        return document.querySelector('form[action*="/profile/tokens"]') ||
          document.querySelector('input[name="access_token[purpose]"]')?.closest('form');
      }

      function tokenRequestBody(form) {
        const body = form ? new URLSearchParams(new FormData(form)) : new URLSearchParams();
        const csrfToken = body.get('authenticity_token') || csrf();
        body.set('utf8', body.get('utf8') || '');
        body.set('authenticity_token', csrfToken);
        body.set('purpose', purpose);
        body.set('access_token[purpose]', purpose);
        body.set('expires_at', '');
        body.set('access_token[expires_at]', '');
        body.set('_method', 'post');
        return body;
      }

      function tokenFromJson(value) {
        if (!value) return null;
        if (typeof value === 'string') {
          return value.length > 20 ? value : null;
        }
        if (Array.isArray(value)) {
          for (const item of value) {
            const token = tokenFromJson(item);
            if (token) return token;
          }
          return null;
        }
        if (typeof value === 'object') {
          for (const key of ['token', 'visible_token', 'access_token']) {
            const token = tokenFromJson(value[key]);
            if (token) return token;
          }
        }
        return null;
      }

      function clickBySelector(selector) {
        const target = document.querySelector(selector);
        if (!target) return false;
        target.click();
        return true;
      }

      try {
        await profile();
        const apiToken = await tryTokenApi();
        if (apiToken) {
          post({ type: 'token', token: apiToken });
          return;
        }
      } catch (error) {
        post({ type: 'error', message: String(error && error.message ? error.message : error) });
      }
    })();
  ''';
}
