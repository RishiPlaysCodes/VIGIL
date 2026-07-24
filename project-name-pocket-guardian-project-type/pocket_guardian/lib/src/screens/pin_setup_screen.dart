import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/secure_storage_service.dart';

/// Dialog for setting up or changing the security PIN.
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key, this.isFirstSetup = false});

  final bool isFirstSetup;

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _secureStorage = SecureStorageService.instance;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < AppConfig.minPinLength) {
      setState(() => _error = 'PIN must be at least ${AppConfig.minPinLength} digits.');
      return;
    }
    if (pin.length > AppConfig.maxPinLength) {
      setState(() => _error = 'PIN must be at most ${AppConfig.maxPinLength} digits.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PINs do not match.');
      return;
    }

    await _secureStorage.saveSecurityPin(pin);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isFirstSetup ? 'Set Security PIN' : 'Change Security PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isFirstSetup)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'You need a security PIN to cancel alerts. '
                'Choose a PIN you can enter quickly.',
              ),
            ),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: AppConfig.maxPinLength,
            decoration: const InputDecoration(
              labelText: 'New PIN',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: AppConfig.maxPinLength,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.isFirstSetup)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        FilledButton(
          onPressed: _savePin,
          child: const Text('Save PIN'),
        ),
      ],
    );
  }
}
