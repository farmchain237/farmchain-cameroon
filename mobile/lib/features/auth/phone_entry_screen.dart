import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/locale/locale_controller.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController(text: '+237');
  bool _loading = false;
  String? _error;

  Future<void> _requestOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.dio.post('/auth/otp/request',
          data: {'phone': _controller.text.trim()});
      if (mounted) context.push('/auth/otp', extra: _controller.text.trim());
    } catch (_) {
      final s = ref.read(stringsProvider);
      setState(() => _error = s.errorSendingCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.agriculture, size: 56, color: Color(0xFF1B7A3D)),
              const SizedBox(height: 8),
              const Text('AGROFAMILY',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A3D))),
              const SizedBox(height: 8),
              Text(s.enterPhone, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: s.phoneNumber,
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(s.sendCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
