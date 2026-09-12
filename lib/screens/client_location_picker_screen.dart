import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectedTaskLocation {
  const SelectedTaskLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
  });
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
}

class ClientLocationPickerScreen extends StatefulWidget {
  const ClientLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });
  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<ClientLocationPickerScreen> createState() =>
      _ClientLocationPickerScreenState();
}

class _ClientLocationPickerScreenState
    extends State<ClientLocationPickerScreen> {
  static const navy = Color(0xFF001F3F), orange = Color(0xFFFF4500);
  static const supportedCountryCodes = {
    'RW',
    'NG',
    'KE',
    'GH',
    'ZA',
    'CI',
    'CM',
    'UG',
    'SN',
    'TZ',
  };
  static const placesApiKey = 'AIzaSyAYPP0M7rhHMjmk4Bvr18M-g61FEcm4b5w';
  GoogleMapController? _controller;
  LatLng _pin = const LatLng(
    6.5244,
    3.3792,
  ); // Lagos fallback; user can move it.
  final _search = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _locating = false, _saving = false, _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _pin = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _findPlaces(String value) async {
    final query = value.trim();
    if (query.length < 3) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': placesApiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
        },
        body: jsonEncode({
          'input': query,
          'includedRegionCodes': supportedCountryCodes.toList(),
        }),
      );
      final data = jsonDecode(response.body);
      final suggestions = data is Map && data['suggestions'] is List
          ? data['suggestions'] as List
          : const [];
      if (mounted)
        setState(
          () => _results = suggestions
              .map((x) => x['placePrediction'])
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList(),
        );
    } catch (_) {
      if (mounted) _message('Location search is temporarily unavailable.');
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    final id = prediction['placeId']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });
    try {
      final response = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/$id'),
        headers: {
          'X-Goog-Api-Key': placesApiKey,
          'X-Goog-FieldMask': 'location,formattedAddress,addressComponents',
        },
      );
      final data = jsonDecode(response.body) as Map;
      final point = data['location'] as Map?;
      final lat = (point?['latitude'] as num?)?.toDouble(),
          lng = (point?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) throw Exception();
      final next = LatLng(lat, lng);
      setState(() => _pin = next);
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(next, 16));
      _search.text =
          data['formattedAddress']?.toString() ??
          prediction['text']?['text']?.toString() ??
          '';
    } catch (_) {
      if (mounted)
        _message('We could not open that location. Please try another result.');
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Enable location services first.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      final next = LatLng(position.latitude, position.longitude);
      setState(() => _pin = next);
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(next, 16));
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    String? address, city;
    try {
      final marks = await placemarkFromCoordinates(
        _pin.latitude,
        _pin.longitude,
      );
      if (marks.isEmpty) {
        if (mounted) {
          setState(() => _saving = false);
          _message(
            'We could not verify this location. Please choose a clearer map location.',
          );
        }
        return;
      }
      if (marks.isNotEmpty) {
        final p = marks.first;
        final countryCode = (p.isoCountryCode ?? '').toUpperCase();
        if (!supportedCountryCodes.contains(countryCode)) {
          if (mounted) {
            setState(() => _saving = false);
            _message(
              'This task location must be inside one of Boulot Man\'s supported countries.',
            );
          }
          return;
        }
        address = [
          p.street,
          p.subLocality,
        ].whereType<String>().where((v) => v.trim().isNotEmpty).join(', ');
        city = [
          p.locality,
          p.administrativeArea,
        ].whereType<String>().where((v) => v.trim().isNotEmpty).join(', ');
      }
    } catch (_) {
      // Coordinates are still valid; the user can keep or edit the text address.
    }
    if (mounted)
      Navigator.pop(
        context,
        SelectedTaskLocation(
          latitude: _pin.latitude,
          longitude: _pin.longitude,
          address: address,
          city: city,
        ),
      );
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Choose task location'),
      foregroundColor: navy,
      backgroundColor: Colors.white,
    ),
    body: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pin, zoom: 13),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) => _controller = controller,
          onTap: (point) => setState(() => _pin = point),
          markers: {
            Marker(
              markerId: const MarkerId('task-location'),
              position: _pin,
              draggable: true,
              onDragEnd: (point) => setState(() => _pin = point),
            ),
          },
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              Card(
                child: TextField(
                  controller: _search,
                  onChanged: _findPlaces,
                  decoration: InputDecoration(
                    hintText: 'Search city, address, or landmark',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_results.isNotEmpty)
                Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView(
                      shrinkWrap: true,
                      children: _results
                          .map(
                            (p) => ListTile(
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: orange,
                              ),
                              title: Text(p['text']?['text']?.toString() ?? ''),
                              subtitle: Text(
                                p['structuredFormat']?['secondaryText']?['text']
                                        ?.toString() ??
                                    '',
                              ),
                              onTap: () => _selectPlace(p),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Drag the pin or tap the map to select the exact service location.',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            foregroundColor: orange,
            onPressed: _locating ? null : _useCurrentLocation,
            child: _locating
                ? const CircularProgressIndicator()
                : const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _saving ? 'Reading location...' : 'Use this location',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
