import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/location_utils.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition? _initialCamera;
  LatLng? _selected;
  String? _address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final ok = await Geolocator.checkPermission().then((p) async {
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      return p == LocationPermission.always || p == LocationPermission.whileInUse;
    });

    final pos = ok ? await Geolocator.getCurrentPosition() : null;
    final lat = pos?.latitude ?? 4.710989; // Bogotá fallback
    final lng = pos?.longitude ?? -74.072090;
    _selected = LatLng(lat, lng);
    _initialCamera = CameraPosition(target: _selected!, zoom: 16);
    await _reverseGeocode(lat, lng);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng);
      if (list.isNotEmpty) {
        final p = list.first;
        final sb = StringBuffer();
        if (p.street != null && p.street!.isNotEmpty) sb.write(p.street);
        if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) sb.write(' #${p.subThoroughfare}');
        if (p.locality != null && p.locality!.isNotEmpty) sb.write(', ${p.locality}');
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) sb.write(', ${p.administrativeArea}');
        if (p.country != null && p.country!.isNotEmpty) sb.write(', ${p.country}');
        _address = sb.toString();
      }
    } catch (_) {
      // silencioso
    }
  }

  Future<void> _recenterToCurrent() async {
    final details = await LocationUtils.getCurrentLocationDetails();
    if (details == null) return;
    final lat = details['latitude'] as double;
    final lng = details['longitude'] as double;
    _selected = LatLng(lat, lng);
    _address = details['address'] as String?;
    (await _controller.future).animateCamera(CameraUpdate.newLatLng(_selected!));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar en el mapa')),
      body: _loading || _initialCamera == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  initialCameraPosition: _initialCamera!,
                  onMapCreated: (c) => _controller.complete(c),
                  onCameraMove: (pos) {
                    _selected = pos.target;
                  },
                  onCameraIdle: () async {
                    if (_selected != null) {
                      await _reverseGeocode(_selected!.latitude, _selected!.longitude);
                      if (mounted) setState(() {});
                    }
                  },
                ),
                const IgnorePointer(
                  child: Center(
                    child: Icon(Symbols.location_on, size: 48, color: AppTheme.accentColor),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: FloatingActionButton(
                    heroTag: 'gps',
                    onPressed: _recenterToCurrent,
                    child: const Icon(Symbols.my_location),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                          ],
                        ),
                        child: Text(
                          _address ?? 'Ubicación desconocida',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selected == null
                              ? null
                              : () => Navigator.pop(context, {
                                    'latitude': _selected!.latitude,
                                    'longitude': _selected!.longitude,
                                    'address': _address,
                                  }),
                          child: const Text('Confirmar ubicación'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}


