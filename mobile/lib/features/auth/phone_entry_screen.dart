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
  bool _slowConnection = false;
  String? _error;

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
      _slowConnection = false;
    });

    // After 5 seconds show a reassuring "please wait" message
    // so the user doesn't think the app is frozen while Render wakes up
    final slowTimer = Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _loading) {
        setState(() => _slowConnection = true);
      }
    });

    try {
      await ApiClient.instance.dio.post(
        '/auth/otp/request',
        data: {'phone': _controller.text.trim()},
      );
      if (mounted) context.push('/auth/otp', extra: _controller.text.trim());
    } catch (_) {
      final s = ref.read(stringsProvider);
      setState(() => _error = s.errorSendingCode);
    } finally {
      await slowTimer; // ensure timer future is handled
      if (mounted) setState(() { _loading = false; _slowConnection = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.agriculture,
                  size: 56, color: Color(0xFF1B7A3D)),
              const SizedBox(height: 8),
              const Text('AGROFAMILY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A3D))),
              const SizedBox(height: 8),
              Text(s.enterPhone,
                  textAlign: TextAlign.center,
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
              const SizedBox(height: 16),

              // Slow connection message
              if (_slowConnection)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.lang == AppLang.fr
                              ? 'Connexion en cours... Le serveur se réveille, veuillez patienter (30-60 sec).'
                              : s.lang == AppLang.pcm
                                  ? 'E dey load... Server dey wake up, wait small (30-60 sec).'
                                  : 'Connecting... Server is waking up, please wait (30-60 sec).',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(s.sendCode),
              ),
              const SizedBox(height: 16),

              // Reminder about how OTP works in dev mode
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📋 Testing mode: check Render logs for your 6-digit code\n'
                  '(SMS will be enabled once Africa\'s Talking is connected)',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
