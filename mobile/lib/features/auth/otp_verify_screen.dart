import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/api/api_client.dart';
import '../../core/locale/locale_controller.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  String _code = '';
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.dio.post('/auth/otp/verify', data: {
        'phone': widget.phone,
        'code': _code,
      });
      final data = res.data as Map<String, dynamic>;
      await Hive.box('auth').put('token', data['token']);
      await Hive.box('auth').put('user', data['user']);
      if (mounted) context.go('/listings');
    } catch (_) {
      final s = ref.read(stringsProvider);
      setState(() => _error = s.invalidCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.verifyCode)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.codeSent),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => _code = v,
              onCompleted: (_) => _verify(),
              pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
