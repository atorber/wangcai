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
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlockIfNeeded());
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
    _authInProgress = true;
    try {
      final unlocked = await _authenticate(security);
      if (!mounted) {
        return;
      }
      if (unlocked) {
        setState(() {
          _unlocked = true;
        });
      }
    } finally {
      _authInProgress = false;
    }
  }

  Future<bool> _authenticate(SecurityProvider security) async {
    final allowBiometric = security.biometricEnabled;
    if (allowBiometric) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        if (canCheck || isSupported) {
          final ok = await _localAuth.authenticate(
            localizedReason: '验证身份以访问旺财',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
              sensitiveTransaction: true,
            ),
          );
          if (ok) {
            return true;
          }
        }
      } catch (_) {
        // 生物识别不可用时回落 PIN。
      }
    }
    if (!mounted) {
      return false;
    }
    return _showPinUnlockDialog(security);
  }

  Future<bool> _showPinUnlockDialog(SecurityProvider security) async {
    if (!mounted) {
      return false;
    }
    if (!security.hasPinCode) {
      return true;
    }
    final controller = TextEditingController();
    String? errorText;
    bool unlocked = false;
    while (!unlocked && mounted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('输入 PIN 解锁'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: security.hasPinCode ? '请输入 PIN 码' : '请先在设置中配置 PIN',
                    errorText: errorText,
                  ),
                  onSubmitted: (_) {
                    final input = controller.text.trim();
                    if (security.verifyPinCode(input)) {
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      setDialogState(() {
                        errorText = 'PIN 不正确';
                      });
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: security.biometricEnabled
                        ? () => Navigator.of(dialogContext).pop(false)
                        : null,
                    child: const Text('重试生物识别'),
                  ),
                  FilledButton(
                    onPressed: security.hasPinCode
                        ? () {
                            final input = controller.text.trim();
                            if (security.verifyPinCode(input)) {
                              Navigator.of(dialogContext).pop(true);
                            } else {
                              setDialogState(() {
                                errorText = 'PIN 不正确';
                              });
                            }
                          }
                        : null,
                    child: const Text('解锁'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (result == true) {
        unlocked = true;
      } else if (security.biometricEnabled) {
        return _authenticate(security);
      } else {
        errorText = '请先配置 PIN 码';
      }
    }
    controller.dispose();
    return unlocked;
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
                });
              }
            });
          }
          return widget.child;
        }
        if (!_unlocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlockIfNeeded());
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.child;
      },
    );
  }
}
