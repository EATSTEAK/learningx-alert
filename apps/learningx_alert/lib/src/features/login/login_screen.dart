import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'LearningX Alert',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'SSU Canvas 과제, 퀴즈, 토론, 페이지 마감일을 동기화하고 로컬 알림을 예약합니다.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/login/canvas'),
                  icon: const Icon(Icons.login),
                  label: const Text('SSU SSO 로그인 시작'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
