import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorLocationMapCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? address;

  const DoctorLocationMapCard({super.key, this.latitude, this.longitude, this.address});

  bool get _hasLocation => latitude != null && longitude != null;

  Future<void> _openMaps(BuildContext context) async {
    if (!_hasLocation) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation) return const SizedBox.shrink();
    final target = LatLng(latitude!, longitude!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('موقع الطبيب', style: Theme.of(context).textTheme.titleMedium),
            if ((address ?? '').isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Text(address!, style: Theme.of(context).textTheme.bodyMedium),
            ),
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: target, zoom: 14),
                  markers: {Marker(markerId: const MarkerId('doctor_location'), position: target)},
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('فتح الموقع في Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}
