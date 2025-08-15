import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final ok = await Geolocator.checkPermission().then((p) async {
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
        return p == LocationPermission.always || p == LocationPermission.whileInUse;
      });

      Position? pos;
      if (ok) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (e) {
          developer.log('Error obteniendo ubicación GPS: $e', name: 'MapPickerPage');
          // Continuar con ubicación fallback
        }
      }

      final lat = pos?.latitude ?? 4.710989; // Bogotá fallback
      final lng = pos?.longitude ?? -74.072090;
      _selected = LatLng(lat, lng);
      _initialCamera = CameraPosition(target: _selected!, zoom: 16);
      await _reverseGeocode(lat, lng);
      
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      developer.log('Error en inicialización de ubicación: $e', name: 'MapPickerPage');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Error al cargar el mapa. Verifica tu conexión a internet.';
          // Configurar posición fallback
          _selected = const LatLng(4.710989, -74.072090); // Bogotá
          _initialCamera = CameraPosition(target: _selected!, zoom: 16);
          _address = 'Bogotá, Colombia (ubicación aproximada)';
        });
      }
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng).timeout(
        const Duration(seconds: 5),
      );
      if (list.isNotEmpty) {
        final p = list.first;
        final sb = StringBuffer();
        if (p.street != null && p.street!.isNotEmpty) sb.write(p.street);
        if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) sb.write(' #${p.subThoroughfare}');
        if (p.locality != null && p.locality!.isNotEmpty) sb.write(', ${p.locality}');
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) sb.write(', ${p.administrativeArea}');
        if (p.country != null && p.country!.isNotEmpty) sb.write(', ${p.country}');
        _address = sb.toString().isNotEmpty ? sb.toString() : 'Ubicación encontrada';
      } else {
        _address = 'Ubicación encontrada';
      }
    } catch (e) {
      developer.log('Error en geocodificación inversa: $e', name: 'MapPickerPage');
      _address = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
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
    // Calcular el padding bottom necesario para los elementos UI
    const double addressCardHeight = 80.0; // Altura aproximada de la tarjeta de dirección (aumentada)
    const double buttonHeight = 50.0; // Altura del botón
    const double spacing = 12.0; // Espaciado entre elementos
    const double bottomPadding = 24.0; // Padding inferior
    const double extraSafetyMargin = 40.0; // Margen extra para asegurar que no se solape
    const double totalUIHeight = addressCardHeight + buttonHeight + spacing + bottomPadding + extraSafetyMargin;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar en el mapa')),
      body: _loading || _initialCamera == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando mapa...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Symbols.error_outline,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _errorMessage = null;
                            });
                            _initLocation();
                          },
                          icon: const Icon(Symbols.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selected != null)
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context, {
                              'latitude': _selected!.latitude,
                              'longitude': _selected!.longitude,
                              'address': _address,
                            }),
                            icon: const Icon(Symbols.check_circle),
                            label: const Text('Usar ubicación actual'),
                          ),
                      ],
                    ),
                  ),
                )
              : Stack(
              children: [
                // GoogleMap con padding bottom para evitar solapamiento
                Padding(
                  padding: const EdgeInsets.only(bottom: totalUIHeight),
                  child: GoogleMap(
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
                    // Configuración del mapa
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: true, // ✅ Restaurar botones de zoom
                    liteModeEnabled: false,
                    trafficEnabled: false,
                    buildingsEnabled: true,
                    indoorViewEnabled: false,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                  ),
                ),
                // Icono central del pin
                const IgnorePointer(
                  child: Center(
                    child: Icon(
                      Symbols.location_on, 
                      size: 48, 
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
                // Botón GPS reposicionado para no interferir con controles de zoom
                Positioned(
                  left: 16, // Cambiar a la izquierda para evitar conflicto con zoom
                  bottom: totalUIHeight + 16, // Posicionar arriba de los elementos UI
                  child: FloatingActionButton(
                    heroTag: 'gps',
                    onPressed: _recenterToCurrent,
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    child: const Icon(Symbols.my_location),
                  ),
                ),
                // Elementos UI en la parte inferior
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tarjeta de dirección
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                                                    BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1), 
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                                                    const Icon(
                          Symbols.location_on,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _address ?? 'Ubicación desconocida',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón de confirmación mejorado
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _selected == null
                              ? null
                              : () => Navigator.pop(context, {
                                    'latitude': _selected!.latitude,
                                    'longitude': _selected!.longitude,
                                    'address': _address,
                                  }),
                          icon: const Icon(Symbols.check_circle, size: 20),
                          label: const Text(
                            'Confirmar ubicación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
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


