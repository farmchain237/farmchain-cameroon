import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/api/api_client.dart';

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  String _pin = '';
  bool _loading = false;
  String? _status;

  Future<Position> _getPosition() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }

  Future<void> _submit(String action) async {
    if (_pin.length != 4) return;
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      final pos = await _getPosition();
      await ApiClient.instance.dio.post('/employees/$action', data: {
        'pin': _pin,
        'lat': pos.latitude,
        'lng': pos.longitude,
      });
      setState(() => _status = action == 'clock-in' ? 'Pointage entrée enregistré' : 'Pointage sortie enregistré');
    } catch (e) {
      setState(() => _status = 'Échec — vérifiez le PIN et la localisation');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pointage employé')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Entrez votre PIN à 4 chiffres', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,
              onChanged: (v) => _pin = v,
              pinTheme: PinTheme(shape: PinCodeFieldShape.box, borderRadius: BorderRadius.circular(8)),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(_status!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loading ? null : () => _submit('clock-in'),
              icon: const Icon(Icons.login),
              label: const Text('Pointer l\'entrée'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _submit('clock-out'),
              icon: const Icon(Icons.logout),
              label: const Text('Pointer la sortie'),
            ),
          ],
        ),
      ),
    );
  }
}
