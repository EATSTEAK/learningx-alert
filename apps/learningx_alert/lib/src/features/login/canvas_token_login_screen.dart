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
  ConsumerState<CanvasTokenLoginScreen> createState() => _CanvasTokenLoginScreenState();
}

class _CanvasTokenLoginScreenState extends ConsumerState<CanvasTokenLoginScreen> {
  late final WebViewController _controller;
  var _status = 'SSU Canvas 로그인 페이지를 여는 중입니다.';
  var _isAutomating = false;
  var _profileLoaded = false;

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
      await _controller.loadRequest(Uri.parse('https://canvas.ssu.ac.kr/profile/settings'));
    } else if (!loggedIn && mounted) {
      setState(() => _status = 'SSU 통합 로그인을 완료해 주세요.');
    }
  }

  Future<bool> _hasCanvasSession() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (async () => {
          try {
            const response = await fetch('/api/v1/users/self/profile', {
              credentials: 'include',
              headers: { 'Accept': 'application/json' }
            });
            return response.ok;
          } catch (e) {
            return false;
          }
        })();
      ''');
      return result == true || result.toString() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> _runTokenAutomation() async {
    if (_isAutomating) return;
    setState(() {
      _isAutomating = true;
      _status = 'Canvas access token 자동 생성을 시도합니다.';
    });

    final deviceName = Platform.localHostname.isEmpty ? 'device' : Platform.localHostname;
    final purpose = 'LearningX Alert - $deviceName';
    await _controller.runJavaScript(_automationScript(purpose));
  }

  Future<void> _handleBridgeMessage(JavaScriptMessage message) async {
    final data = jsonDecode(message.message) as Map<String, dynamic>;
    final type = data['type'];
    if (type == 'status') {
      setState(() => _status = data['message'] as String? ?? _status);
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
              _controller.loadRequest(Uri.parse('https://canvas.ssu.ac.kr/login'));
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
                    Expanded(child: Text(_status, maxLines: 3, overflow: TextOverflow.ellipsis)),
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

String _automationScript(String purpose) {
  final encodedPurpose = jsonEncode(purpose);
  return '''
    (async () => {
      const purpose = $encodedPurpose;
      const post = (payload) => LearningXAlertBridge.postMessage(JSON.stringify(payload));
      const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
      const csrf = () => document.querySelector('meta[name="csrf-token"]')?.content || '';

      async function profile() {
        const response = await fetch('/api/v1/users/self/profile', {
          credentials: 'include',
          headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) throw new Error('현재 Canvas 사용자를 확인하지 못했습니다.');
        return await response.json();
      }

      async function tryTokenApi(userId) {
        const body = new URLSearchParams();
        body.append('token[purpose]', purpose);
        const paths = [`/api/v1/users/self/tokens`, `/api/v1/users/\${userId}/tokens`];
        for (const path of paths) {
          try {
            post({ type: 'status', message: `토큰 API 확인 중: \${path}` });
            const response = await fetch(path, {
              method: 'POST',
              credentials: 'include',
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                'X-CSRF-Token': csrf(),
                'X-Requested-With': 'XMLHttpRequest'
              },
              body
            });
            if (!response.ok) continue;
            const json = await response.json();
            if (json && typeof json.token === 'string' && json.token.length > 20) {
              return json.token;
            }
          } catch (_) {}
        }
        return null;
      }

      function textOf(element) {
        return (element.innerText || element.textContent || element.value || '').trim();
      }

      function clickByText(patterns) {
        const elements = Array.from(document.querySelectorAll('button, a, input[type="button"], input[type="submit"]'));
        const target = elements.find((element) => patterns.some((pattern) => pattern.test(textOf(element))));
        if (!target) return false;
        target.click();
        return true;
      }

      function setInputValue(input, value) {
        input.focus();
        input.value = value;
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));
      }

      function fillTokenForm() {
        const inputs = Array.from(document.querySelectorAll('input, textarea'));
        for (const input of inputs) {
          const hint = [input.name, input.id, input.placeholder, input.getAttribute('aria-label')].join(' ').toLowerCase();
          if (hint.includes('purpose') || hint.includes('token') || hint.includes('용도') || hint.includes('목적')) {
            setInputValue(input, purpose);
          }
          if (hint.includes('expires') || hint.includes('expiration') || hint.includes('만료') || input.type === 'date' || input.type === 'datetime-local') {
            setInputValue(input, '');
          }
        }
      }

      function findVisibleToken() {
        const candidates = [];
        for (const input of Array.from(document.querySelectorAll('input, textarea'))) {
          if (input.value) candidates.push(input.value.trim());
        }
        for (const element of Array.from(document.querySelectorAll('code, pre, .token, [class*="token"], [id*="token"]'))) {
          candidates.push(textOf(element));
        }
        for (const candidate of candidates) {
          const match = candidate.match(/[A-Za-z0-9_~.-]{40,}/);
          if (match) return match[0];
        }
        return null;
      }

      async function tryDomAutomation() {
        post({ type: 'status', message: '프로필 화면에서 토큰 생성 버튼을 찾는 중입니다.' });
        clickByText([/new access token/i, /generate.*token/i, /access token/i, /token/i, /토큰/, /액세스/]);
        await sleep(900);
        fillTokenForm();
        await sleep(200);
        clickByText([/generate token/i, /create token/i, /submit/i, /save/i, /생성/, /저장/, /확인/]);
        await sleep(1800);
        return findVisibleToken();
      }

      try {
        const user = await profile();
        const apiToken = await tryTokenApi(user.id);
        if (apiToken) {
          post({ type: 'token', token: apiToken });
          return;
        }
        const domToken = await tryDomAutomation();
        if (domToken) {
          post({ type: 'token', token: domToken });
          return;
        }
        post({ type: 'error', message: '토큰 생성 UI를 자동으로 찾지 못했습니다. 재시도하거나 Canvas 프로필 화면 구조를 확인해야 합니다.' });
      } catch (error) {
        post({ type: 'error', message: String(error && error.message ? error.message : error) });
      }
    })();
  ''';
}
