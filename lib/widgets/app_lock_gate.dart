import 'package:finance_app/providers/security_provider.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _unlocked = false;
  bool _authInProgress = false;
  bool _autoUnlockRequested = false;
  String? _lockMessage;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final security = context.read<SecurityProvider>();
      if (!security.appLockEnabled) {
        return;
      }
      final pausedAt = _pausedAt;
      final shouldRelock = pausedAt == null ||
          DateTime.now().difference(pausedAt) >= const Duration(seconds: 10);
      if (shouldRelock) {
        setState(() {
          _unlocked = false;
          _autoUnlockRequested = false;
          _lockMessage = null;
        });
      }
      _tryUnlockIfNeeded();
    }
  }

  Future<void> _tryUnlockIfNeeded() async {
    if (!mounted || _authInProgress) {
      return;
    }
    final security = context.read<SecurityProvider>();
    if (!security.loaded || !security.appLockEnabled || _unlocked) {
      return;
    }
    setState(() {
      _authInProgress = true;
      _lockMessage = null;
    });
    try {
      final unlocked = await _authenticate(security);
      if (!mounted) {
        return;
      }
      if (unlocked) {
        setState(() {
          _unlocked = true;
          _lockMessage = null;
        });
      } else if (_lockMessage == null) {
        setState(() {
          _lockMessage = '未完成生物识别，请重试';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _authInProgress = false;
        });
      } else {
        _authInProgress = false;
      }
    }
  }

  Future<bool> _authenticate(SecurityProvider security) async {
    if (!security.biometricEnabled) {
      return false;
    }
    return _authenticateWithBiometric();
  }

  Future<bool> _authenticateWithBiometric() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        if (mounted) {
          setState(() {
            _lockMessage = '当前设备未检测到可用的面容或指纹，请先在系统设置中配置';
          });
        }
        return false;
      }
      return await _localAuth.authenticate(
        localizedReason: '验证身份以访问旺财',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (error) {
      debugPrint('Biometric authentication failed: $error');
      if (mounted) {
        setState(() {
          _lockMessage = '无法调起系统生物识别，请检查系统权限或设备设置';
        });
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, security, _) {
        if (!security.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!security.appLockEnabled) {
          if (_unlocked) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _unlocked = false;
                  _autoUnlockRequested = false;
                  _lockMessage = null;
                });
              }
            });
          }
          return widget.child;
        }
        if (!_unlocked) {
          if (!_autoUnlockRequested) {
            _autoUnlockRequested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlockIfNeeded());
          }
          return _buildLockedScreen();
        }
        return widget.child;
      },
    );
  }

  Widget _buildLockedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                '旺财已锁定',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '请使用面容或指纹解锁',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_lockMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _lockMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _authInProgress ? null : _tryUnlockIfNeeded,
                icon: const Icon(Icons.lock_open),
                label: Text(_authInProgress ? '验证中...' : '解锁'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
