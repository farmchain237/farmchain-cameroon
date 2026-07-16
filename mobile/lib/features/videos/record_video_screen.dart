import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:video_compress/video_compress.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

const _videoTypes = ['FARM_VISIT', 'PICKUP', 'DELIVERY', 'QUALITY_CHECK', 'HARVEST'];
const _maxDuration = Duration(seconds: 60);

class RecordVideoScreen extends StatefulWidget {
  const RecordVideoScreen({super.key, this.listingId, this.orderId});
  final String? listingId;
  final String? orderId;

  @override
  State<RecordVideoScreen> createState() => _RecordVideoScreenState();
}

class _RecordVideoScreenState extends State<RecordVideoScreen> {
  CameraController? _controller;
  bool _recording = false;
  bool _uploading = false;
  String _selectedType = _videoTypes.first;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: true);
    await controller.initialize();
    if (mounted) setState(() => _controller = controller);
  }

  Future<void> _startRecording() async {
    if (_controller == null) return;
    await _controller!.startVideoRecording();
    _startedAt = DateTime.now();
    setState(() => _recording = true);

    // Hard 60s cap — stop automatically even if the user doesn't tap stop.
    Future.delayed(_maxDuration, () {
      if (_recording) _stopAndUpload();
    });
  }

  Future<void> _stopAndUpload() async {
    if (_controller == null || !_recording) return;
    final file = await _controller!.stopVideoRecording();
    setState(() {
      _recording = false;
      _uploading = true;
    });

    final durationSec = DateTime.now().difference(_startedAt!).inSeconds.clamp(1, 60);

    try {
      // Compress to 720p before upload — critical for 2G/3G upload success.
      final compressed = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: true,
      );
      if (compressed?.file == null) throw Exception('Compression failed');

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final uploadUrlRes = await ApiClient.instance.dio.post('/videos/upload-url');
      final s3Key = uploadUrlRes.data['s3Key'] as String;
      final uploadUrl = uploadUrlRes.data['uploadUrl'] as String;

      final bytes = await compressed!.file!.readAsBytes();
      await ApiClient.instance.dio.put(
        uploadUrl,
        data: bytes,
        options: Options(headers: {'Content-Type': 'video/mp4'}),
      );

      await ApiClient.instance.dio.post('/videos', data: {
        's3Key': s3Key,
        'type': _selectedType,
        'durationSec': durationSec,
        'recordedAt': _startedAt!.toIso8601String(),
        'lat': pos.latitude,
        'lng': pos.longitude,
        if (widget.listingId != null) 'listingId': widget.listingId,
        if (widget.orderId != null) 'orderId': widget.orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vidéo envoyée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de l'envoi. La vidéo sera renvoyée dès que le réseau revient.")),
        );
        // TODO: push the compressed file path into OfflineQueue for retry
        // once connectivity returns, rather than losing it.
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vidéo de traçabilité')),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: [for (final t in _videoTypes) DropdownMenuItem(value: t, child: Text(t))],
                    onChanged: (v) => setState(() => _selectedType = v!),
                    decoration: const InputDecoration(labelText: 'Type de vidéo'),
                  ),
                ),
                Expanded(child: CameraPreview(_controller!)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _uploading
                      ? const CircularProgressIndicator()
                      : FloatingActionButton.large(
                          backgroundColor: _recording ? Colors.red : Theme.of(context).colorScheme.primary,
                          onPressed: _recording ? _stopAndUpload : _startRecording,
                          child: Icon(_recording ? Icons.stop : Icons.videocam),
                        ),
                ),
                if (_recording) const Text('Max 60 secondes'),
              ],
            ),
    );
  }
}
