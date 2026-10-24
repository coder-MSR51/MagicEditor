import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/private_vault_service.dart';

enum VaultPinMode {
  create,
  unlock,
  change,
}

class VaultPinDialog extends StatefulWidget {
  final VaultPinMode mode;
  final VoidCallback? onSuccess;

  const VaultPinDialog({
    super.key,
    required this.mode,
    this.onSuccess,
  });

  /// Static helper to display the PIN dialog
  static Future<bool?> show(
    BuildContext context, {
    required VaultPinMode mode,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VaultPinDialog(mode: mode),
    );
  }

  @override
  State<VaultPinDialog> createState() => _VaultPinDialogState();
}

class _VaultPinDialogState extends State<VaultPinDialog> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstEnteredPin = '';
  int _step = 0; // for multi-step flows
  String? _errorMessage;

  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake(String error) {
    setState(() {
      _errorMessage = error;
      _enteredPin = '';
    });
    _shakeController.forward(from: 0.0);
  }

  void _handleNumberPress(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _processCompletedPin(_enteredPin);
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _processCompletedPin(String pin) async {
    switch (widget.mode) {
      case VaultPinMode.unlock:
        final isValid = await PrivateVaultService.verifyPassword(pin);
        if (isValid) {
          if (mounted) Navigator.pop(context, true);
        } else {
          _triggerShake('Incorrect PIN. Please try again.');
        }
        break;

      case VaultPinMode.create:
        if (_step == 0) {
          // Store first entry and ask for confirmation
          setState(() {
            _firstEnteredPin = pin;
            _enteredPin = '';
            _step = 1;
            _errorMessage = null;
          });
        } else {
          // Confirm PIN
          if (pin == _firstEnteredPin) {
            await PrivateVaultService.setPassword(pin);
            if (mounted) Navigator.pop(context, true);
          } else {
            _triggerShake('PINs did not match. Start again.');
            setState(() {
              _step = 0;
              _firstEnteredPin = '';
            });
          }
        }
        break;

      case VaultPinMode.change:
        if (_step == 0) {
          // Verify old PIN
          final isValid = await PrivateVaultService.verifyPassword(pin);
          if (isValid) {
            setState(() {
              _enteredPin = '';
              _step = 1;
              _errorMessage = null;
            });
          } else {
            _triggerShake('Current PIN is incorrect.');
          }
        } else if (_step == 1) {
          // New PIN
          setState(() {
            _firstEnteredPin = pin;
            _enteredPin = '';
            _step = 2;
            _errorMessage = null;
          });
        } else {
          // Confirm new PIN
          if (pin == _firstEnteredPin) {
            await PrivateVaultService.setPassword(pin);
            if (mounted) Navigator.pop(context, true);
          } else {
            _triggerShake('New PINs did not match.');
            setState(() {
              _step = 1;
              _firstEnteredPin = '';
            });
          }
        }
        break;
    }
  }

  String get _title {
    switch (widget.mode) {
      case VaultPinMode.create:
        return _step == 0 ? 'Create Vault PIN' : 'Confirm Your PIN';
      case VaultPinMode.unlock:
        return 'Unlock Private Vault';
      case VaultPinMode.change:
        if (_step == 0) return 'Enter Current PIN';
        if (_step == 1) return 'Set New 4-Digit PIN';
        return 'Confirm New PIN';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case VaultPinMode.create:
        return _step == 0
            ? 'Set a 4-digit PIN to secure your hidden photos'
            : 'Re-enter your 4-digit PIN to confirm';
      case VaultPinMode.unlock:
        return 'Enter your 4-digit security PIN';
      case VaultPinMode.change:
        if (_step == 0) return 'Verify your existing password';
        if (_step == 1) return 'Choose a new 4-digit security PIN';
        return 'Re-enter your new PIN to confirm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF11141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2B3347), width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Glowing Safe/Lock Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFF00F0FF),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            _title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 22),

          // 4 Animated Dots Indicator
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset = _shakeController.isAnimating
                  ? (math.sin(_shakeController.value * math.pi * 6) * 10.0)
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: isFilled ? 18 : 14,
                  height: isFilled ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? const Color(0xFF00F0FF) : Colors.white12,
                    border: Border.all(
                      color: isFilled ? const Color(0xFF00F0FF) : Colors.white30,
                      width: 1.5,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),

          // Error Message Display
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFF4D4D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            const SizedBox(height: 20),

          // Keypad (3x4)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _buildKeyRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _buildKeyRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Empty spacer or cancel
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 26),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    _buildKeyButton('0'),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: IconButton(
                        icon: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 26),
                        onPressed: _handleBackspace,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeyButton(d)).toList(),
    );
  }

  Widget _buildKeyButton(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNumberPress(text),
        borderRadius: BorderRadius.circular(36),
        splashColor: const Color(0xFF00F0FF).withValues(alpha: 0.25),
        highlightColor: Colors.white10,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1F2C),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
