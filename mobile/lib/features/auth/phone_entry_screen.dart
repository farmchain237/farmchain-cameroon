import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/locale/locale_controller.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController(text: '');
  bool _loading = false;
  bool _slowConnection = false;
  String? _error;

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
      _slowConnection = false;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _loading) setState(() => _slowConnection = true);
    });

    try {
      final phone = '+237${_controller.text.trim()}';
      await ApiClient.instance.dio.post(
        '/auth/otp/request',
        data: {'phone': phone},
      );
      if (mounted) context.push('/auth/otp', extra: phone);
    } catch (_) {
      final s = ref.read(stringsProvider);
      setState(() => _error = s.errorSendingCode);
    } finally {
      if (mounted) setState(() { _loading = false; _slowConnection = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.agriculture, size: 56, color: Color(0xFF1B7A3D)),
              const SizedBox(height: 8),
              const Text('AGROFAMILY',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A3D))),
              const SizedBox(height: 8),
              Text(s.enterPhone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Phone number field with +237 prefix
              Text(s.phoneNumber,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🇨🇲 +237',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '6 52 67 97 40',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slow connection warning
              if (_slowConnection)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
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
                          lang == AppLang.fr
                              ? 'Serveur en cours de démarrage, patientez 30-60 sec...'
                              : lang == AppLang.pcm
                                  ? 'Server dey wake up, wait small (30-60 sec)...'
                                  : 'Server waking up, please wait 30-60 sec...',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 13)),
                ),
              ],

              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1B7A3D),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(s.sendCode,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
              const SizedBox(height: 16),

              // Testing reminder box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📋 Testing: get your 6-digit code from\n'
                  'Render → agrofamily-backend → Logs',
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
