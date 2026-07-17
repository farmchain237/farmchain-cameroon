import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/api/api_client.dart';
import '../../core/locale/locale_controller.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  String _cropType = 'CACAO';
  String _grade = 'A';
  DateTime _harvestDate = DateTime.now().add(const Duration(days: 7));
  String _city = 'Douala';
  List<File> _photos = [];
  bool _loading = false;
  String? _error;

  static const _crops = [
    'CACAO', 'CAFE', 'PLANTAIN', 'MAIS', 'TOMATE', 'MANIOC',
    'POULETS', 'CHEVRES', 'TILAPIA', 'AUTRE'
  ];

  static const _cities = [
    'Douala', 'Yaoundé', 'Bafoussam', 'Bamenda', 'Buea',
    'Limbe', 'Kumba', 'Dschang', 'Nkongsamba', 'Édéa', 'Autre'
  ];

  Future<void> _pickPhoto() async {
    if (_photos.length >= 5) {
      setState(() => _error = 'Maximum 5 photos');
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _harvestDate = picked);
  }

  Future<void> _submit() async {
    if (_qtyController.text.isEmpty || _priceController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // Get GPS location
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium),
        );
      } catch (_) {
        // GPS optional — listing still creates without it
      }

      // Upload photos first if any
      final photoKeys = <String>[];
      for (final photo in _photos) {
        try {
          final urlRes = await ApiClient.instance.dio
              .post('/videos/upload-url?contentType=image/jpeg');
          final s3Key = urlRes.data['s3Key'] as String;
          final uploadUrl = urlRes.data['uploadUrl'] as String;
          final bytes = await photo.readAsBytes();
          await ApiClient.instance.dio.put(uploadUrl, data: bytes);
          photoKeys.add(s3Key);
        } catch (_) {
          // Skip failed photo uploads, continue with listing creation
        }
      }

      // Create the listing
      await ApiClient.instance.dio.post('/listings', data: {
        'cropType': _cropType,
        'region': 'LITTORAL', // derived from city server-side later
        'qtyKg': double.parse(_qtyController.text),
        'grade': _grade,
        'pricePerKg': double.parse(_priceController.text),
        'harvestDate': _harvestDate.toIso8601String(),
        'photos': photoKeys,
        if (pos != null) 'lat': pos.latitude,
        if (pos != null) 'lng': pos.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing created successfully!'),
            backgroundColor: Color(0xFF1B7A3D),
          ),
        );
        context.go('/listings');
      }
    } catch (e) {
      setState(() => _error = 'Failed to create listing. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.newListing.replaceAll('+ ', '')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B7A3D),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // What are you selling
            _Label(s.whatDoYouSell),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _cropType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.eco_outlined),
              ),
              items: _crops.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
              onChanged: (v) => setState(() => _cropType = v!),
            ),
            const SizedBox(height: 16),

            // Quantity
            _Label(s.availableQty),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '50',
                suffixText: 'kg',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            _Label(s.pricePerKg),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1500',
                suffixText: 'XAF',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Grade
            _Label(s.grade),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _GradeButton(
                    label: 'Grade A',
                    subtitle: 'Best quality',
                    selected: _grade == 'A',
                    onTap: () => setState(() => _grade = 'A'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradeButton(
                    label: 'Grade B',
                    subtitle: 'Standard',
                    selected: _grade == 'B',
                    onTap: () => setState(() => _grade = 'B'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Harvest date
            _Label(s.harvestDate),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF1B7A3D), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // City
            _Label(s.city),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _city,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              items: _cities.map((c) => DropdownMenuItem(
                value: c, child: Text(c),
              )).toList(),
              onChanged: (v) => setState(() => _city = v!),
            ),
            const SizedBox(height: 16),

            // Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Photos',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${_photos.length}/5',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add photo button
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 80, height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF1B7A3D), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: Color(0xFF1B7A3D)),
                          SizedBox(height: 4),
                          Text('Add',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF1B7A3D))),
                        ],
                      ),
                    ),
                  ),
                  // Photo thumbnails
                  for (int i = 0; i < _photos.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_photos[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _loading ? null : _submit,
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
                  : Text(
                      s.currentLang == AppLang.fr
                          ? 'Publier l\'annonce'
                          : s.currentLang == AppLang.pcm
                              ? 'Post wetin yu de sell'
                              : 'Post listing',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 14));
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label, required this.subtitle,
    required this.selected, required this.onTap,
  });
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1B7A3D)
              : Colors.white,
          border: Border.all(
              color: const Color(0xFF1B7A3D), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : const Color(0xFF1B7A3D))),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? Colors.white70
                        : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
