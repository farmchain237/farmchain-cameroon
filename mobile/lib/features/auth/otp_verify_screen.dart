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
  bool _isNewUser = true; // assume new until backend says otherwise
  String? _error;

  static const _roles = [
    'FARMER', 'BUYER', 'TRANSPORTER', 'EMPLOYEE', 'ADMIN', 'CONSUMER'
  ];

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final body = <String, dynamic>{
        'phone': widget.phone,
        'code': _code,
      };
      if (_isNewUser && _nameController.text.trim().isNotEmpty) {
        body['fullName'] = _nameController.text.trim();
        body['role'] = _selectedRole;
      }

      final res = await ApiClient.instance.dio.post(
        '/auth/otp/verify',
        data: body,
      );
      final data = res.data as Map<String, dynamic>;
      await Hive.box('auth').put('token', data['token']);
      await Hive.box('auth').put('user', data['user']);
      if (mounted) context.go('/listings');
    } catch (e) {
      final s = ref.read(stringsProvider);
      // If error is "fullName required", show new user fields
      final msg = e.toString().toLowerCase();
      if (msg.contains('fullname') || msg.contains('role')) {
        setState(() => _isNewUser = true);
      }
      setState(() => _error = s.invalidCode);
    } finally {
      if (mounted) setState(() => _loading = false);
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
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF1B7A3D), size: 18),
                  const SizedBox(width: 8),
                  Text(widget.phone,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(s.codeSent,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),

            // PIN entry — big, easy to tap
            Text(s.verifyCode,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            PinCodeTextField(
              appContext: context,
              length: 6,
              animationType: AnimationType.fade,
              keyboardType: TextInputType.number,
              onChanged: (v) => _code = v,
              onCompleted: (_) => _verify(),
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

            // New user fields — only shown when needed
            if (_isNewUser) ...[
              Text(s.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Uncle G',
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
            ],

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _loading ? null : _verify,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1B7A3D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(s.confirm,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),

            const SizedBox(height: 24),
            // Testing reminder
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📋 Testing: get your 6-digit code from\nRender → agrofamily-backend → Logs',
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
