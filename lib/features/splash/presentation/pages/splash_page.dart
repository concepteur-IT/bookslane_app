import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/features/auth/presentation/pages/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _splashDuration = Duration(seconds: 2);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start counting only once the splash has actually been painted. initState
    // runs well before the first frame is rasterized, and Android holds the
    // native launch screen until that frame lands - on a cold debug start that
    // gap can exceed 2s, so timing from here would skip the splash entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(_splashDuration, _openLogin);
    });
  }

  @override
  void dispose() {
    // Stop the timer if the page is torn down early, so it can't fire a
    // navigation against a disposed State.
    _timer?.cancel();
    super.dispose();
  }

  void _openLogin() {
    if (!mounted) return;

    // pushReplacement so the back button doesn't return to the splash screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isApple) {
      // CupertinoPageScaffold provides no Material ancestor, so Text would
      // fall back to WidgetsApp's error style (red, yellow double underline).
      // A transparent Material supplies the text defaults without painting.
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,
        child: Material(
          type: MaterialType.transparency,
          child: _SplashContent(),
        ),
      );
    }

    return const Scaffold(
      backgroundColor: Colors.white,
      body: _SplashContent(),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.logo,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 24),

          const Text(
            'Your book, your business',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 1, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}
