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
  final _nameController = TextEditingController();
  String _selectedRole = 'FARMER';
  bool _loading = false;
  bool _verified = false; // prevents double-call
  String? _error;

  static const _roles = [
    'FARMER', 'BUYER', 'TRANSPORTER', 'EMPLOYEE', 'ADMIN', 'CONSUMER'
  ];

  Future<void> _verify() async {
    // Hard guard: if already loading or already verified, do nothing
    if (_code.length < 6 || _loading || _verified) return;

    setState(() { _loading = true; _error = null; });

    try {
      final body = <String, dynamic>{
        'phone': widget.phone,
        'code': _code,
      };
      if (_nameController.text.trim().isNotEmpty) {
        body['fullName'] = _nameController.text.trim();
        body['role'] = _selectedRole;
      }

      final res = await ApiClient.instance.dio.post(
        '/auth/otp/verify',
        data: body,
      );

      final data = res.data as Map<String, dynamic>;

      // Mark as verified IMMEDIATELY so no second call can happen
      _verified = true;

      await Hive.box('auth').put('token', data['token']);
      await Hive.box('auth').put('user', data['user']);

      // Small delay to ensure Hive write completes, then navigate
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) context.go('/listings');

    } catch (e) {
      final msg = e.toString().toLowerCase();
      // If backend says fullName/role missing, make sure fields are visible
      if (msg.contains('fullname') || msg.contains('role')) {
        setState(() => _error =
            'Please fill in your full name and role below, then try again.');
      } else {
        setState(() => _error = ref.read(stringsProvider).invalidCode);
      }
    } finally {
      if (mounted && !_verified) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.verifyCode),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B7A3D),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Phone number display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.phone, color: Color(0xFF1B7A3D), size: 18),
                const SizedBox(width: 8),
                Text(widget.phone,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 8),
            Text(s.codeSent,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),

            Text(s.verifyCode,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            // PIN field — onCompleted just stores the value, does NOT auto-submit
            // User must tap Confirm button to prevent accidental double-calls
            PinCodeTextField(
              appContext: context,
              length: 6,
              animationType: AnimationType.fade,
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => _code = v),
              onCompleted: (v) => setState(() => _code = v),
              // Deliberately NOT calling _verify() here — user taps Confirm instead
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 52,
                fieldWidth: 44,
                activeColor: const Color(0xFF1B7A3D),
                selectedColor: const Color(0xFF1B7A3D),
                inactiveColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 20),

            // Name and role fields
            Text(s.fullName,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Your full name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            Text(s.whoAreYou,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              items: _roles.map((r) => DropdownMenuItem(
                value: r,
                child: Text(r[0] + r.substring(1).toLowerCase()),
              )).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: (_loading || _verified || _code.length < 6)
                  ? null
                  : _verify,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1B7A3D),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : _verified
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Verified! Opening app...',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        )
                      : Text(s.confirm,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
            ),
            const SizedBox(height: 16),
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
    );
  }
}
