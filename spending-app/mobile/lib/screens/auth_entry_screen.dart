import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend_api.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';

class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  final BackendApi _backendApi = BackendApi();
  final AppLinks _appLinks = AppLinks();

  bool _isCheckingSession = true;
  bool _hasValidSession = false;
  bool _isSigningIn = false;
  String? _errorText;
  String? _pendingState;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForOAuthCallback();
    _checkSession();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _listenForOAuthCallback() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleOAuthCallback(uri);
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isSigningIn = false;
          _errorText = error.toString();
        });
      },
    );
  }

  Future<void> _handleOAuthCallback(Uri uri) async {
    if (!_isSigningIn) {
      return;
    }

    if (uri.scheme != 'ranceipt') {
      return;
    }

    final callbackPath = uri.host.isNotEmpty ? uri.host : uri.path.replaceFirst('/', '');
    if (callbackPath != 'auth-callback') {
      return;
    }

    final callbackState = uri.queryParameters['state'];
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    if (error != null && error.isNotEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSigningIn = false;
        _errorText = 'bunq sign-in failed: $error';
      });
      return;
    }

    if (callbackState == null || callbackState != _pendingState || code == null || code.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSigningIn = false;
        _errorText = 'Invalid OAuth callback payload.';
      });
      return;
    }

    try {
      await _backendApi.completeBunqOAuthWithCode(
        state: callbackState,
        code: code,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingState = null;
        _hasValidSession = true;
        _isSigningIn = false;
        _errorText = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSigningIn = false;
        _errorText = e.toString();
      });
    }
  }

  Future<void> _checkSession() async {
    setState(() {
      _isCheckingSession = true;
      _errorText = null;
    });

    try {
      final hasSession = await _backendApi.hasValidSession();
      if (!mounted) {
        return;
      }

      setState(() {
        _hasValidSession = hasSession;
        _isCheckingSession = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasValidSession = false;
        _isCheckingSession = false;
        _errorText = e.toString();
      });
    }
  }

  Future<void> _continueWithBunq() async {
    setState(() {
      _isSigningIn = true;
      _errorText = null;
    });

    try {
      final oauthStart = await _backendApi.startBunqOAuth();
      _pendingState = oauthStart.state;

      final launched = await launchUrl(
        Uri.parse(oauthStart.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not open bunq authorization URL');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSigningIn = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const _AuthLoadingScreen();
    }

    if (_hasValidSession) {
      return const DashboardScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.logoGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.bg),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Ranceipt',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.1,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in with bunq to sync transactions, goals, and receipts.',
                    style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secure login',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Continue with bunq and return to this app to complete sign in automatically.',
                          style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _isSigningIn ? null : _continueWithBunq,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.aqua,
                              foregroundColor: AppColors.bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: _isSigningIn
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.account_balance_outlined),
                            label: Text(
                              _isSigningIn ? 'Connecting...' : 'Continue with bunq',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorText!,
                      style: const TextStyle(color: AppColors.rose, fontSize: 13, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.aqua,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Checking session...',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
