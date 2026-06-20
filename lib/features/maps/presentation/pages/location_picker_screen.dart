import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickedDoctorLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PickedDoctorLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };
}

class LocationPickerScreen extends StatefulWidget {
  final PickedDoctorLocation? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallback = LatLng(24.7136, 46.6753);
  late LatLng _selectedLatLng;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.initialLocation == null
        ? _fallback
        : LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude);
    _addressController = TextEditingController(text: widget.initialLocation?.address ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال العنوان النصي للموقع')),
      );
      return;
    }
    Navigator.pop(
      context,
      PickedDoctorLocation(
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار موقع العيادة'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: Icon(Icons.check, color: scheme.onPrimary),
            label: Text('حفظ', style: TextStyle(color: scheme.onPrimary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _selectedLatLng, zoom: 14),
              markers: {
                Marker(markerId: const MarkerId('doctor_location'), position: _selectedLatLng),
              },
              onTap: (value) => setState(() => _selectedLatLng = value),
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'الإحداثيات: ${_selectedLatLng.latitude.toStringAsFixed(6)}, ${_selectedLatLng.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان النصي',
                    hintText: 'مثال: صنعاء، حي سعوان، شارع النصر ',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
