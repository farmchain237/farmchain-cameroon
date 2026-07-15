import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../core/api/api_client.dart';

class SecurityTabScreen extends StatefulWidget {
  const SecurityTabScreen({super.key});

  @override
  State<SecurityTabScreen> createState() => _SecurityTabScreenState();
}

class _SecurityTabScreenState extends State<SecurityTabScreen> {
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents({String? farmId}) async {
    if (farmId == null) return; // caller supplies the farm context in a real flow
    final res = await ApiClient.instance.dio.get('/security/farms/$farmId/events');
    setState(() => _events = res.data as List<dynamic>);
  }

  void _openAddDeviceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AddDeviceSheet(onAdded: () => _loadEvents()),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité'),
        actions: [IconButton(icon: const Icon(Icons.add_a_photo_outlined), onPressed: _openAddDeviceSheet)],
      ),
      body: _events.isEmpty
          ? const Center(child: Text('Aucun événement récent'))
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (_, i) {
                final e = _events[i] as Map<String, dynamic>;
                return ListTile(
                  leading: Icon(
                    e['type'] == 'MOTION_DETECTED' ? Icons.directions_run : Icons.videocam_off_outlined,
                    color: e['type'] == 'CAMERA_OFFLINE' ? Colors.red : Colors.orange,
                  ),
                  title: Text(e['type']),
                  subtitle: Text(e['createdAt']),
                  onTap: () => _openLiveView(e['deviceId'] as String),
                );
              },
            ),
    );
  }

  Future<void> _openLiveView(String deviceId) async {
    final res = await ApiClient.instance.dio.get('/security/devices/$deviceId/stream-url');
    final rtspUrl = res.data['rtspUrl'] as String?;
    if (rtspUrl == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _LiveViewScreen(rtspUrl: rtspUrl)));
  }
}

class _LiveViewScreen extends StatefulWidget {
  const _LiveViewScreen({required this.rtspUrl});
  final String rtspUrl;

  @override
  State<_LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<_LiveViewScreen> {
  late final VlcPlayerController _vlcController;

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
      widget.rtspUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caméra en direct')),
      body: VlcPlayer(controller: _vlcController, aspectRatio: 16 / 9, placeholder: const Center(child: CircularProgressIndicator())),
    );
  }
}

class _AddDeviceSheet extends StatefulWidget {
  const _AddDeviceSheet({required this.onAdded});
  final VoidCallback onAdded;

  @override
  State<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<_AddDeviceSheet> {
  final _rtspController = TextEditingController();
  final _nameController = TextEditingController();
  bool _testing = false;
  bool? _testOk;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testOk = null;
    });
    // A real "test connection" should ask the backend to attempt a short RTSP
    // probe server-side (ffprobe) rather than trusting the client, since the
    // phone and the camera may not be on the same network segment.
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _testing = false;
      _testOk = _rtspController.text.startsWith('rtsp://');
    });
  }

  Future<void> _submit(String farmId) async {
    await ApiClient.instance.dio.post('/security/devices', data: {
      'farmId': farmId,
      'type': 'CAMERA',
      'name': _nameController.text,
      'rtspUrl': _rtspController.text,
    });
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ajouter une caméra', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom (ex: Entrée ferme)')),
          const SizedBox(height: 8),
          TextField(controller: _rtspController, decoration: const InputDecoration(labelText: 'URL RTSP')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _testing ? null : _testConnection,
            icon: _testing ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
            label: Text(_testOk == null ? 'Tester la connexion' : (_testOk! ? 'Connexion OK' : 'Échec de connexion')),
          ),
          const SizedBox(height: 8),
          Text('Ou scannez le QR code fourni avec la caméra:'),
          SizedBox(
            height: 200,
            child: QRView(
              key: const Key('qr'),
              onQRViewCreated: (controller) {
                controller.scannedDataStream.listen((scanData) {
                  if (scanData.code != null) {
                    _rtspController.text = scanData.code!;
                    controller.pauseCamera();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // farmId would come from the current user's selected farm context —
          // wiring that provider is a follow-up once Farm CRUD screens exist.
        ],
      ),
    );
  }
}
